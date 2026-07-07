# Guinness Rater

Rate Guinness pints with AI-powered pour analysis. Snap a photo, get an AI score, and share your ratings with friends.

## Features

- **AI Pour Analysis** - OpenAI (gpt-4o-mini) analyzes your Guinness photo for head size, creaminess, dome shape, split line sharpness, and color
- **Interactive Glass Rating** - Custom drag-to-rate glass widget with animated fill level and haptic feedback
- **Pub Map** - OpenStreetMap (flutter_map) with custom Guinness-glass markers, real GPS location, and long-press to add new pubs
- **Review System** - Photo, rating, notes, price, and Guinness type — every review is tied to your account and shows your name
- **Photo Upload** - Review photos are stored in Firebase Storage and shown in the pub sheet
- **Profile** - Your review history, stats (total reviews, average rating, perfect pours, streak) and badge collection
- **Badges** - Earn badges for visited pubs, perfect pours, streaks, night/early sessions and more
- **Likes** - Like your friends' reviews (one like per user)
- **Real-time Ratings** - Live pub averages and "hot" indicators for highly rated pubs

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| Auth | Firebase Authentication (email/password) |
| Database | Cloud Firestore |
| Photo Storage | Firebase Storage |
| AI | OpenAI gpt-4o-mini (vision) |
| Maps | flutter_map (OpenStreetMap, CartoDB dark tiles) |
| Location | Geolocator |
| State Management | Provider |

## Project Structure

```
lib/
├── main.dart                  # App entry point & theme setup
├── auth_wrapper.dart          # Auth state routing
├── firebase_options.dart      # Firebase config
├── data/
│   └── badges_catalog.dart    # Badge definitions
├── models/
│   └── models.dart            # AppUser, Pub, Review, Badge
├── providers/
│   └── review_provider.dart   # Review flow state management
├── screens/
│   ├── login_screen.dart      # Authentication UI
│   ├── map_screen.dart        # Main map, GPS, add-pub dialog
│   ├── profile_screen.dart    # Stats, history, badges, logout
│   └── review_screen.dart     # Multi-step review workflow
├── services/
│   ├── auth_service.dart      # Firebase Auth wrapper
│   ├── ai_service.dart        # OpenAI pour analysis
│   ├── pub_service.dart       # Firestore pub operations
│   ├── user_stats_service.dart # Stats & badge unlocks after review
│   └── openstreetmap_service.dart # FlutterMap rendering
└── widgets/
    ├── brutal_button.dart     # Custom button component
    ├── brutal_pub_sheet.dart  # Pub details bottom sheet (reviews, likes)
    ├── guinness_glass_rating.dart  # Interactive glass rating widget
    ├── mini_guinness_marker.dart   # Custom map markers
    ├── map_container.dart     # Map wrapper widget
    └── about_shamrock.dart    # About/info dialog
```

## Getting Started

### Prerequisites

- Flutter SDK 3.10.4+
- A Firebase project with **Firestore**, **Storage**, and **Auth (Email/Password)** enabled
- An OpenAI API key (for the pour analysis — the app works without it, you just lose the AI score)

### Setup

```bash
# Install dependencies
flutter pub get

# Generate model serialization code
dart run build_runner build --delete-conflicting-outputs
```

### Configuration

1. **OpenAI Key** — copy `.env.example` to `.env` and paste your key.
   ⚠️ The `.env` file is bundled into the app binary as an asset. Anyone who unpacks the APK can extract the key. That is acceptable for testing with friends, but **rotate the key and move AI calls behind a backend before any public release.** Never commit `.env` (it is gitignored).
2. **Firebase (Android)** — Firebase Console → Project settings → *Your apps* → Android app (`com.example.gsplit`) → download `google-services.json` → put it in `android/app/google-services.json`. Without it the Android build fails.
3. **Firebase (iOS)** — same place, iOS app → download `GoogleService-Info.plist` → put it in `ios/Runner/GoogleService-Info.plist` (add it to the Runner target in Xcode).
4. **Web** needs no extra file — `lib/firebase_options.dart` already contains the web config.

### Run

```bash
flutter run -d chrome        # fastest for UI development on Windows
flutter run                  # Android device/emulator
flutter build apk --release  # share with friends via APK
```

## Developing on Windows, shipping to iOS

The app is developed entirely on Windows (Chrome + Android). For iOS you need macOS to build:

1. Use a CI service like **Codemagic** (Flutter-native, free tier) to build and sign the iOS app in the cloud — no Mac required.
2. You need an **Apple Developer account** (~99 €/year) to distribute to friends via TestFlight.
3. `ios/Runner/Info.plist` already contains the camera/photo permission strings.

## How It Works

1. **Snap** - Take a photo of your Guinness pint
2. **Analyze** - The AI evaluates the pour quality (score 0-10)
3. **Rate** - Add your manual rating, notes, price, and Guinness type
4. **Share** - Submit to the map; friends see your name, photo and rating live

Pours scoring 8.5+ count as a "Perfect Pour".

## Design

The app uses a "brutal" design aesthetic with the Guinness brand palette:

- **Gold** `#D4AF37` - Accents and highlights
- **Cream** `#F5E6D3` - Text and secondary elements
- **Black** `#0D0D0D` - Background

## Status

MVP — fun-with-friends stage.
