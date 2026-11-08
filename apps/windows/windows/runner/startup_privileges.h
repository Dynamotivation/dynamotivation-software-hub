#pragma once

#include <windows.h>

// Injectable only for native tests; production always queries its own primary
// process token. Admin group membership alone is not evidence of elevation.
struct StartupTokenApi {
  decltype(&::OpenProcessToken) open = ::OpenProcessToken;
  decltype(&::GetTokenInformation) query = ::GetTokenInformation;
  decltype(&::CloseHandle) close = ::CloseHandle;
};

// Only a confirmed unelevated token may enter application startup. Return the
// Windows error as the exit code if inspection fails, and access denied when
// elevated. This also rejects full admin tokens when UAC is disabled.
inline DWORD CheckStartupPrivileges(const StartupTokenApi& api = {}) {
  HANDLE token = nullptr;
  if (!api.open(::GetCurrentProcess(), TOKEN_QUERY, &token)) {
    const DWORD error = ::GetLastError();
    return error != ERROR_SUCCESS ? error : ERROR_ACCESS_DENIED;
  }

  TOKEN_ELEVATION elevation{};
  DWORD length = 0;
  if (!api.query(token, TokenElevation, &elevation, sizeof(elevation), &length)) {
    const DWORD error = ::GetLastError();
    api.close(token);
    return error != ERROR_SUCCESS ? error : ERROR_ACCESS_DENIED;
  }
  if (!api.close(token)) {
    const DWORD error = ::GetLastError();
    return error != ERROR_SUCCESS ? error : ERROR_ACCESS_DENIED;
  }
  if (length != sizeof(elevation)) return ERROR_INVALID_DATA;
  return elevation.TokenIsElevated != 0 ? ERROR_ACCESS_DENIED : ERROR_SUCCESS;
}
