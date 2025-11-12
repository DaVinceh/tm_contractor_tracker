# Assets Directory

This directory contains image and icon assets for the TM Contractor Tracker app.

## Directory Structure

```
assets/
├── images/
│   ├── logo.png           (Add your company logo here)
│   ├── splash_logo.png    (Add splash screen logo here)
│   └── placeholder.png    (Placeholder images)
└── icons/
    ├── contractor.png     (Contractor role icon)
    ├── admin.png          (Admin role icon)
    └── task.png           (Task icon)
```

## Image Requirements

### Logo
- **Size**: 512x512 px (minimum)
- **Format**: PNG with transparency
- **Usage**: App branding, splash screen

### Icons
- **Size**: 256x256 px
- **Format**: PNG
- **Usage**: UI elements, role indicators

### Task Images (Uploaded by Users)
- **Max Size**: 1920x1080 px
- **Format**: JPEG
- **Storage**: Supabase Storage bucket `task-images`

## Adding Custom Assets

1. Place your images in the appropriate directory
2. Update `pubspec.yaml` if needed:

```yaml
flutter:
  assets:
    - assets/images/
    - assets/icons/
```

3. Reference in code:

```dart
Image.asset('assets/images/logo.png')
```

## App Icon

To change the app icon:

### Android
Replace files in: `android/app/src/main/res/mipmap-*/ic_launcher.png`

### iOS
Replace files in: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

Or use `flutter_launcher_icons` package for automated icon generation.

## Splash Screen

Configure splash screen in:
- Android: `android/app/src/main/res/drawable/launch_background.xml`
- iOS: `ios/Runner/Assets.xcassets/LaunchImage.imageset/`

---

**Note**: Asset files are not included in the repository by default. Add your own branded assets before deployment.
