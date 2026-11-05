#pragma once
#include <windows.h>
#include <tlhelp32.h>
#include <string>
#include <vector>

struct ApplicationProcessResult {
  std::vector<bool> running;
  DWORD error = ERROR_SUCCESS;
};

inline std::wstring ApplicationProcessPath(HANDLE process) {
  std::wstring path(32768, L'\0');
  DWORD length = static_cast<DWORD>(path.size());
  if (!QueryFullProcessImageNameW(process, 0, path.data(), &length)) return {};
  path.resize(length);
  return path;
}

// Query and terminate using full paths, never image-name taskkill. A separate
// termination handle is revalidated to prevent PID reuse targeting another app.
inline ApplicationProcessResult InspectApplicationProcesses(
    const std::vector<std::wstring>& paths, bool terminate = false) {
  ApplicationProcessResult result{std::vector<bool>(paths.size(), false)};
  HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if (snapshot == INVALID_HANDLE_VALUE) {
    result.error = GetLastError();
    return result;
  }
  PROCESSENTRY32W entry{};
  entry.dwSize = sizeof(entry);
  if (!Process32FirstW(snapshot, &entry)) {
    result.error = GetLastError();
    CloseHandle(snapshot);
    return result;
  }
  do {
    if (entry.th32ProcessID == GetCurrentProcessId()) continue;
    bool candidate = false;
    for (const auto& path : paths) {
      const auto slash = path.find_last_of(L"\\/");
      const auto name = path.substr(slash == std::wstring::npos ? 0 : slash + 1);
      if (_wcsicmp(name.c_str(), entry.szExeFile) == 0) candidate = true;
    }
    if (!candidate) continue;
    HANDLE process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE,
                                 entry.th32ProcessID);
    // Protected processes or processes that exited cannot expose an app path.
    if (!process) continue;
    const auto actual = ApplicationProcessPath(process);
    CloseHandle(process);
    for (size_t i = 0; i < paths.size(); ++i) {
      if (CompareStringOrdinal(actual.c_str(), -1, paths[i].c_str(), -1, TRUE) != CSTR_EQUAL) continue;
      result.running[i] = true;
      if (!terminate) continue;
      HANDLE target = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION | PROCESS_TERMINATE,
                                  FALSE, entry.th32ProcessID);
      if (!target) {
        const DWORD error = GetLastError();
        if (error != ERROR_INVALID_PARAMETER) result.error = error;
        continue;
      }
      const auto confirmed = ApplicationProcessPath(target);
      if (CompareStringOrdinal(confirmed.c_str(), -1, paths[i].c_str(), -1, TRUE) == CSTR_EQUAL) {
        if (!TerminateProcess(target, 1)) {
          const DWORD error = GetLastError();
          DWORD exit_code = STILL_ACTIVE;
          if (!GetExitCodeProcess(target, &exit_code) || exit_code == STILL_ACTIVE) result.error = error;
        }
      } else if (confirmed.empty()) {
        DWORD exit_code = STILL_ACTIVE;
        if (!GetExitCodeProcess(target, &exit_code) || exit_code == STILL_ACTIVE) result.error = ERROR_ACCESS_DENIED;
      }
      CloseHandle(target);
    }
  } while (Process32NextW(snapshot, &entry));
  const DWORD error = GetLastError();
  if (error != ERROR_NO_MORE_FILES) result.error = error;
  CloseHandle(snapshot);
  return result;
}
