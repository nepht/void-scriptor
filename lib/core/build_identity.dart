/// Compile-time identity for the executable currently running.
///
/// The build pipeline should provide `VOID_BUILD_SHA`,
/// `VOID_BUILD_VERSION`, and `VOID_BUILD_CHANNEL` with `--dart-define`.
/// Defaults are deliberately honest for local/test builds and never pretend
/// that a commit is known when it was not injected.
abstract final class BuildIdentity {
  const BuildIdentity._();

  static const version = String.fromEnvironment(
    'VOID_BUILD_VERSION',
    defaultValue: '1.2.0-rc.1',
  );
  static const commit = String.fromEnvironment(
    'VOID_BUILD_SHA',
    defaultValue: 'local',
  );
  static const channel = String.fromEnvironment(
    'VOID_BUILD_CHANNEL',
    defaultValue: 'debug',
  );

  static bool get hasCommit => commit != 'local' && commit.isNotEmpty;

  static String get shortLabel =>
      hasCommit ? 'v$version · $commit' : 'v$version · local';

  static String get diagnosticLabel => '$shortLabel · $channel';
}
