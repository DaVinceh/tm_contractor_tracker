# 🔥 Firebase Test Credentials & Setup Guide

## Quick Setup Summary

### ✅ What You've Done
1. Created Firebase project
2. Added Android app with package `com.tm.contractor_tracker`
3. Downloaded and added `google-services.json` to `android/app/`
4. Enabled Firebase Authentication (Email/Password)
5. Enabled Firestore Database
6. Enabled Firebase Storage
7. Set Firestore to test mode
8. Built APK successfully

---

## 🔐 Test Credentials

### 👷 Contractor Login (Team ID + Leader Name)

#### ✅ WORKING - Team 001
```
Team ID: TEAM001
Leader Name: John Doe
```
**Status:** Successfully created in Firestore
**Access:** Contractor dashboard, check-in, tasks

---

### 👤 Admin Login (Email + Password)

#### 🏢 GM/AGM Dashboard
```
Email: gm@tm.com
Password: Test@123
```
**Access:** View all executives, site officers, complete system overview

---

#### 📊 Executive Dashboard
```
Email: executive@tm.com
Password: Test@123
```
**Access:** View all site officers, generate reports, export Excel

---

#### 🔧 Site Officer Dashboard
```
Email: so1@tm.com
Password: Test@123
```
**Access:** Manages contractor teams

---

## 🔧 How Admin Login Works (AUTO-SETUP)

### First Time Login
When an admin logs in for the first time:

1. **Authentication:** Uses Firebase Authentication (email/password)
2. **Auto-Detection:** App automatically detects role from email:
   - `gm@*.com` → GM/AGM role
   - `executive@*.com` → Executive role
   - `so*@*.com` → Site Officer role
3. **Auto-Create:** App creates Firestore user document with:
   - Email from Firebase Auth
   - Role based on email pattern
   - Name extracted from email
   - Timestamps

### What You Need to Do

#### Step 1: Create Admin Users in Firebase Authentication
1. Go to Firebase Console
2. Navigate to **Authentication > Users**
3. Click **Add User**
4. For each admin:
   - Enter email (e.g., `gm@tm.com`)
   - Enter password: `Test@123`
   - Click **Add User**

Create these users:
- ✅ `gm@tm.com` (GM/AGM)
- ✅ `executive@tm.com` (Executive)
- ✅ `so1@tm.com` (Site Officer 1)
- ✅ `so2@tm.com` (Site Officer 2) [Optional]

#### Step 2: Login via App
1. Install APK on Android phone
2. Select **Admin Login**
3. Enter email: `gm@tm.com`
4. Enter password: `Test@123`
5. Click Login
6. **First time:** App will auto-create Firestore user document
7. You'll be redirected to the appropriate dashboard

---

## 📱 How to Login

### For Admins (First Time):
1. Open app
2. Select **"Admin Login"**
3. Enter email (e.g., `gm@tm.com`)
4. Enter password (`Test@123`)
5. Click Login
6. Wait for auto-setup (2-3 seconds)
7. Dashboard appears!

### For Contractors:
1. Open app
2. Select **"Contractor Login"**
3. Enter Team ID (e.g., `TEAM001`)
4. Enter Leader Name (e.g., `John Doe`)
5. Click Login
6. If team doesn't exist in Firestore, create it manually or set test mode

---

## 🗂️ Firestore Collections (Auto-Created)

### ✅ `users` Collection
Auto-created when admin logs in for the first time.

**Document Structure:**
```json
{
  "email": "gm@tm.com",
  "role": "gmAgm",
  "name": "GM",
  "created_at": "2025-11-10T10:30:00Z",
  "updated_at": "2025-11-10T10:30:00Z",
  "manager_id": null,
  "team_id": null
}
```

**Roles:**
- `contractor` - Contractor team leader
- `so` - Site Officer
- `executive` - Executive
- `gmAgm` - GM/AGM

---

### ✅ `contractor_teams` Collection
Must be created manually or via app.

**Example Document (TEAM001):**
```json
{
  "team_id": "TEAM001",
  "leader_name": "John Doe",
  "so_id": "dummy-so-id",
  "members": ["John Doe", "Alex Brown"],
  "location": "Kuala Lumpur",
  "created_at": "2025-11-10T10:00:00Z"
}
```

---

### 🔄 Other Collections (Created by App Usage)
- `attendance` - Check-in records
- `tasks` - Assigned tasks
- `task_updates` - Task progress updates

---

## 🚨 Troubleshooting

### Issue: Admin stays on login page
**Cause:** Firebase Authentication user doesn't exist
**Solution:** 
1. Go to Firebase Console > Authentication
2. Check if user email exists
3. If not, click "Add User" and create it
4. Try logging in again

---

### Issue: Permission denied error
**Cause:** Firestore rules are too restrictive
**Solution:**
1. Go to Firebase Console > Firestore Database > Rules
2. Set to test mode:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```
3. Publish rules
4. Try again

---

### Issue: Contractor login fails
**Cause:** Team doesn't exist in Firestore
**Solution 1 - Manual Creation:**
1. Go to Firebase Console > Firestore Database
2. Click "Start Collection"
3. Collection ID: `contractor_teams`
4. Add document with fields:
   - `team_id`: "TEAM001"
   - `leader_name`: "John Doe"
   - `so_id`: "dummy-so-id"
   - `created_at`: (timestamp) now

**Solution 2 - Use Test Mode:**
Set Firestore to test mode (allow all reads/writes)
App will auto-create contractor user on login

---

### Issue: Image upload fails
**Cause:** Firebase Storage not enabled or no bucket
**Solution:**
1. Go to Firebase Console > Storage
2. Click "Get Started"
3. Choose production mode or test mode
4. Upload will create folders automatically

---

## 🎯 Testing Checklist

### Admin Login Tests
- [ ] Login as `gm@tm.com` → Should see GM/AGM Dashboard
- [ ] Login as `executive@tm.com` → Should see Executive Dashboard
- [ ] Login as `so1@tm.com` → Should see SO Dashboard
- [ ] Check user document auto-created in Firestore users collection
- [ ] Check role is correctly assigned

### Contractor Login Tests
- [ ] Login with TEAM001 / John Doe → Should see Contractor Dashboard
- [ ] Perform GPS check-in → Should create attendance record
- [ ] View tasks (if any)
- [ ] Upload task update with photo

---

## 📊 Role Hierarchy

```
GM/AGM (gm@tm.com)
  └── Executive (executive@tm.com)
      └── Site Officer (so1@tm.com, so2@tm.com)
          └── Contractors (TEAM001, TEAM002, TEAM003, etc.)
```

---

## 🔐 Security Notes

### Current Setup (Development)
- Firestore: Test mode (allow all reads/writes)
- Authentication: Email/Password enabled
- Storage: Test mode (allow all uploads)

### For Production
⚠️ **IMPORTANT:** Before going live:
1. Update Firestore rules to restrict access by role
2. Use production security rules (see `firestore.rules`)
3. Enable proper user management
4. Change all passwords from `Test@123`
5. Set up proper manager_id relationships
6. Enable email verification
7. Add rate limiting

---

## 🎉 Next Steps

1. **Create Admin Users:**
   - Go to Firebase Authentication
   - Add users: gm@tm.com, executive@tm.com, so1@tm.com

2. **Test Admin Login:**
   - Install APK on phone
   - Login with each admin credential
   - Verify dashboard appears
   - Check Firestore for auto-created user documents

3. **Create Contractor Teams:**
   - Manually add TEAM001 in Firestore, OR
   - Keep test mode to let app create on login

4. **Test Full Flow:**
   - Contractor check-in
   - Admin view teams
   - Task assignment
   - Progress tracking

---

## 📝 Default Password

**All users:** `Test@123`

⚠️ **Security Warning:** Change these passwords in production!

---

## 📦 Latest APK

**Location:** `build\app\outputs\flutter-apk\app-release.apk`
**Size:** 22.7MB
**Build Date:** November 10, 2025
**Features:**
- ✅ Auto-create admin users on first login
- ✅ Role detection from email
- ✅ Firebase Authentication
- ✅ Firestore integration
- ✅ Timestamp handling
- ✅ GPS check-in
- ✅ Task management

---

**Happy Testing! 🔥**
