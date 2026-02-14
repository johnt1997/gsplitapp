# Guinness Rater

Rate Guinness pints with AI-powered pour analysis. Snap a photo, get an AI score, and share your ratings with the community.

## Features

- **AI Pour Analysis** - Google Gemini analyzes your Guinness photo for head size, creaminess, dome shape, split line sharpness, and color
- **Interactive Glass Rating** - Custom drag-to-rate glass widget with animated fill level and haptic feedback
- **Pub Map** - Interactive Google Maps view with custom markers and marker clustering
- **Review System** - Rate pints on multiple criteria (head/foam, presentation), add notes, price, Guinness type, and serving style
- **Badge System** - Earn badges across 6 categories: Passport, Variety, Quality, Location, Timing, and Special
- **Offline Support** - Local caching with Drift (SQLite) and automatic sync queue with retry logic
- **Real-time Ratings** - Live pub ratings and "hot" indicators for recently reviewed pubs

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| Auth | Firebase Authentication |
| Database | Cloud Firestore |
| Storage | Firebase Storage |
| AI | Google Generative AI (Gemini) |
| On-device ML | TFLite Flutter |
| Maps | Google Maps + Flutter Map (OpenStreetMap) |
| Location | Geolocator |
| State Management | Provider |
| Local Cache | Drift (SQLite) |
| UI Effects | Glassmorphism, Lottie, Shimmer |

## Project Structure

```
lib/
├── main.dart                  # App entry point & theme setup
├── auth_wrapper.dart          # Auth state routing
├── firebase_options.dart      # Firebase config
├── models/
│   └── models.dart            # AppUser, Pub, Review, Badge, CachedReview
├── providers/
│   └── review_provider.dart   # Review flow state management
├── screens/
│   ├── login_screen.dart      # Authentication UI
│   ├── map_screen.dart        # Main map with pub listings
│   ├── pub_selection_screen.dart
│   └── review_screen.dart     # Multi-step review workflow
├── services/
│   ├── auth_service.dart      # Firebase Auth wrapper
│   ├── ai_service.dart        # Gemini pour analysis
│   ├── pub_service.dart       # Firestore pub operations
│   ├── map_service.dart       # Map utilities
│   └── openstreetmap_service.dart
└── widgets/
    ├── brutal_button.dart     # Custom button component
    ├── brutal_pub_sheet.dart  # Pub details bottom sheet
    ├── guinness_glass_rating.dart  # Interactive glass rating widget
    ├── mini_guinness_marker.dart   # Custom map markers
    └── about_shamrock.dart    # About/info widget
```

## Getting Started

### Prerequisites

- Flutter SDK 3.10.4+
- Firebase project with Firestore, Storage, and Auth enabled
- Google Gemini API key
- Google Maps API key

### Setup

```bash
# Install dependencies
flutter pub get

# Generate model serialization code
flutter pub run build_runner build
```

### Configuration

1. **Firebase** - Place `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in the respective platform directories
2. **Gemini API Key** - Configure in `lib/services/ai_service.dart`
3. **Google Maps API Key** - Add to Android manifest and iOS runner

### Run

```bash
# Debug
flutter run

# Release build
flutter build apk --release    # Android
flutter build ios --release    # iOS
flutter build web --release    # Web
```

## How It Works

1. **Snap** - Take a photo of your Guinness pint
2. **Analyze** - Gemini AI evaluates the pour quality (score 0-10)
3. **Rate** - Add your manual rating, notes, price, and Guinness type
4. **Share** - Submit to the community map with pub location

Pours scoring 8.5+ earn the "Perfect Pour" badge.

## Design

The app uses a "brutal" design aesthetic with the Guinness brand palette:

- **Gold** `#D4AF37` - Accents and highlights
- **Cream** `#F5E6D3` - Text and secondary elements
- **Black** `#0D0D0D` - Background

Glassmorphism effects, haptic feedback, and Lottie animations throughout.

## Status

MVP in development
