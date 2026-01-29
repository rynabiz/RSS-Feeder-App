# RSS Feed Reader App

A simple, fast, and light RSS Feed Reader built with Flutter.

## Features
- **RSS Consumption**: Fetches news from RSS/XML feeds.
- **In-App Article View**: Reads articles using an integrated WebView.
- **Monetization**: Integrated Google AdMob (Banner & Interstitial).
- **Clean UI**: Minimalist, white-themed Material Design.

## Setup Instructions

### 1. Prerequisites
- Flutter SDK installed.
- Android Studio / VS Code configured.

### 2. Dependencies
Run the following command to install dependencies:
```bash
flutter pub get
```

### 3. Configuration

#### AdMob
The app is currently configured with **Test Ad Unit IDs**.
To use real ads for production, update `lib/services/ad_service.dart`:
1.  Replace `bannerAdUnitId` with your AdMob Banner ID.
2.  Replace `interstitialAdUnitId` with your AdMob Interstitial ID.
3.  Ensure your App ID is configured in `android/app/src/main/AndroidManifest.xml` (meta-data) if required by newer AdMob SDK versions (currently using standard test setup).

#### RSS Feeds
To add or change feeds, edit the `feedUrls` list in `lib/services/rss_service.dart`:
```dart
final List<String> feedUrls = [
  'https://feeds.bbci.co.uk/news/world/rss.xml',
  // Add more URLs here
];
```

## Build

### Debug
```bash
flutter run
```

### Release APK
```bash
flutter build apk --release
```
The APK will be located at `build/app/outputs/flutter-apk/app-release.apk`.
