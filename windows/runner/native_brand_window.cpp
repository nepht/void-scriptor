#include "native_brand_window.h"

#include <gdiplus.h>

#include <memory>
#include <string>

#include "resource.h"

namespace {

constexpr wchar_t kBrandWindowClass[] = L"VOID_SCRIPTOR_NATIVE_BRAND";
constexpr int kBrandWidth = 520;
constexpr int kBrandHeight = 320;

struct BrandWindowState {
  ULONG_PTR gdiplus_token = 0;
  std::unique_ptr<Gdiplus::Image> logo;

  ~BrandWindowState() {
    logo.reset();
    if (gdiplus_token != 0) {
      Gdiplus::GdiplusShutdown(gdiplus_token);
    }
  }
};

std::wstring ExecutableDirectory() {
  wchar_t executable_path[MAX_PATH] = {};
  GetModuleFileNameW(nullptr, executable_path, MAX_PATH);
  std::wstring path(executable_path);
  const auto separator = path.find_last_of(L"\\/");
  return separator == std::wstring::npos ? L"." : path.substr(0, separator);
}

HFONT CreateBrandFont(HDC dc, int point_size, int weight) {
  const int height = -MulDiv(point_size, GetDeviceCaps(dc, LOGPIXELSY), 72);
  return CreateFontW(height, 0, 0, 0, weight, FALSE, FALSE, FALSE,
                     DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                     CLEARTYPE_QUALITY, DEFAULT_PITCH | FF_SWISS, L"Segoe UI");
}

void DrawCenteredText(HDC dc, const wchar_t* text, RECT rect, COLORREF color,
                      int point_size, int weight) {
  HFONT font = CreateBrandFont(dc, point_size, weight);
  HGDIOBJ previous_font = SelectObject(dc, font);
  SetBkMode(dc, TRANSPARENT);
  SetTextColor(dc, color);
  DrawTextW(dc, text, -1, &rect,
            DT_CENTER | DT_SINGLELINE | DT_VCENTER | DT_NOPREFIX);
  SelectObject(dc, previous_font);
  DeleteObject(font);
}

LRESULT CALLBACK BrandWindowProc(HWND window, UINT message, WPARAM wparam,
                                 LPARAM lparam) {
  auto* state = reinterpret_cast<BrandWindowState*>(
      GetWindowLongPtrW(window, GWLP_USERDATA));
  if (message == WM_NCCREATE) {
    auto* create = reinterpret_cast<CREATESTRUCTW*>(lparam);
    state = static_cast<BrandWindowState*>(create->lpCreateParams);
    SetWindowLongPtrW(window, GWLP_USERDATA,
                      reinterpret_cast<LONG_PTR>(state));
  }

  switch (message) {
    case WM_ERASEBKGND:
      return 1;
    case WM_PAINT: {
      PAINTSTRUCT paint = {};
      HDC dc = BeginPaint(window, &paint);
      RECT client = {};
      GetClientRect(window, &client);

      HBRUSH background = CreateSolidBrush(RGB(10, 8, 18));
      FillRect(dc, &client, background);
      DeleteObject(background);

      const int logo_size = 104;
      const int logo_x = (client.right - logo_size) / 2;
      const int logo_y = 34;
      if (state != nullptr && state->logo != nullptr &&
          state->logo->GetLastStatus() == Gdiplus::Ok) {
        Gdiplus::Graphics graphics(dc);
        graphics.SetInterpolationMode(
            Gdiplus::InterpolationModeHighQualityBicubic);
        graphics.DrawImage(state->logo.get(), logo_x, logo_y, logo_size,
                           logo_size);
      } else {
        HICON icon = LoadIconW(GetModuleHandleW(nullptr),
                               MAKEINTRESOURCEW(IDI_APP_ICON));
        DrawIconEx(dc, logo_x, logo_y, icon, logo_size, logo_size, 0, nullptr,
                   DI_NORMAL);
      }

      RECT title = {20, 150, client.right - 20, 190};
      DrawCenteredText(dc, L"VOID SCRIPTOR", title, RGB(246, 242, 255), 22,
                       FW_SEMIBOLD);
      RECT subtitle = {20, 190, client.right - 20, 220};
      DrawCenteredText(dc, L"LOCAL-FIRST CREATIVE WORKSPACE", subtitle,
                       RGB(190, 164, 235), 10, FW_MEDIUM);

      HPEN accent = CreatePen(PS_SOLID, 2, RGB(139, 82, 220));
      HGDIOBJ previous_pen = SelectObject(dc, accent);
      MoveToEx(dc, client.right / 2 - 36, 236, nullptr);
      LineTo(dc, client.right / 2 + 36, 236);
      SelectObject(dc, previous_pen);
      DeleteObject(accent);

      RECT status = {20, 246, client.right - 20, 282};
      DrawCenteredText(dc, L"Opening local workspace", status,
                       RGB(196, 191, 207), 10, FW_NORMAL);
      EndPaint(window, &paint);
      return 0;
    }
    case WM_NCDESTROY:
      SetWindowLongPtrW(window, GWLP_USERDATA, 0);
      delete state;
      return 0;
  }
  return DefWindowProcW(window, message, wparam, lparam);
}

}  // namespace

HWND CreateNativeBrandWindow(HINSTANCE instance) {
  WNDCLASSEXW window_class = {};
  window_class.cbSize = sizeof(window_class);
  window_class.lpfnWndProc = BrandWindowProc;
  window_class.hInstance = instance;
  window_class.hCursor = LoadCursorW(nullptr, IDC_ARROW);
  window_class.hIcon =
      LoadIconW(instance, MAKEINTRESOURCEW(IDI_APP_ICON));
  window_class.lpszClassName = kBrandWindowClass;
  RegisterClassExW(&window_class);

  auto* state = new BrandWindowState();
  Gdiplus::GdiplusStartupInput startup_input;
  if (Gdiplus::GdiplusStartup(&state->gdiplus_token, &startup_input, nullptr) ==
      Gdiplus::Ok) {
    const std::wstring logo_path =
        ExecutableDirectory() +
        L"\\data\\flutter_assets\\assets\\logos\\void_scriptor_logo.png";
    state->logo.reset(Gdiplus::Image::FromFile(logo_path.c_str(), FALSE));
  }

  POINT cursor = {};
  GetCursorPos(&cursor);
  HMONITOR monitor = MonitorFromPoint(cursor, MONITOR_DEFAULTTONEAREST);
  MONITORINFO monitor_info = {};
  monitor_info.cbSize = sizeof(monitor_info);
  GetMonitorInfoW(monitor, &monitor_info);
  const int x = monitor_info.rcWork.left +
                (monitor_info.rcWork.right - monitor_info.rcWork.left -
                 kBrandWidth) /
                    2;
  const int y = monitor_info.rcWork.top +
                (monitor_info.rcWork.bottom - monitor_info.rcWork.top -
                 kBrandHeight) /
                    2;

  HWND window = CreateWindowExW(
      WS_EX_TOOLWINDOW, kBrandWindowClass,
      L"Void Scriptor - Opening local workspace", WS_POPUP, x, y, kBrandWidth,
      kBrandHeight, nullptr, nullptr, instance, state);
  if (window == nullptr) {
    // WM_NCDESTROY owns state cleanup once creation has reached the window
    // procedure. Avoid a possible double-free on partial creation failure.
    return nullptr;
  }
  ShowWindow(window, SW_SHOWNORMAL);
  UpdateWindow(window);
  return window;
}

void DestroyNativeBrandWindow(HWND window) {
  if (window != nullptr && IsWindow(window)) {
    DestroyWindow(window);
  }
}
