# Firebase Setup Guide

## Step 1: Create Firebase Project

1. Go to https://console.firebase.google.com/
2. Click "Add project" or "Create a project"
3. Enter project name: **TM Contractor Tracker**
4. (Optional) Enable Google Analytics
5. Click "Create project"

## Step 2: Add Android App to Firebase

1. In your Firebase project, click the **Android icon** to add an Android app
2. Register app with these details:
   - **Android package name**: `com.tm.contractor_tracker`
   - **App nickname**: TM Contractor Tracker
   - **Debug signing certificate SHA-1**: (Optional - leave blank for now)
3. Click "Register app"

## Step 3: Download google-services.json

1. Download the `google-services.json` file
2. Move this file to: `android/app/google-services.json`
3. **CRITICAL**: The file MUST be placed in the `android/app/` folder

## Step 4: Enable Firebase Services

### Enable Authentication:
1. In Firebase Console, go to **Authentication**
2. Click "Get Started"
3. Go to **Sign-in method** tab
4. Enable **Email/Password**

### Enable Firestore Database:
1. Go to **Firestore Database**
2. Click "Create database"
3. Choose "Start in **production mode**" (we'll add rules next)
4. Select your preferred region
5. Click "Enable"

### Enable Storage:
1. Go to **Storage**
2. Click "Get started"
3. Start in **production mode**
4. Click "Done"

## Step 5: Set Up Firestore Security Rules

1. Go to **Firestore Database** > **Rules** tab
2. Copy the contents from `firestore.rules` file in this project
3. Click "Publish"

## Step 6: Set Up Storage Rules

1. Go to **Storage** > **Rules** tab
2. Replace with:
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /task-images/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```
3. Click "Publish"

## Step 7: Create Admin Users

1. Go to **Authentication** > **Users**
2. Click "Add user"
3. Create these admin accounts:

**GM/AGM Account:**
- Email: `gm@tm.com`
- Password: `Test@123`

**Executive Account:**
- Email: `executive@tm.com`
- Password: `Test@123`

**SO Accounts:**
- Email: `so1@tm.com` | Password: `Test@123`
- Email: `so2@tm.com` | Password: `Test@123`

## Step 8: Initialize Firestore Collections

You need to create the initial data manually or run initialization code. The app will create contractor users automatically on first login.

### Create Initial Teams (Optional):

1. Go to **Firestore Database**
2. Click "Start collection" named `contractor_teams`
3. Add documents with these fields:
   - team_id: "TEAM001"
   - leader_name: "John Doe"
   - so_id: (copy the UID from so1@tm.com in Authentication)
   - created_at: (server timestamp)
   - updated_at: (server timestamp)

4. Repeat for more teams (TEAM002, TEAM003, TEAM004)

## Step 9: Build and Test

1. Make sure `google-services.json` is in `android/app/`
2. Run: `flutter clean`
3. Run: `flutter pub get`
4. Build APK: `flutter build apk --release`
5. Install on your Android device
6. Test login with contractor: Team ID: TEAM001, Leader Name: John Doe

## Troubleshooting

**Error: "google-services.json not found"**
- Verify the file is in `android/app/google-services.json`
- Run `flutter clean` and rebuild

**Error: "FirebaseApp not initialized"**
- Make sure you ran `flutter pub get` after adding Firebase packages
- Check that main.dart calls `FirebaseConfig.initialize()`

**Authentication fails:**
- Verify Email/Password is enabled in Firebase Console
- Check that you created the user accounts
- Ensure Firestore security rules are published

**Data not saving:**
- Check Firestore security rules
- Verify collections exist
- Check Firebase Console logs
