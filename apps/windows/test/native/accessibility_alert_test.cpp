#include "../../windows/runner/accessibility_alert.h"

#include <wrl/client.h>

#include <cstdlib>
#include <iostream>
#include <vector>

namespace {
Microsoft::WRL::ComPtr<AccessibilityAlert> alert;
std::vector<std::wstring> announcements;

void Check(bool condition, const char* message) {
  if (!condition) {
    std::cerr << message << std::endl;
    std::exit(1);
  }
}

LRESULT CALLBACK WindowProc(HWND hwnd, UINT message, WPARAM wparam,
                            LPARAM lparam) {
  if (message == WM_GETOBJECT && static_cast<LONG>(lparam) == OBJID_ALERT &&
      alert) {
    return LresultFromObject(IID_IAccessible, wparam, alert.Get());
  }
  return DefWindowProcW(hwnd, message, wparam, lparam);
}

void CALLBACK OnAlert(HWINEVENTHOOK, DWORD, HWND hwnd, LONG object_id,
                      LONG child_id, DWORD, DWORD) {
  Microsoft::WRL::ComPtr<IAccessible> accessible;
  VARIANT child;
  VariantInit(&child);
  Check(SUCCEEDED(AccessibleObjectFromEvent(hwnd, object_id, child_id,
                                            &accessible, &child)),
        "Alert event must resolve to its accessible provider");
  VARIANT role;
  VariantInit(&role);
  Check(SUCCEEDED(accessible->get_accRole(child, &role)) && role.vt == VT_I4 &&
            role.lVal == ROLE_SYSTEM_ALERT,
        "Provider must expose the alert role");
  BSTR name = nullptr;
  Check(SUCCEEDED(accessible->get_accName(child, &name)) && name,
        "Provider must expose announcement text");
  announcements.emplace_back(name);
  SysFreeString(name);
  VariantClear(&role);
  VariantClear(&child);
}

void PumpEvents() {
  for (int tick = 0; tick < 20; ++tick) {
    MSG message;
    while (PeekMessageW(&message, nullptr, 0, 0, PM_REMOVE)) {
      TranslateMessage(&message);
      DispatchMessageW(&message);
    }
    MsgWaitForMultipleObjects(0, nullptr, FALSE, 10, QS_ALLINPUT);
  }
}
}  // namespace

int main() {
  Check(SUCCEEDED(CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED)),
        "COM init");
  WNDCLASSW window_class{};
  window_class.lpfnWndProc = WindowProc;
  window_class.hInstance = GetModuleHandleW(nullptr);
  window_class.lpszClassName = L"HubAccessibilityAlertTest";
  Check(RegisterClassW(&window_class) != 0, "Register test window");
  HWND hwnd =
      CreateWindowW(window_class.lpszClassName, L"Alert test", 0, 0, 0, 100,
                    100, nullptr, nullptr, window_class.hInstance, nullptr);
  Check(hwnd != nullptr, "Create test window");
  alert = Microsoft::WRL::Make<AccessibilityAlert>(hwnd);
  const auto hook =
      SetWinEventHook(EVENT_SYSTEM_ALERT, EVENT_SYSTEM_ALERT, nullptr, OnAlert,
                      GetCurrentProcessId(), 0, WINEVENT_OUTOFCONTEXT);
  Check(hook != nullptr, "Register alert listener");
  const HWND initial_focus = GetFocus();
  alert->Announce(L"Autostart, on");
  PumpEvents();
  Check(announcements == std::vector<std::wstring>{L"Autostart, on"},
        "One activation must emit exactly one named alert");
  alert->Announce(L"Autostart, off");
  PumpEvents();
  Check(announcements ==
            std::vector<std::wstring>{L"Autostart, on", L"Autostart, off"},
        "Second activation must emit its new state exactly once");
  Check(GetFocus() == initial_focus,
        "Announcements must not move keyboard focus");
  UnhookWinEvent(hook);
  alert = nullptr;
  DestroyWindow(hwnd);
  CoUninitialize();
  std::cout << "Single named MSAA alerts and unchanged focus verified"
            << std::endl;
  return 0;
}
