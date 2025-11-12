# TM Contractor Tracker - Quick Reference

## Quick Start Commands

### Setup
```bash
# Install dependencies
flutter pub get

# Check everything is ready
flutter doctor -v

# Run on connected device/emulator
flutter run

# Run in release mode
flutter run --release
```

### Build
```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS (macOS only)
flutter build ios --release
```

### Clean & Reset
```bash
flutter clean
flutter pub get
```

---

## Default Test Credentials

### Contractor Login
- **Team ID**: TEAM001
- **Leader Name**: John Doe

### Admin Logins

**Site Officer (SO)**
- Email: so@tm.com
- Password: Test@123

**Executive**
- Email: executive@tm.com
- Password: Test@123

**GM/AGM**
- Email: gm@tm.com
- Password: Test@123

---

## Key Features by Role

### Contractor
✅ Login with Team ID + Leader Name  
✅ Daily check-in with GPS  
✅ View assigned tasks  
✅ Update task progress  
✅ Upload photos  
✅ Add comments  

### Site Officer (SO)
✅ View managed teams  
✅ Monitor attendance  
✅ Check task progress  
✅ View performance stats  
✅ Access team details  

### Executive
✅ Manage Site Officers  
✅ View all teams under SOs  
✅ Access analytics  
✅ Generate reports  
✅ Export to Excel  
✅ View graphs (daily/weekly/monthly/annually)  

### GM/AGM
✅ View all staff  
✅ Complete system overview  
✅ Advanced reporting  
✅ Excel export  
✅ Full data access  

---

## File Structure

```
tm_contractor_tracker/
├── lib/
│   ├── main.dart                      # App entry
│   ├── config/
│   │   └── supabase_config.dart       # Supabase settings
│   ├── models/                        # Data models
│   ├── providers/                     # State management
│   ├── screens/                       # All screens
│   │   ├── contractor/                # Contractor screens
│   │   └── admin/                     # Admin screens
│   └── utils/                         # Utilities
├── android/                           # Android config
├── ios/                               # iOS config
├── pubspec.yaml                       # Dependencies
├── README.md                          # Overview
├── SETUP_GUIDE.md                     # Detailed setup
└── DATABASE_SCHEMA.md                 # Database docs
```

---

## Configuration Checklist

### Before Running
- [ ] Update `lib/config/supabase_config.dart` with your Supabase URL and key
- [ ] Add Google Maps API key to AndroidManifest.xml
- [ ] Add Google Maps API key to iOS AppDelegate
- [ ] Run `flutter pub get`
- [ ] Run database schema in Supabase SQL Editor
- [ ] Create storage bucket: `task-images`
- [ ] Create test users in Supabase Auth

### Database Setup
- [ ] Create Supabase project
- [ ] Run SQL from DATABASE_SCHEMA.md
- [ ] Create storage bucket: task-images
- [ ] Set storage policies
- [ ] Create test users
- [ ] Insert sample data

### API Keys Needed
- [ ] Supabase Project URL
- [ ] Supabase Anon Key
- [ ] Google Maps API Key (Android)
- [ ] Google Maps API Key (iOS)

---

## Common Commands

### Development
```bash
# Hot reload while developing
r (in terminal after flutter run)

# Hot restart
R (in terminal after flutter run)

# View logs
flutter logs

# Run specific device
flutter run -d <device-id>

# List devices
flutter devices
```

### Debugging
```bash
# Run with verbose logging
flutter run -v

# Run in debug mode
flutter run --debug

# Analyze code
flutter analyze

# Format code
flutter format lib/
```

---

## Troubleshooting Quick Fixes

### Problem: App won't connect to Supabase
```bash
# Check config file
cat lib/config/supabase_config.dart
# Verify URL and key are correct
```

### Problem: Build fails
```bash
flutter clean
flutter pub get
flutter run
```

### Problem: iOS pods issue
```bash
cd ios
pod install
pod update
cd ..
flutter run
```

### Problem: Location not working
- Check permissions in AndroidManifest.xml and Info.plist
- Ensure location services enabled on device
- Grant location permission when prompted

### Problem: Maps not showing
- Verify Google Maps API key
- Check API is enabled in Google Cloud Console
- Ensure billing is enabled on Google Cloud

---

## Database Quick Reference

### Tables
- **users** - All users (contractors + admins)
- **contractor_teams** - Team information
- **attendance** - Check-in records
- **tasks** - Assigned tasks
- **task_updates** - Progress updates

### Roles
- `contractor` - Team members
- `so` - Site Officers
- `executive` - Executive level
- `gmAgm` - General Manager/Assistant GM

---

## Support & Resources

📖 **Documentation**
- README.md - Project overview
- SETUP_GUIDE.md - Detailed setup
- DATABASE_SCHEMA.md - Database structure

🔗 **Links**
- Flutter: https://flutter.dev
- Supabase: https://supabase.com
- Google Maps: https://developers.google.com/maps

📧 **Contact**
- Email: support@tm-contractor-tracker.com
- GitHub Issues: [Create an issue]

---

## Version Info

**Current Version**: 1.0.0  
**Last Updated**: 2024  
**Minimum Flutter**: 3.0  
**Minimum Android**: API 21 (Android 5.0)  
**Minimum iOS**: 12.0  

---

## Tips

💡 **Performance**
- Use `flutter run --release` for testing real performance
- Profile mode: `flutter run --profile`

💡 **Security**
- Never commit supabase_config.dart with real credentials
- Use environment variables for production
- Enable RLS (Row Level Security) in Supabase

💡 **Best Practices**
- Test on both Android and iOS
- Test with real GPS locations
- Verify permissions on physical devices
- Test Excel export feature

---

**Made with ❤️ for TM Contractor Management**
