#ifndef RUNNER_OAUTH_CALLBACK_H_
#define RUNNER_OAUTH_CALLBACK_H_

#include <windows.h>

#include <functional>
#include <string>

// Registers vscriptor://oauth/callback for the current executable. This is
// intentionally best-effort and never writes OAuth values to the registry.
bool RegisterOAuthProtocolHandler();

using OAuthCallbackReceiver = std::function<void(const std::string&)>;

// Owns the single-instance mutex and hidden message window. If another
// instance owns it, the callback is forwarded and |forwarded| is set true.
bool AcquireOAuthSingleInstance(HINSTANCE instance,
                                const std::string& initial_callback,
                                bool* forwarded);

// Delivers callbacks received while the app is already running.
void SetOAuthCallbackReceiver(OAuthCallbackReceiver receiver);
void DestroyOAuthSingleInstance();

#endif  // RUNNER_OAUTH_CALLBACK_H_
