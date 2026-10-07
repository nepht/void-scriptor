import 'oauth_callback_arguments_stub.dart'
    if (dart.library.io) 'oauth_callback_arguments_io.dart'
    as platform;

List<String> getOAuthCallbackArguments() => platform.arguments;
