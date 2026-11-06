#include "../../windows/runner/startup_privileges.h"

#include <cstdlib>
#include <iostream>

namespace {
bool open_ok = true;
bool query_ok = true;
bool close_ok = true;
DWORD elevated = 0;
DWORD returned_length = sizeof(TOKEN_ELEVATION);
int queries = 0;
int closes = 0;

void Check(bool condition, const char* message) {
  if (!condition) {
    std::cerr << message << std::endl;
    std::exit(1);
  }
}

BOOL WINAPI Open(HANDLE process, DWORD access, PHANDLE token) {
  Check(process == GetCurrentProcess(), "Must inspect own process");
  Check(access == TOKEN_QUERY, "Must request read-only token access");
  SetLastError(ERROR_ACCESS_DENIED);
  *token = GetCurrentProcess();  // Sentinel; the injected Close never closes it.
  return open_ok;
}

BOOL WINAPI Query(HANDLE token, TOKEN_INFORMATION_CLASS info, LPVOID buffer,
                  DWORD size, PDWORD length) {
  ++queries;
  Check(token == GetCurrentProcess(), "Must inspect the opened token");
  Check(info == TokenElevation, "Must inspect privileges, not UAC split type");
  Check(size == sizeof(TOKEN_ELEVATION), "Must supply the elevation buffer");
  static_cast<TOKEN_ELEVATION*>(buffer)->TokenIsElevated = elevated;
  *length = returned_length;
  SetLastError(ERROR_BAD_TOKEN_TYPE);
  return query_ok;
}

BOOL WINAPI Close(HANDLE token) {
  ++closes;
  Check(token == GetCurrentProcess(), "Must release the opened token");
  SetLastError(ERROR_INVALID_HANDLE);
  return close_ok;
}
}  // namespace

int main() {
  const StartupTokenApi api{Open, Query, Close};
  Check(CheckStartupPrivileges(api) == ERROR_SUCCESS,
        "Confirmed unelevated startup must be allowed");
  Check(queries == 1 && closes == 1, "Token must be queried and closed once");

  elevated = 1;
  Check(CheckStartupPrivileges(api) == ERROR_ACCESS_DENIED,
        "Elevated startup must be refused");
  elevated = 2;
  Check(CheckStartupPrivileges(api) == ERROR_ACCESS_DENIED,
        "Every nonzero elevation value must be refused");
  elevated = 0;

  open_ok = false;
  const int before_queries = queries;
  const int before_closes = closes;
  Check(CheckStartupPrivileges(api) == ERROR_ACCESS_DENIED,
        "Token open failure must refuse startup");
  Check(queries == before_queries && closes == before_closes,
        "Failed opens must not query or close an unowned handle");
  open_ok = true;

  query_ok = false;
  Check(CheckStartupPrivileges(api) == ERROR_BAD_TOKEN_TYPE,
        "Query failure must refuse startup and preserve its error");
  Check(closes == before_closes + 1, "Query failures must still close the token");
  query_ok = true;

  returned_length = 0;
  Check(CheckStartupPrivileges(api) == ERROR_INVALID_DATA,
        "Incomplete token information must refuse startup");
  returned_length = sizeof(TOKEN_ELEVATION);
  close_ok = false;
  Check(CheckStartupPrivileges(api) == ERROR_INVALID_HANDLE,
        "Handle cleanup failure must refuse startup");

  // Exercise the real Windows API as well as the failure-injection cases.
  HANDLE token = nullptr;
  Check(OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &token),
        "Native token open");
  TOKEN_ELEVATION native{};
  DWORD length = 0;
  Check(GetTokenInformation(token, TokenElevation, &native, sizeof(native),
                            &length), "Native token query");
  Check(CloseHandle(token), "Native token cleanup");
  Check(CheckStartupPrivileges() ==
            (native.TokenIsElevated ? static_cast<DWORD>(ERROR_ACCESS_DENIED)
                                   : static_cast<DWORD>(ERROR_SUCCESS)),
        "Production guard must agree with the real process token");
  std::cout << "Startup privilege checks passed; native process elevated="
            << native.TokenIsElevated << std::endl;
  return 0;
}
