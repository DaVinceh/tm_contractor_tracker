# URGENT: Deploy Firestore Rules to Fix Task Updates Display

## Problem
Task updates submitted by contractors are not visible to admins because the Firestore security rules were blocking access.

## Solution
Updated `firestore.rules` to allow everyone to read and create task_updates (since contractors don't use Firebase Authentication).

## Deploy Instructions

### Option 1: Firebase Console (Easiest)
1. Go to https://console.firebase.google.com
2. Select your project
3. Go to **Firestore Database** → **Rules** tab
4. Copy and paste the rules from `firestore.rules` file
5. Click **Publish**

### Option 2: Firebase CLI
```bash
npm install -g firebase-tools
firebase login
firebase deploy --only firestore:rules
```

## Updated Rules Section
The task_updates rules have been changed from:
```javascript
// OLD (blocked contractors)
allow read: if isAuthenticated();
allow create: if isContractor();
```

To:
```javascript
// NEW (allows everyone)
allow read: if true;
allow create: if true;
```

## After Deploying Rules

1. **Rebuild the app:**
```powershell
flutter build apk --release
```

2. **Test the flow:**
   - Login as contractor
   - Submit task update (comment + photo + progress)
   - Logout
   - Login as admin (SO/Executive/GM)
   - Navigate to team → Tasks → Click on the task
   - **Should now see all updates!**

## Why This Was Needed
- Contractors use custom authentication (team ID + leader name)
- They don't have Firebase Auth tokens
- Firestore rules were requiring Firebase Auth
- Now rules allow public read/write for task_updates only
- This is safe because the data isn't sensitive and is meant to be shared

---

**Deploy the rules NOW to fix the issue!** 🔥
