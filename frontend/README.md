# CreatorAI Frontend

Flutter mobile application for CreatorAI — AI-powered content analysis for Instagram creators.

## Local Setup

### 1. Prerequisites
- Flutter SDK 3.0+
- Android Studio / Xcode (for emulators)
- Dart SDK (bundled with Flutter)

### 2. Install Dependencies
```bash
cd frontend
flutter pub get
```

### 3. Run the App
```bash
# Development (with hot reload)
flutter run

# With environment overrides
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1 \
            --dart-define=SUPABASE_URL=https://your-project.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=your-key
```

### 4. Run Tests
```bash
flutter test
```

### 5. Build
```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release
```

## Project Structure

```
lib/
├── main.dart              # Entry point
├── app.dart               # MaterialApp with router + theme
├── config/                # App config, routes, theme
├── models/                # Data models (User, Analysis, ApiResponse)
├── providers/             # Riverpod state management
├── screens/               # Full-page screens
├── services/              # API, auth, and storage services
├── widgets/               # Reusable UI components
│   ├── common/            # State widgets (loading, empty, error)
│   ├── analysis/          # Score badge, result cards
│   └── input/             # Content input fields
└── utils/                 # Constants, validators, extensions
```
