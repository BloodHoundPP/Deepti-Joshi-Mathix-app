
/// Configuration for Portfolio / Demo Mode.
/// 
/// To run the app in Demo Mode for portfolio recordings:
/// flutter run --dart-define=DEMO_MODE=true
/// 
/// To build a release APK with demo data:
/// flutter build apk --release --dart-define=DEMO_MODE=true
/// 
/// In normal builds / production, DEMO_MODE defaults to false,
/// ensuring the teacher's live database is always used.
class DemoConfig {
  static const bool _isEnvironmentDemo = bool.fromEnvironment(
    'DEMO_MODE',
    defaultValue: false,
  );

  static bool _runtimeOverride = false;

  /// Returns true if the app is currently running in Demo Mode.
  static bool get isDemoMode => _isEnvironmentDemo || _runtimeOverride;

  /// Enable Demo Mode programmatically (e.g. for development/testing).
  static void enableDemoMode() {
    _runtimeOverride = true;
  }

  /// Disable Demo Mode programmatically.
  static void disableDemoMode() {
    _runtimeOverride = false;
  }
}
