# Veera Safety App

## Overview

The **Veera Safety App** is an intelligent, hardware-integrated personal safety application built with Flutter. It is designed to provide real-time threat detection, automated emergency alerts, and seamless multi-channel SOS broadcasting. The application also includes low-latency driver and user monitoring capabilities, aiming to enhance personal safety and provide peace of mind.

## Key Features

The application offers a comprehensive suite of safety features designed for high-reliability environments:

| Feature | Description |
| :--- | :--- |
| **Real-time Threat Detection** | Utilizes advanced AI services for proactive threat identification and assessment. |
| **Automated Emergency Alerts** | Instant notifications sent to predefined emergency contacts during critical situations. |
| **Multi-channel SOS** | Seamless broadcasting of SOS alerts across multiple communication channels. |
| **Driver & User Monitoring** | Low-latency monitoring to ensure safety during transit or high-risk activities. |
| **Geofencing & Tracking** | Define safe zones, track journeys, and share real-time location with trusted contacts. |
| **Stealth Mode** | Specialized interface and services for discreet safety monitoring. |
| **Evidence Collection** | Automated services for gathering and securely managing digital evidence. |

## Technology Stack

The Veera Safety App leverages a robust set of modern technologies and libraries to ensure performance and reliability.

### Core Framework & Backend
*   **Flutter:** Cross-platform UI toolkit for high-performance mobile and web deployment.
*   **Firebase Ecosystem:** Integrated with `firebase_core`, `firebase_auth`, `firebase_messaging`, and `firebase_database` for real-time synchronization and secure authentication.

### Geospatial & Mapping
*   **Google Maps Platform:** Utilizes `google_maps_flutter`, `flutter_polyline_points`, and specialized `directions_service` and `places_service` for accurate navigation and location tracking.
*   **Geolocator:** High-precision location services for real-time monitoring.

### AI & Hardware Integration
*   **AI Services:** Powered by `google_generative_ai` for intelligent threat analysis.
*   **Hardware Access:** Deep integration with device hardware using `camera`, `record` (audio), `sensors_plus`, `battery_plus`, and `vibration`.
*   **Voice Integration:** Includes `speech_to_text` and dedicated `voice_service` for hands-free operation.

## Installation & Setup

To set up a local development environment, please follow these instructions.

### Prerequisites
*   **Flutter SDK:** Ensure you have the latest version of Flutter installed. Refer to the [Official Flutter Installation Guide](https://flutter.dev/docs/get-started/install ).
*   **Firebase Account:** A Firebase project is required for backend services.

### Steps
1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/soumilsaini07-code/veera-safety-app.git
    cd veera-safety-app
    ```

2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Firebase Configuration:**
    *   Place your `google-services.json` in the `android/app/` directory.
    *   Place your `GoogleService-Info.plist` in the `ios/Runner/` directory.
    *   Ensure `firestore.rules` are correctly deployed to your Firebase console.

4.  **Run the Application:**
    ```bash
    flutter run
    ```

## Contributing

We welcome contributions to improve the safety and functionality of Veera.
1.  **Fork** the project.
2.  **Create** your feature branch (`git checkout -b feature/AmazingFeature` ).
3.  **Commit** your changes (`git commit -m 'Add some AmazingFeature'`).
4.  **Push** to the branch (`git push origin feature/AmazingFeature`).
5.  **Open** a Pull Request.

## License

This project is distributed under the **MIT License**.
