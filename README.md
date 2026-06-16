Veera Safety App

Overview

The Veera Safety App is an intelligent, hardware-integrated personal safety application built with Flutter. It is designed to provide real-time threat detection, automated emergency alerts, and seamless multi-channel SOS broadcasting. The application also includes low-latency driver and user monitoring capabilities, aiming to enhance personal safety and provide peace of mind.

Features

Based on the file structure and service names, the Veera Safety App appears to offer a comprehensive suite of safety features, including:

•
Real-time Threat Detection: Utilizing AI services for proactive threat identification.

•
Automated Emergency Alerts: Instant notifications to predefined contacts during emergencies.

•
Multi-channel SOS Broadcasting: Seamlessly send SOS alerts through various communication channels.

•
Low-latency Driver and User Monitoring: Continuous tracking and monitoring for enhanced safety.

•
Geofencing: Define safe zones and receive alerts upon entry or exit.

•
Journey Tracking: Monitor and record travel routes.

•
Live Tracking: Share real-time location with trusted contacts.

•
Evidence Collection: Services for gathering and managing evidence.

•
Voice Services: Integration for voice-activated commands or communication.

•
Authentication: Secure user login and registration.

Technologies Used

The application is developed using Flutter and leverages a variety of powerful libraries and services:

•
Flutter: UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase.

•
Firebase: Backend services including:

•
firebase_core

•
firebase_auth

•
firebase_messaging

•
firebase_database



•
Google Maps & Location Services:

•
google_maps_flutter

•
flutter_polyline_points

•
geolocator

•
places_service

•
directions_service



•
AI & Voice:

•
google_generative_ai

•
speech_to_text

•
voice_service



•
Sensors & Hardware Integration:

•
sensors_plus

•
camera

•
record

•
battery_plus

•
vibration



•
Other Key Libraries:

•
cupertino_icons

•
google_fonts

•
gallery_saver_plus

•
google_sign_in

•
provider

•
url_launcher

•
shared_preferences

•
intl

•
flutter_ringtone_player

•
http

•
path_provider



Installation

To get a local copy up and running, follow these simple steps.

Prerequisites

Ensure you have Flutter installed. If not, follow the official Flutter installation guide: Flutter Installation Guide

Setup

1.
Clone the repository:

Bash


git clone https://github.com/soumilsaini07-code/veera-safety-app.git
cd veera-safety-app





2.
Install dependencies:

Bash


flutter pub get





3.
Firebase Setup:

This project uses Firebase. You will need to set up your own Firebase project, add Android and iOS apps, and download google-services.json (for Android ) and GoogleService-Info.plist (for iOS) into the respective android/app and ios/Runner directories. Refer to the Firebase documentation for detailed instructions.



4.
Run the application:

Bash


flutter run





Usage

(Further details on how to use the application would go here, once specific functionalities are clearer from code analysis or user input.)

Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are greatly appreciated.

1.
Fork the Project

2.
Create your Feature Branch (git checkout -b feature/AmazingFeature)

3.
Commit your Changes (git commit -m 'Add some AmazingFeature')

4.
Push to the Branch (git push origin feature/AmazingFeature)

5.
Open a Pull Request

License

Distributed under the MIT License. See LICENSE for more information.


