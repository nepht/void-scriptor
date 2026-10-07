#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>

#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  FlutterWindow(const flutter::DartProject& project, HWND brand_window);
  virtual ~FlutterWindow();

  void DeliverOAuthCallback(const std::string& callback);

 private:
  void FlushPendingOAuthCallbacks();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // Native brand window shown only while Flutter produces its first frame.
  HWND brand_window_ = nullptr;

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      oauth_channel_;
  std::mutex oauth_callback_mutex_;
  std::vector<std::string> pending_oauth_callbacks_;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
