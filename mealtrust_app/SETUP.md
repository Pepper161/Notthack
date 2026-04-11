# MealTrust Flutter App — Setup Guide

## 1. Prerequisites

- Flutter SDK installed (https://docs.flutter.dev/get-started/install)
- Android Studio or VS Code with Flutter extension
- Android emulator or physical device

## 2. Install dependencies

```bash
flutter pub get
```

## 3. Android permissions (required for camera / QR scanning)

Edit `android/app/src/main/AndroidManifest.xml` and add inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

Also set `minSdkVersion` to **21** in `android/app/build.gradle`:
```gradle
defaultConfig {
    minSdkVersion 21
    ...
}
```

## 4. iOS permissions (if targeting iOS)

Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>MealTrust needs camera access to scan QR codes.</string>
```

## 5. Run the app

```bash
flutter run
```

## 6. Connect to the backend

The app points to `http://10.0.2.2:3000/api` by default (Android emulator → host localhost).

- **Android emulator**: works as-is, run the Node.js backend with `node src/index.js`
- **Physical device**: change `baseUrl` in `lib/services/api_service.dart` to your machine's LAN IP  
  (e.g. `http://192.168.1.50:3000/api`)
- **iOS simulator**: change `baseUrl` to `http://localhost:3000/api`

## 7. File structure

```
lib/
├── main.dart                  — App entry point + theme
├── models/voucher.dart        — Voucher, AuditEvent, VerifyResult models
├── services/api_service.dart  — All HTTP calls to backend
└── screens/
    ├── home_screen.dart       — Role selector (4 cards)
    ├── issuer_screen.dart     — Issue + manage vouchers
    ├── student_screen.dart    — Student QR pass
    ├── merchant_screen.dart   — QR scanner + verify + redeem
    └── auditor_screen.dart    — Audit event timeline
```
