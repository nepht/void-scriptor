#include "oauth_callback.h"

#include <windows.h>

#include <string>

#include <mutex>

namespace {

constexpr wchar_t kMutexName[] = L"Local\\VoidScriptor.OAuth.SingleInstance";
constexpr wchar_t kWindowClass[] = L"VoidScriptor.OAuth.Callback";
constexpr wchar_t kWindowTitle[] = L"Void Scriptor OAuth Callback Receiver";
HANDLE g_mutex = nullptr;
HWND g_callback_window = nullptr;
OAuthCallbackReceiver g_receiver;
std::mutex g_receiver_mutex;

LRESULT CALLBACK CallbackWindowProc(HWND window, UINT message, WPARAM wparam,
                                    LPARAM lparam) {
  if (message == WM_COPYDATA && lparam != 0) {
    const auto* data = reinterpret_cast<const COPYDATASTRUCT*>(lparam);
    if (data->dwData == 1 && data->lpData != nullptr && data->cbData > 1) {
      const auto* bytes = static_cast<const char*>(data->lpData);
      const size_t length = strnlen_s(bytes, data->cbData);
      if (length > 0) {
        OAuthCallbackReceiver receiver;
        {
          std::lock_guard<std::mutex> lock(g_receiver_mutex);
          receiver = g_receiver;
        }
        if (receiver) receiver(std::string(bytes, length));
      }
    }
    return TRUE;
  }
  return DefWindowProcW(window, message, wparam, lparam);
}

HWND FindCallbackWindow() {
  return FindWindowW(kWindowClass, kWindowTitle);
}

bool ForwardCallback(const std::string& callback) {
  HWND target = FindCallbackWindow();
  if (target == nullptr || callback.empty()) return false;
  COPYDATASTRUCT data{};
  data.dwData = 1;
  data.cbData = static_cast<DWORD>(callback.size() + 1);
  data.lpData = const_cast<char*>(callback.c_str());
  return SendMessageW(target, WM_COPYDATA, 0,
                      reinterpret_cast<LPARAM>(&data)) != 0;
}

bool WriteDefaultValue(HKEY key, const wchar_t* value) {
  return RegSetValueExW(
             key, nullptr, 0, REG_SZ,
             reinterpret_cast<const BYTE*>(value),
             static_cast<DWORD>((wcslen(value) + 1) * sizeof(wchar_t))) ==
         ERROR_SUCCESS;
}

}  // namespace

bool RegisterOAuthProtocolHandler() {
  wchar_t executable_path[MAX_PATH] = {};
  const DWORD length = GetModuleFileNameW(nullptr, executable_path, MAX_PATH);
  if (length == 0 || length >= MAX_PATH) {
    return false;
  }

  HKEY protocol_key = nullptr;
  HKEY command_key = nullptr;
  bool success = false;
  const LSTATUS protocol_status = RegCreateKeyExW(
      HKEY_CURRENT_USER, L"Software\\Classes\\vscriptor", 0, nullptr,
      REG_OPTION_NON_VOLATILE, KEY_WRITE, nullptr, &protocol_key, nullptr);
  if (protocol_status != ERROR_SUCCESS) {
    return false;
  }

  const wchar_t description[] = L"URL:Void Scriptor OAuth Callback";
  const wchar_t url_protocol[] = L"";
  success = WriteDefaultValue(protocol_key, description) &&
            RegSetValueExW(protocol_key, L"URL Protocol", 0, REG_SZ,
                           reinterpret_cast<const BYTE*>(url_protocol),
                           sizeof(url_protocol)) == ERROR_SUCCESS;

  if (success && RegCreateKeyExW(protocol_key, L"shell\\open\\command", 0,
                                 nullptr, REG_OPTION_NON_VOLATILE, KEY_WRITE,
                                 nullptr, &command_key,
                                 nullptr) == ERROR_SUCCESS) {
    std::wstring command = L"\"";
    command += executable_path;
    command += L"\" \"%1\"";
    success = WriteDefaultValue(command_key, command.c_str());
  } else {
    success = false;
  }

  if (command_key != nullptr) {
    RegCloseKey(command_key);
  }
  RegCloseKey(protocol_key);
  return success;
}

bool AcquireOAuthSingleInstance(HINSTANCE instance,
                                const std::string& initial_callback,
                                bool* forwarded) {
  if (forwarded == nullptr) return false;
  *forwarded = false;
  g_mutex = CreateMutexW(nullptr, TRUE, kMutexName);
  if (g_mutex == nullptr) return false;
  if (GetLastError() == ERROR_ALREADY_EXISTS) {
    *forwarded = ForwardCallback(initial_callback);
    CloseHandle(g_mutex);
    g_mutex = nullptr;
    return false;
  }

  WNDCLASSW window_class{};
  window_class.hInstance = instance;
  window_class.lpfnWndProc = CallbackWindowProc;
  window_class.lpszClassName = kWindowClass;
  RegisterClassW(&window_class);
  g_callback_window = CreateWindowExW(
      0, kWindowClass, kWindowTitle, 0, 0, 0, 0, 0, HWND_MESSAGE, nullptr,
      instance, nullptr);
  if (g_callback_window == nullptr) {
    CloseHandle(g_mutex);
    g_mutex = nullptr;
    return false;
  }
  return true;
}

void SetOAuthCallbackReceiver(OAuthCallbackReceiver receiver) {
  std::lock_guard<std::mutex> lock(g_receiver_mutex);
  g_receiver = std::move(receiver);
}

void DestroyOAuthSingleInstance() {
  if (g_callback_window != nullptr) {
    DestroyWindow(g_callback_window);
    g_callback_window = nullptr;
  }
  if (g_mutex != nullptr) {
    ReleaseMutex(g_mutex);
    CloseHandle(g_mutex);
    g_mutex = nullptr;
  }
}
