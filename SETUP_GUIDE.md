# Setup Guide - TM Contractor Tracker

This guide will walk you through setting up the TM Contractor Tracker application from scratch.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Flutter Setup](#flutter-setup)
3. [Supabase Setup](#supabase-setup)
4. [Google Maps Setup](#google-maps-setup)
5. [App Configuration](#app-configuration)
6. [Running the App](#running-the-app)
7. [Testing](#testing)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software

- **Flutter SDK** (3.0 or higher)
  - Download from: https://flutter.dev/docs/get-started/install
  - Verify installation: `flutter doctor`

- **Android Studio** or **VS Code**
  - Android Studio: https://developer.android.com/studio
  - VS Code with Flutter extension: https://code.visualstudio.com/

- **Git**
  - Download from: https://git-scm.com/

### Required Accounts

- **Supabase Account** (Free tier available)
  - Sign up at: https://supabase.com

- **Google Cloud Account** (For Maps API)
  - Sign up at: https://console.cloud.google.com/

---

## Flutter Setup

### 1. Install Flutter

**Windows:**
```powershell
# Download Flutter SDK and extract to C:\src\flutter
# Add to PATH: C:\src\flutter\bin

flutter doctor
```

**macOS/Linux:**
```bash
# Download and extract Flutter
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

flutter doctor
```

### 2. Install Dependencies

```bash
cd tm_contractor_tracker
flutter pub get
```

### 3. Verify Installation

```bash
flutter doctor -v
```

Ensure all checkmarks are green. Install any missing dependencies.

---

## Supabase Setup

### 1. Create a New Project

1. Go to https://supabase.com/dashboard
2. Click "New Project"
3. Fill in:
   - **Name**: TM Contractor Tracker
   - **Database Password**: (Create a strong password)
   - **Region**: Choose closest to your location
4. Click "Create new project"

### 2. Get Project Credentials

1. Go to **Settings** → **API**
2. Copy:
   - **Project URL** (e.g., https://xxxxx.supabase.co)
   - **anon public** key

### 3. Update App Configuration

Edit `lib/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String url = 'https://xxxxx.supabase.co'; // Your project URL
  static const String anonKey = 'eyJxxx...'; // Your anon key
}
```

### 4. Set Up Database

1. Go to **SQL Editor** in Supabase dashboard
2. Copy the complete SQL from `DATABASE_SCHEMA.md`
3. Click "Run" to execute the script

### 5. Create Storage Bucket

1. Go to **Storage** in Supabase dashboard
2. Click "New bucket"
3. Name: `task-images`
4. Set as **Public bucket**
5. Click "Create bucket"

### 6. Configure Storage Policies

Go to **Storage** → **Policies** and add:

```sql
-- Allow authenticated uploads
CREATE POLICY "Authenticated users can upload images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'task-images');

-- Allow public access
CREATE POLICY "Images are publicly accessible"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'task-images');
```

### 7. Create Test Users

In **Authentication** → **Users**, create test accounts:

**GM/AGM:**
- Email: gm@tm.com
- Password: Test@123

**Executive:**
- Email: executive@tm.com
- Password: Test@123

**Site Officer:**
- Email: so@tm.com
- Password: Test@123

Then in **SQL Editor**, link them to users table:

```sql
-- Insert GM/AGM
INSERT INTO users (id, email, role, name)
SELECT id, 'gm@tm.com', 'gmAgm', 'General Manager'
FROM auth.users WHERE email = 'gm@tm.com';

-- Insert Executive
INSERT INTO users (id, email, role, name, manager_id)
SELECT 
  u.id, 
  'executive@tm.com', 
  'executive', 
  'Executive Officer',
  (SELECT id FROM users WHERE email = 'gm@tm.com')
FROM auth.users u WHERE u.email = 'executive@tm.com';

-- Insert Site Officer
INSERT INTO users (id, email, role, name, manager_id)
SELECT 
  u.id, 
  'so@tm.com', 
  'so', 
  'Site Officer',
  (SELECT id FROM users WHERE email = 'executive@tm.com')
FROM auth.users u WHERE u.email = 'so@tm.com';

-- Create a test contractor team
INSERT INTO contractor_teams (team_id, leader_name, so_id)
VALUES (
  'TEAM001',
  'John Doe',
  (SELECT id FROM users WHERE email = 'so@tm.com')
);
```

---

## Google Maps Setup

### 1. Create Google Cloud Project

1. Go to https://console.cloud.google.com/
2. Create a new project: "TM Contractor Tracker"
3. Enable billing (required for Maps API)

### 2. Enable Maps SDK

1. Go to **APIs & Services** → **Library**
2. Search and enable:
   - Maps SDK for Android
   - Maps SDK for iOS

### 3. Create API Key

1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **API Key**
3. Copy the API key
4. Click **Restrict Key**:
   - For Android: Add package name restriction
   - For iOS: Add bundle identifier restriction

### 4. Configure Android

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest>
  <application>
    <!-- Add before closing application tag -->
    <meta-data
      android:name="com.google.android.geo.API_KEY"
      android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
  </application>
</manifest>
```

### 5. Configure iOS

Edit `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import GoogleMaps // Add this import

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY") // Add this line
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

Update `ios/Podfile`:

```ruby
platform :ios, '12.0' # Ensure minimum version is 12.0
```

---

## App Configuration

### 1. Android Configuration

Edit `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 33
    
    defaultConfig {
        applicationId "com.tm.contractor_tracker"
        minSdkVersion 21
        targetSdkVersion 33
        versionCode 1
        versionName "1.0.0"
    }
}
```

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    
    <application
        android:label="TM Contractor Tracker"
        android:icon="@mipmap/ic_launcher">
        <!-- Your activities and other configurations -->
    </application>
</manifest>
```

### 2. iOS Configuration

Edit `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to record check-in location</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs location access to record check-in location</string>

<key>NSCameraUsageDescription</key>
<string>This app needs camera access to upload task progress photos</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select images</string>
```

---

## Running the App

### 1. Check for Issues

```bash
flutter doctor -v
flutter pub get
```

### 2. Run on Emulator/Simulator

**Android:**
```bash
# List available devices
flutter devices

# Run on Android emulator
flutter run
```

**iOS (macOS only):**
```bash
# Open iOS Simulator
open -a Simulator

# Run on iOS simulator
flutter run
```

### 3. Run on Physical Device

**Android:**
1. Enable Developer Options on your Android device
2. Enable USB Debugging
3. Connect via USB
4. Run: `flutter run`

**iOS:**
1. Open Xcode
2. Sign the app with your Apple Developer account
3. Connect iPhone via USB
4. Run: `flutter run`

### 4. Build for Release

**Android APK:**
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**Android App Bundle:**
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

**iOS:**
```bash
flutter build ios --release
# Then use Xcode to archive and upload to App Store
```

---

## Testing

### Test Contractor Login

1. Open the app
2. Select "Contractor Login"
3. Enter:
   - Team ID: `TEAM001`
   - Leader Name: `John Doe`
4. Click "Login"

### Test Admin Login

1. Open the app
2. Select "Admin Login"
3. Enter:
   - Email: `so@tm.com`
   - Password: `Test@123`
4. Click "Login"

### Test Check-in

1. Login as contractor
2. Click "Check In Now"
3. Allow location permissions
4. Verify check-in success

### Test Task Updates

1. Login as contractor
2. Navigate to tasks
3. Open a task
4. Add comment and photo
5. Submit update

---

## Troubleshooting

### Common Issues

**1. Supabase Connection Error**
```
Solution: Verify URL and anon key in supabase_config.dart
```

**2. Location Permission Denied**
```
Solution: Check AndroidManifest.xml and Info.plist have location permissions
```

**3. Google Maps Not Showing**
```
Solution: 
- Verify API key is correct
- Ensure Maps SDK is enabled in Google Cloud
- Check API key restrictions
```

**4. Build Failed on iOS**
```
Solution:
cd ios
pod install
cd ..
flutter clean
flutter pub get
flutter run
```

**5. Images Not Uploading**
```
Solution:
- Check storage bucket name is 'task-images'
- Verify storage policies are set
- Check internet connection
```

### Debug Mode

Enable Flutter debug mode:
```bash
flutter run --debug
```

View logs:
```bash
flutter logs
```

### Clear Cache

```bash
flutter clean
flutter pub get
```

---

## Production Deployment

### Android Play Store

1. Build App Bundle:
   ```bash
   flutter build appbundle --release
   ```

2. Create keystore for signing
3. Update `android/key.properties`
4. Upload to Google Play Console

### iOS App Store

1. Build in Xcode with release configuration
2. Archive the app
3. Validate and upload to App Store Connect
4. Submit for review

---

## Next Steps

1. Customize app colors in `lib/utils/theme.dart`
2. Add your company logo to `assets/images/`
3. Update app name in `pubspec.yaml`
4. Configure push notifications (optional)
5. Set up analytics (optional)
6. Create admin panel for task creation (optional)

---

## Support

For issues or questions:
- Check GitHub Issues
- Email: support@tm-contractor-tracker.com
- Documentation: README.md and DATABASE_SCHEMA.md

---

**Happy Tracking! 🚀**
