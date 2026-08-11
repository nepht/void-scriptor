import 'package:go_router/go_router.dart';
import 'package:void_scriptor/app/adaptive/adaptive_app_shell.dart';

GoRouter createAppRouter() {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const AdaptiveAppShell()),
    ],
  );
}
