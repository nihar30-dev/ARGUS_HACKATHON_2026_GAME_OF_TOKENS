// ─────────────────────────────────────────────────────────────────────────────
// MeetWise — Backend Configuration
// ─────────────────────────────────────────────────────────────────────────────
//
// THIS IS THE ONLY FILE YOU NEED TO EDIT TO SWITCH ENVIRONMENTS.
//
// Quick start — offline demo (default, no backend required):
//   useMockData = true   ← already set
//
// Quick start — connect to real backend:
//   1. Start the backend:  cd backend && mvn spring-boot:run
//   2. Set useMockData  = false
//   3. Set backendBaseUrl  to your server address (see options below)
//   4. Hot-restart the Flutter app (R in terminal, or Cmd+\ in IDE)
//
// ─────────────────────────────────────────────────────────────────────────────

/// Central configuration for the MeetWise Flutter frontend.
///
/// All values are compile-time constants. Change them here and rebuild —
/// no other file needs to be touched to switch between mock and live mode.
abstract class AppConfig {
  // ── Mock / Live toggle ────────────────────────────────────────────────────

  /// `true`  → use offline Apollo Hospitals demo data (no backend needed).
  /// `false` → call the real Spring Boot backend at [backendBaseUrl].
  ///
  /// Keep `true` during UI development and demos. Flip to `false` when
  /// the backend is running and you want to test end-to-end.
  // ↓ change this to false to enable the real backend ↓
  static const bool useMockData = false;

  // ── Backend URL ───────────────────────────────────────────────────────────

  /// Root URL of the Spring Boot API — no trailing slash.
  ///
  /// Common values:
  ///   Local dev  : 'http://localhost:8080/api'   ← default
  ///   Docker     : 'http://10.0.2.2:8080/api'    (Android emulator → host)
  ///   Staging    : 'https://meetwise-staging.example.com/api'
  ///   Production : 'https://meetwise.example.com/api'
  ///
  /// Only used when [useMockData] = false.
  ///
  /// Web note: the backend must have CORS configured to allow requests from
  /// the Flutter web origin (e.g. http://localhost:8082 in local dev).
  // ↓ change this URL to point at your backend ↓
  static const String backendBaseUrl = 'http://192.1.170.32:8082/api';

  // ── Request timeout ───────────────────────────────────────────────────────

  /// Maximum wait time for a single API response.
  ///
  /// The 6-agent pipeline (with Gemini calls) can take 15–30 s in live mode.
  /// 60 s is intentionally generous; reduce if you hit real performance SLAs.
  ///
  /// Only used when [useMockData] = false.
  static const Duration apiTimeout = Duration(seconds: 60);

  // ── Demo delay ────────────────────────────────────────────────────────────

  /// Simulated network delay in mock mode, so the loading UI renders.
  ///
  /// Set to [Duration.zero] to skip the delay during automated tests.
  static const Duration mockDelay = Duration(seconds: 2);
}
