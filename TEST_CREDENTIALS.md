# 🔐 Test Credentials & Setup Guide

## Quick Setup Steps

### 1. Run SQL Setup
1. Open your Supabase Dashboard
2. Go to **SQL Editor**
3. Copy all content from `supabase_setup.sql`
4. Run the script
5. Wait for "Success!" message

### 2. Create Authentication Users
Go to: **Supabase Dashboard > Authentication > Users > Add User**

Create these users **manually** with the credentials below:

---

## 👤 Admin Login Credentials (Email + Password)

### 🏢 GM/AGM Dashboard
```
Email: gm@tm.com
Password: Test@123
```
**Access:** View all executives, site officers, and complete system overview

---

### 📊 Executive Dashboard
```
Email: executive@tm.com
Password: Test@123
```
**Access:** View all site officers under management, generate reports, export Excel

---

### 🔧 Site Officer 1 Dashboard
```
Email: so1@tm.com
Password: Test@123
```
**Access:** Manages TEAM001 and TEAM002

---

### 🔧 Site Officer 2 Dashboard
```
Email: so2@tm.com
Password: Test@123
```
**Access:** Manages TEAM003 and TEAM004

---

## 👷 Contractor Login Credentials (Team ID + Leader Name)

### Team 001
```
Team ID: TEAM001
Leader Name: John Doe
```
- **Managed by:** Site Officer 1 (so1@tm.com)
- **Members:** John Doe, Alex Brown
- **Tasks:** Building Foundation Work, Steel Framework Installation

---

### Team 002
```
Team ID: TEAM002
Leader Name: Jane Smith
```
- **Managed by:** Site Officer 1 (so1@tm.com)
- **Members:** Jane Smith, Emily Davis
- **Tasks:** Electrical Wiring, Site Cleanup

---

### Team 003
```
Team ID: TEAM003
Leader Name: Mike Johnson
```
- **Managed by:** Site Officer 2 (so2@tm.com)
- **Members:** Mike Johnson, Chris Wilson
- **Tasks:** Plumbing Installation, Bathroom Fixture Installation

---

### Team 004
```
Team ID: TEAM004
Leader Name: Sarah Williams
```
- **Managed by:** Site Officer 2 (so2@tm.com)
- **Members:** Sarah Williams, Lisa Martinez
- **Tasks:** Painting (Completed), Flooring Installation

---

## 📧 Contractor Email Accounts (For RLS)

These email accounts need to be created in Supabase Auth for Row Level Security to work properly:

```
contractor1@tm.com - Password: Test@123 (John Doe - TEAM001)
contractor2@tm.com - Password: Test@123 (Alex Brown - TEAM001)
contractor3@tm.com - Password: Test@123 (Jane Smith - TEAM002)
contractor4@tm.com - Password: Test@123 (Emily Davis - TEAM002)
contractor5@tm.com - Password: Test@123 (Mike Johnson - TEAM003)
contractor6@tm.com - Password: Test@123 (Chris Wilson - TEAM003)
contractor7@tm.com - Password: Test@123 (Sarah Williams - TEAM004)
contractor8@tm.com - Password: Test@123 (Lisa Martinez - TEAM004)
```

⚠️ **Note:** Contractors login using Team ID + Leader Name in the app, but these email accounts must exist in Supabase Auth for the database policies to work.

---

## 🗂️ Sample Data Included

### ✅ 4 Contractor Teams
- TEAM001, TEAM002, TEAM003, TEAM004

### ✅ 8 Tasks
- Various statuses: pending, in_progress, completed
- Completion ranges: 5% to 100%

### ✅ Attendance Records
- Multiple check-ins from different locations
- GPS coordinates from various Malaysian cities

### ✅ Task Updates
- Progress comments
- Completion percentage updates

---

## 🧪 Testing Checklist

### Test Contractor Features
- [ ] Login with TEAM001 / John Doe
- [ ] Check dashboard shows tasks
- [ ] Perform GPS check-in
- [ ] View task details
- [ ] Upload task update with photo
- [ ] Add progress comment

### Test Site Officer Features
- [ ] Login with so1@tm.com
- [ ] View teams (TEAM001, TEAM002)
- [ ] Check team details
- [ ] View attendance records
- [ ] Check task progress

### Test Executive Features
- [ ] Login with executive@tm.com
- [ ] View all site officers
- [ ] Navigate to SO's teams
- [ ] Generate report (daily/weekly/monthly)
- [ ] View analytics charts
- [ ] Export Excel report

### Test GM/AGM Features
- [ ] Login with gm@tm.com
- [ ] View complete hierarchy
- [ ] Check all executives and SOs
- [ ] View system-wide statistics
- [ ] Generate comprehensive reports

---

## 📱 How to Login

### For Admins (SO, Executive, GM/AGM):
1. Open app
2. Select **"Admin Login"**
3. Enter email and password
4. Click Login

### For Contractors:
1. Open app
2. Select **"Contractor Login"**
3. Enter Team ID (e.g., TEAM001)
4. Enter Leader Name (e.g., John Doe)
5. Click Login

---

## 🔧 Storage Bucket Setup

Don't forget to create the storage bucket for task images:

1. Go to **Supabase Dashboard > Storage**
2. Click **New Bucket**
3. Name: `task-images`
4. Make it **Public**
5. Click **Create**

Or run this SQL:
```sql
INSERT INTO storage.buckets (id, name, public) 
VALUES ('task-images', 'task-images', true)
ON CONFLICT (id) DO NOTHING;
```

---

## 🚨 Troubleshooting

### Issue: Cannot login as contractor
**Solution:** Make sure the contractor email accounts are created in Supabase Auth

### Issue: Cannot see any data
**Solution:** Check that RLS policies are enabled and configured correctly

### Issue: Image upload fails
**Solution:** Verify `task-images` storage bucket exists and is public

### Issue: Admin cannot view teams
**Solution:** Check that manager_id relationships are set correctly in the users table

---

## 📊 Database Hierarchy

```
GM/AGM (gm@tm.com)
  └── Executive (executive@tm.com)
      ├── Site Officer 1 (so1@tm.com)
      │   ├── TEAM001 - John Doe
      │   └── TEAM002 - Jane Smith
      └── Site Officer 2 (so2@tm.com)
          ├── TEAM003 - Mike Johnson
          └── TEAM004 - Sarah Williams
```

---

## ✨ Next Steps

1. ✅ Run `supabase_setup.sql` in Supabase SQL Editor
2. ✅ Create all users in Supabase Authentication
3. ✅ Create `task-images` storage bucket
4. ✅ Update `lib/config/supabase_config.dart` with your credentials
5. ✅ Run `flutter pub get`
6. ✅ Run `flutter run`
7. ✅ Test all login credentials
8. ✅ Test all features!

---

## 📝 Default Password

**All users:** `Test@123`

⚠️ **Security Warning:** Change these passwords in production!

---

**Happy Testing! 🎉**
