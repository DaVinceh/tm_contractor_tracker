# TM Contractor Tracker

A comprehensive mobile application for tracking contractor teams, attendance, task progress, and performance. Built with Flutter and Supabase.

## Features

### For Contractors
- ✅ Simple login with Team ID and Leader Name
- ✅ Daily check-in with GPS location tracking
- ✅ View assigned tasks and progress
- ✅ Upload daily task updates with photos and comments
- ✅ Track task completion percentage

### For Site Officers (SO)
- ✅ Manage multiple contractor teams
- ✅ View team attendance records
- ✅ Monitor task progress and performance
- ✅ Access detailed team statistics
- ✅ View location data for check-ins

### For Executives
- ✅ Manage Site Officers
- ✅ View all contractor teams under supervision
- ✅ Comprehensive report summary with graphs
- ✅ Filter reports by daily, weekly, monthly, or annually
- ✅ Export reports to Excel

### For GM/AGM
- ✅ Full visibility of all staff (Executives and SOs)
- ✅ Complete system overview
- ✅ Access to all contractor data
- ✅ Advanced analytics and reporting
- ✅ Excel export functionality

## Screenshots

(Add screenshots here after running the app)

## Tech Stack

- **Frontend**: Flutter 3.0+
- **Backend**: Supabase (PostgreSQL)
- **State Management**: Provider
- **Maps**: Google Maps Flutter
- **Charts**: FL Chart
- **File Export**: Excel package

## Prerequisites

Before you begin, ensure you have:

1. Flutter SDK (3.0 or higher) installed
2. Android Studio / VS Code with Flutter extensions
3. A Supabase account (free tier available)
4. Google Maps API key (for Android and iOS)

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/tm_contractor_tracker.git
cd tm_contractor_tracker
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Set Up Supabase

1. Create a new project at [supabase.com](https://supabase.com)
2. Copy your project URL and anon key
3. Update `/lib/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String url = 'YOUR_SUPABASE_URL';
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

### 4. Set Up Database

Run the following SQL in your Supabase SQL Editor:

```sql
-- See DATABASE_SCHEMA.md for complete schema
```

### 5. Configure Google Maps (Optional but Recommended)

#### For Android:
Add your API key to `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

#### For iOS:
Add your API key to `ios/Runner/AppDelegate.swift`:

```swift
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
```

### 6. Configure Permissions

#### Android (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

#### iOS (`ios/Runner/Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access for check-in tracking</string>
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to upload task photos</string>
```

## Running the App

```bash
flutter run
```

## Building for Production

### Android APK
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Project Structure

```
lib/
├── config/
│   └── supabase_config.dart          # Supabase configuration
├── models/
│   ├── user_model.dart                # User data model
│   ├── contractor_team_model.dart     # Team data model
│   ├── attendance_model.dart          # Attendance data model
│   ├── task_model.dart                # Task data model
│   └── task_update_model.dart         # Task update data model
├── providers/
│   ├── auth_provider.dart             # Authentication state
│   ├── contractor_provider.dart       # Contractor functionality
│   └── admin_provider.dart            # Admin functionality
├── screens/
│   ├── splash_screen.dart             # App splash screen
│   ├── login_selection_screen.dart    # Login type selector
│   ├── contractor_login_screen.dart   # Contractor login
│   ├── admin_login_screen.dart        # Admin login
│   ├── contractor/
│   │   ├── contractor_dashboard.dart  # Contractor home
│   │   ├── check_in_screen.dart       # Check-in functionality
│   │   ├── task_list_screen.dart      # Task list view
│   │   └── task_detail_screen.dart    # Task details & updates
│   └── admin/
│       ├── so_dashboard.dart          # SO dashboard
│       ├── executive_dashboard.dart   # Executive dashboard
│       ├── gm_agm_dashboard.dart      # GM/AGM dashboard
│       ├── team_detail_screen.dart    # Team details
│       ├── so_teams_view_screen.dart  # View SO's teams
│       └── report_summary_screen.dart # Analytics & reports
├── utils/
│   ├── theme.dart                     # App theme
│   └── excel_export.dart              # Excel export utility
└── main.dart                          # App entry point
```

## Database Schema

See [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) for detailed database structure.

## User Roles & Hierarchy

```
GM/AGM (Top Level)
  ├── Executive
  │     └── Site Officer (SO)
  │           └── Contractor Teams
```

## Default Test Credentials

### Admin Users (Create these in Supabase Auth):

**GM/AGM:**
- Email: gm@tm.com
- Password: password123

**Executive:**
- Email: executive@tm.com
- Password: password123

**Site Officer:**
- Email: so@tm.com
- Password: password123

### Contractor:
- Team ID: TEAM001
- Leader Name: John Doe

(Create contractor teams in the database first)

## Features Roadmap

- [x] Basic authentication
- [x] Contractor check-in with GPS
- [x] Task management
- [x] Admin dashboards
- [x] Reports with charts
- [x] Excel export
- [ ] Push notifications
- [ ] Offline mode
- [ ] Multi-language support
- [ ] Dark mode
- [ ] Task assignment interface
- [ ] Real-time updates
- [ ] Photo gallery for tasks
- [ ] Advanced filtering

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, email support@tm-contractor-tracker.com or open an issue in the repository.

## Acknowledgments

- Flutter team for the amazing framework
- Supabase for the backend infrastructure
- All contributors and testers

---

**Made with ❤️ for TM Contractor Management**
