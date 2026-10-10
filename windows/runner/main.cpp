#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "native_brand_window.h"
#include "oauth_callback.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  // Register the custom scheme per-user so OAuth providers can launch this
  // executable without elevation. Failure stays fail-closed at the Dart layer.
  RegisterOAuthProtocolHandler();

  const std::string oauth_callback = GetOAuthCallbackArgument();
  bool callback_forwarded = false;
  if (!AcquireOAuthSingleInstance(instance, oauth_callback, &callback_forwarded)) {
    // A second activation is delivered to the running instance. If delivery
    // fails, do not start a second Flutter process with an unhandled callback.
    return callback_forwarded ? EXIT_SUCCESS : EXIT_FAILURE;
  }

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();
  if (!oauth_callback.empty()) {
    command_line_arguments.push_back("--oauth-callback=" + oauth_callback);
  }

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  HWND brand_window = CreateNativeBrandWindow(instance);
  FlutterWindow window(project, brand_window);
  SetOAuthCallbackReceiver([&window](const std::string& callback) {
    window.DeliverOAuthCallback(callback);
  });
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"Void Scriptor Studio", origin, size)) {
    DestroyNativeBrandWindow(brand_window);
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
