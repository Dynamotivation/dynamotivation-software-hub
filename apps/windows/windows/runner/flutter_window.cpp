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
  contrast_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "dynamotivation/windows_accessibility",
      &flutter::StandardMethodCodec::GetInstance());
  contrast_channel_->SetMethodCallHandler(
      [](const auto& call, auto result) {
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
