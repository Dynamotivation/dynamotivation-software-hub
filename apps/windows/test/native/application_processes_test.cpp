#include "../../windows/runner/application_processes.h"
#include <filesystem>
#include <iostream>

int wmain(int argc, wchar_t** argv) {
  if (argc == 2 && std::wstring(argv[1]) == L"--child") {
    Sleep(INFINITE);
    return 0;
  }
  wchar_t filename[32768]{};
  GetModuleFileNameW(nullptr, filename, 32768);
  const std::wstring original(filename);
  const auto other_dir = std::filesystem::path(original).parent_path() / L"other-app";
  std::filesystem::create_directories(other_dir);
  const auto other = other_dir / std::filesystem::path(original).filename();
  std::filesystem::copy_file(original, other, std::filesystem::copy_options::overwrite_existing);
  std::vector<PROCESS_INFORMATION> children;
  auto spawn = [&](const std::wstring& path) {
    STARTUPINFOW startup{};
    startup.cb = sizeof(startup);
    PROCESS_INFORMATION process{};
    std::wstring command = L"\"" + path + L"\" --child";
    if (!CreateProcessW(path.c_str(), command.data(), nullptr, nullptr, FALSE,
                        CREATE_NO_WINDOW, nullptr, nullptr, &startup, &process)) return false;
    CloseHandle(process.hThread);
    children.push_back(process);
    return true;
  };
  bool passed = spawn(original) && spawn(original) && spawn(other.wstring());
  if (passed) {
    const auto running = InspectApplicationProcesses({original, other.wstring()});
    passed = running.error == 0 && running.running[0] && running.running[1];
    const auto stopped = InspectApplicationProcesses({original}, true);
    passed = passed && stopped.error == 0;
    passed = passed && WaitForSingleObject(children[0].hProcess, 3000) == WAIT_OBJECT_0;
    passed = passed && WaitForSingleObject(children[1].hProcess, 3000) == WAIT_OBJECT_0;
    passed = passed && WaitForSingleObject(children[2].hProcess, 0) == WAIT_TIMEOUT;
    const auto after = InspectApplicationProcesses({original, other.wstring()});
    passed = passed && after.error == 0 && !after.running[0] && after.running[1];
  }
  for (const auto& child : children) {
    TerminateProcess(child.hProcess, 1);
    WaitForSingleObject(child.hProcess, 3000);
    CloseHandle(child.hProcess);
  }
  std::filesystem::remove(other);
  std::filesystem::remove(other_dir);
  std::cout << (passed ? "Process path matching and force-close passed" : "Process test failed") << std::endl;
  return passed ? 0 : 1;
}
