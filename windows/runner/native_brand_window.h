#ifndef RUNNER_NATIVE_BRAND_WINDOW_H_
#define RUNNER_NATIVE_BRAND_WINDOW_H_

#include <windows.h>

// Shows lightweight native branding while the Flutter engine renders its
// first frame. The window has no timer: it exists only for real startup work.
HWND CreateNativeBrandWindow(HINSTANCE instance);
void DestroyNativeBrandWindow(HWND window);

#endif  // RUNNER_NATIVE_BRAND_WINDOW_H_
