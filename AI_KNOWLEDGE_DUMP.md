# Veera Safety App - AI Context & Knowledge Dump

> **ATTENTION FUTURE AI:** Read this document entirely before making any modifications to the Veera (formerly Aura Guard) Flutter application. This file contains the complete architectural context, design system guidelines, feature breakdown, and known quirks of the codebase.

## 1. Project Overview
- **Name:** Veera (Previously Aura Guard / Silent Security System)
- **Framework:** Flutter (Dart)
- **Backend:** Firebase (Authentication + Realtime Database)
- **Primary Use Case:** Personal safety application designed for hackathons.
- **Core Philosophy:** The app functions as a "Silent Guardian" with a highly premium, dark, "intelligence agency" aesthetic. 

## 2. Design System (Aura Guard Glassmorphism)
The app uses a strict, custom design system rather than standard Material widgets.
- **Theme File:** `lib/core/theme.dart` (Contains `AppTheme` colors).
- **Backgrounds:** Screens use a `RadialGradient` originating from `Alignment(0.0, -0.5)` with colors `[Color(0xFF252238), AppTheme.background]`.
- **Containers (Glassmorphism):** Most UI cards and forms are wrapped in a `ClipRRect` and a `BackdropFilter` (`ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15)`). The container itself has a translucent color (`AppTheme.surfaceVariant.withValues(alpha: 0.3)`) and a faint border.
- **Typography:** Titles often use `fontWeight.w900` and heavy `letterSpacing` (e.g., `letterSpacing: 4`). 
- **Optical Centering:** Because Flutter adds letter spacing after the final character, texts with high letter spacing (like "VEERA") are wrapped in `Padding(padding: EdgeInsets.only(left: X))` to remain pixel-perfect centered.

## 3. Core Features & Implementation Details

### A. Authentication (`lib/services/auth_service.dart`)
- Supports Email/Password and **Google Sign-In**.
- Google Sign-In requires the SHA-1 and SHA-256 debug keystore fingerprints to be registered in Firebase, and the resulting `google-services.json` must be placed in `android/app/`.
- User profiles are saved to Firebase Realtime Database upon successful registration.

### B. SOS Triggers
- **Voice Trigger:** Uses `speech_to_text`. Listens continuously. If the word "help" is detected 3 times, it triggers the SOS protocol.
- **Shake to SOS:** Uses `sensors_plus` (accelerometer). Rapid movement triggers the SOS protocol.
- **Fake Call (`lib/screens/fake_call_screen.dart`):** Uses `flutter_ringtone_player` and `vibration`. Configured with `asAlarm: true` and `volume: 1.0` to force the phone to ring loudly and vibrate even if it is set to silent/vibrate.

### C. SOS Protocol Execution (`lib/services/sos_service.dart` or similar)
When SOS is triggered, the app attempts to:
1. Capture Audio using the `record` package.
2. Capture Video using the `camera` package.
3. Save the media securely to the device using `gallery_saver_plus`.
4. (Optional/Future) Send SMS/Location to emergency contacts.

### D. Map & Geofencing (`lib/screens/journey_screen.dart`)
- Uses `google_maps_flutter` and `flutter_polyline_points`.
- Requires the Google Maps SDK for Android and Directions API to be enabled in Google Cloud Console.
- Tracks deviation from the route and can trigger alerts if the user goes off-path.

## 4. Firebase Architecture & Rules
- **Authentication:** Enabled for Email/Password and Google.
- **Realtime Database Structure:**
  ```json
  {
    "Users": {
      "uid_12345": {
        "name": "User Name",
        "email": "user@email.com",
        "phone": "1234567890",
        "createdAt": "timestamp"
      }
    }
  }
  ```
- **Security Rules:** The database requires the user to be authenticated.
  ```json
  {
    "rules": {
      ".read": "auth != null",
      ".write": "auth != null"
    }
  }
  ```

## 5. Known Quirks & Troubleshooting History
- **Google Auth Timeout:** If `GoogleSignIn` times out, it is because `oauth_client` is missing in `google-services.json` due to missing SHA-1 fingerprints in the Firebase Console.
- **RTDB Permission Denied:** If the app throws `DatabaseError: Permission denied` on sign-up, it means the Realtime Database rules have not been set to allow authenticated reads/writes.
- **Gradle JVM Error:** The Android build might fail if the `JAVA_HOME` environment variable is pointing to Java 8. Flutter uses its bundled Java 17, but standalone Gradle tasks require Java 17+.
- **Android Manifest Permissions:** The app requires `CAMERA`, `RECORD_AUDIO`, `ACCESS_FINE_LOCATION`, and `VIBRATE` permissions.
- **Alignments:** Signup and Login screens were explicitly mirrored to use the exact same glassmorphic design to prevent visual jarring during navigation.

## 6. How to Continue Development
1. Always maintain the strict Aura Guard design language. Do not use default white Flutter Cards or basic AppBars.
2. If adding new map features, ensure Google Cloud billing/APIs are active.
3. Keep background services in mind: iOS and Android aggressively kill background location/audio processing unless proper foreground services are implemented.
