/// Compile-time flag controlling whether the Universal Downloader is built in.
///
/// Evaluated at compile time (not runtime) so the entire downloader graph —
/// screens, controller, engine, Python bridge strings, and the
/// `download_task_rows` database table — is tree-shaken out of a `standard`
/// build and leaves no code or string traces in the shipped artifact.
///
/// Set via `--dart-define=ENABLE_DOWNLOADER=false` for the Play Store build
/// (the `standard` flavor). Defaults to `true` for the `universal` build.
const bool enableDownloader =
    bool.fromEnvironment('ENABLE_DOWNLOADER', defaultValue: true);
