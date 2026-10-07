#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"
#include "native_brand_window.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project,
                             HWND brand_window)
    : project_(project), brand_window_(brand_window) {}

FlutterWindow::~FlutterWindow() {
  oauth_channel_.reset();
  DestroyNativeBrandWindow(brand_window_);
}

void FlutterWindow::DeliverOAuthCallback(const std::string& callback) {
  if (callback.empty()) return;

  std::lock_guard<std::mutex> lock(oauth_callback_mutex_);
  if (!oauth_channel_) {
    pending_oauth_callbacks_.push_back(callback);
    return;
  }

  oauth_channel_->InvokeMethod(
      "callback", std::make_unique<flutter::EncodableValue>(callback));
}

void FlutterWindow::FlushPendingOAuthCallbacks() {
  std::vector<std::string> callbacks;
  {
    std::lock_guard<std::mutex> lock(oauth_callback_mutex_);
    callbacks.swap(pending_oauth_callbacks_);
  }
  for (const auto& callback : callbacks) {
    oauth_channel_->InvokeMethod(
        "callback", std::make_unique<flutter::EncodableValue>(callback));
  }
}

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
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  oauth_channel_ = std::make_unique<
      flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "void_scriptor/oauth",
      &flutter::StandardMethodCodec::GetInstance());
  oauth_channel_->SetMethodCallHandler(
      [](const auto& call, auto result) { result->NotImplemented(); });
  FlushPendingOAuthCallbacks();

  flutter_controller_->engine()->SetNextFrameCallback([this]() {
    DestroyNativeBrandWindow(brand_window_);
    brand_window_ = nullptr;
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
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
