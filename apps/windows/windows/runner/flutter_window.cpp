#include "flutter_window.h"

#include <optional>
#include <flutter/standard_method_codec.h>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  accessibility_alert_ = Microsoft::WRL::Make<AccessibilityAlert>(GetHandle());
  contrast_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "dynamotivation/windows_accessibility",
      &flutter::StandardMethodCodec::GetInstance());
  contrast_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        if (call.method_name() == "announceSwitch") {
          const auto* text = std::get_if<std::string>(call.arguments());
          if (!text) {
            result->Error("windows_accessibility", "Expected announcement text");
            return;
          }
          const int length = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, text->data(),
                                                static_cast<int>(text->size()), nullptr, 0);
          if (length == 0) {
            result->Error("windows_accessibility", "Invalid announcement text");
            return;
          }
          std::wstring wide(length, L'\0');
          MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, text->data(), static_cast<int>(text->size()),
                              wide.data(), length);
          accessibility_alert_->Announce(std::move(wide));
          result->Success();
          return;
        }
        if (call.method_name() == "setWindowIconTheme") {
          const auto* theme = std::get_if<int32_t>(call.arguments());
          if (!theme || *theme < -1 || *theme > 1) {
            result->Error("window_icon", "Expected theme -1, 0 or 1");
            return;
          }
          SetWindowIconTheme(GetHandle(), *theme);
          result->Success();
          return;
        }
        if (call.method_name() == "readTaskbarTheme") {
          // The taskbar and tray follow "Windows mode" (SystemUsesLightTheme),
          // which is separate from the apps' own theme. Missing value: light.
          DWORD value = 1;
          DWORD size = sizeof(value);
          RegGetValueW(HKEY_CURRENT_USER,
                       L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize",
                       L"SystemUsesLightTheme", RRF_RT_REG_DWORD, nullptr, &value, &size);
          result->Success(flutter::EncodableValue(value != 0));
          return;
        }
        if (call.method_name() != "readContrast") {
          result->NotImplemented();
          return;
        }
        HIGHCONTRASTW contrast = {};
        contrast.cbSize = sizeof(contrast);
        if (!SystemParametersInfoW(SPI_GETHIGHCONTRAST, sizeof(contrast), &contrast, 0)) {
          result->Error("windows_accessibility", "Could not read Windows high contrast",
                        flutter::EncodableValue(static_cast<int64_t>(GetLastError())));
          return;
        }
        auto color = [](int index) {
          const COLORREF value = GetSysColor(index);
          return flutter::EncodableValue(static_cast<int64_t>(
              0xFF000000u | (GetRValue(value) << 16) |
              (GetGValue(value) << 8) | GetBValue(value)));
        };
        result->Success(flutter::EncodableMap{
            {flutter::EncodableValue("enabled"), flutter::EncodableValue(
                (contrast.dwFlags & HCF_HIGHCONTRASTON) != 0)},
            {flutter::EncodableValue("window"), color(COLOR_WINDOW)},
            {flutter::EncodableValue("text"), color(COLOR_WINDOWTEXT)},
            {flutter::EncodableValue("button"), color(COLOR_BTNFACE)},
            {flutter::EncodableValue("buttonText"), color(COLOR_BTNTEXT)},
            {flutter::EncodableValue("highlight"), color(COLOR_HIGHLIGHT)},
            {flutter::EncodableValue("highlightText"), color(COLOR_HIGHLIGHTTEXT)},
            {flutter::EncodableValue("disabled"), color(COLOR_GRAYTEXT)},
        });
      });
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  accessibility_alert_ = nullptr;
  contrast_channel_ = nullptr;
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // An installer (through the Restart Manager) or a logoff/shutdown asks the
  // app to end with WM_ENDSESSION. The app answers an ordinary close by
  // hiding to the tray (window_manager's preventClose), so without this a
  // Hub sleeping in the tray could never be closed by Setup. Leave the
  // message loop; the runner then ends the process.
  if (message == WM_ENDSESSION && wparam != 0) {
    PostQuitMessage(0);
    return 0;
  }
  if (message == WM_GETOBJECT && static_cast<LONG>(lparam) == OBJID_ALERT &&
      accessibility_alert_) {
    return LresultFromObject(IID_IAccessible, wparam, accessibility_alert_.Get());
  }
  if (message == WM_QUERYENDSESSION) {
    return TRUE;
  }
  static const UINT taskbar_created = RegisterWindowMessageW(L"TaskbarCreated");
  if (message == WM_SETTINGCHANGE || message == WM_THEMECHANGED ||
      message == WM_SYSCOLORCHANGE || message == taskbar_created) {
    UpdateTheme(hwnd);
  }
  // Broadcast settings changes must reach Dart even if a plugin handles them.
  if (contrast_channel_ && (message == WM_SETTINGCHANGE ||
      message == WM_SYSCOLORCHANGE || message == WM_THEMECHANGED)) {
    contrast_channel_->InvokeMethod("changed", nullptr);
  }
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
