# RunTogether: Track Your Running Journey

RunTogether is a personal Flutter app designed for two friends to track their runs together, plan activities, and share daily Bible verses. Simple, focused, and personal.

## Features

### 🏃‍♂️ Fitness Tracking
- Real-time GPS tracking for runs
- Distance and duration monitoring
- Running statistics and progress charts
- Weekly and monthly activity summaries
- View each other's running progress

### 📅 Activity Planning
- Interactive calendar for planning runs and activities
- Location and activity details
- Shared calendar view
- Reminders for upcoming activities
- Notes for each plan

### ✝️ Daily Inspiration (Coming Soon)
- Daily Bible verse sharing
- Save favorite verses
- Share thoughts on verses

### 📱 Core Features
- Clean, modern interface
- Secure authentication
- Push notifications for activities
- Real-time data sync between two users
- Running statistics

## Technical Specifications

### Prerequisites
- Flutter SDK (latest stable version)
- Firebase account
- Android Studio / Xcode for mobile deployment
- Minimum iOS 12.0 / Android 5.0 (API 21)

### Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_messaging: ^14.7.10
  flutter_local_notifications: ^16.3.0
  flutter_riverpod: ^2.4.9
  geolocator: ^10.1.0
  table_calendar: ^3.0.9
  intl: ^0.18.1
  fl_chart: ^0.66.0
```

## Installation

1. Clone the repository:
```bash
git clone https://github.com/DroneCodes/run_together.git
cd run_together
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
```bash
flutterfire configure
```

4. Update Firebase configuration:
    - Add `google-services.json` to `android/app/`
    - Add `GoogleService-Info.plist` to `ios/Runner/`

5. Run the app:
```bash
flutter run
```

## Firebase Setup

1. Create a new Firebase project
2. Enable Authentication with Email/Password
3. Set up Cloud Firestore with the following collections:
    - `users` (just two users)
    - `running_activities`
    - `activity_plans`

## Required Permissions

### Android
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE" />
```

### iOS
Add to `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to location when running to track your route.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs access to location when in the background to track your route.</string>
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

## Project Structure
```
lib/
├── main.dart
├── models/
│   ├── running_activity.dart
│   └── activity_plan.dart
├── pages/
│   ├── auth/
│   │   ├── login_page.dart
│   │   └── signup_page.dart
│   ├── running_tracker_page.dart
│   ├── activity_planner_page.dart
│   └── running_stats_page.dart
├── providers/
│   ├── auth_provider.dart
│   ├── running_provider.dart
│   └── plans_provider.dart
└── services/
    └── notification_service.dart
```

## Future Features
- Bible verse integration
- Personal records tracking
- Route mapping
- Achievement milestones
- Weather integration for run planning

## Support
For issues, please open a GitHub issue in the repository.