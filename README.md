# EduTrack — Smart Student Planner

EduTrack is a Flutter student-planner application for organizing tasks and academic activities.

## Features
- Firebase Authentication for sign-in and registration
- Task creation, editing, details, and status tracking
- Monthly calendar with task lookup by date
- Dashboard summaries and task statistics
- In-app notifications and Firebase Cloud Messaging integration
- Profile management and theme settings

## Architecture
```
Screens → Provider → Repository → Service → Firebase
```
- **Screens:** UI and user interaction
- **Providers:** application state and loading/error handling
- **Repositories:** data mapping and application-facing operations
- **Services:** Firebase and platform integrations
- **Models:** typed application data

## Tech stack
- Flutter / Dart
- Provider
- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Messaging
- Shared Preferences

## Setup
1. Install the Flutter SDK and configure Android tooling.
2. Clone this repository.
3. Run `flutter pub get`.
4. Configure Firebase for your target platform using Firebase Console and FlutterFire CLI.
5. Enable Email/Password sign-in in Firebase Authentication.
6. Review Firestore security rules and configure authenticated, owner-scoped access before deploying.
7. Run `flutter run`.

## Verification
Run locally before a release:
```bash
flutter analyze
flutter test
```

## Known limitations
- The notification preference toggle in Settings is not yet persisted.
- Additional model-level unit tests can be added.
- This is a development/learning project. Verify Firebase rules and deployment configuration before production use.

## Author
Gusty Faqikh
