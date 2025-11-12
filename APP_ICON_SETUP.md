## 🎨 App Icon Update - Quick Guide

### What I've Done:

1. ✅ Added `flutter_launcher_icons` package to `pubspec.yaml`
2. ✅ Configured icon settings in `pubspec.yaml`
3. ✅ Set up assets directory
4. ✅ Ran `flutter pub get` to install the package

### What You Need to Do:

#### Step 1: Save the Logo Image 📥
Since I cannot directly access the image file you uploaded, please:

1. **Save your contractor tracker logo image as:**
   ```
   c:\tm_contractor_tracker\assets\icons\app_icon.png
   ```

2. **Requirements:**
   - Format: PNG
   - Size: At least 512x512 pixels (1024x1024 is better)
   - The image you provided (map with red location pin and "CONTRACTOR TRACKER" text)

#### Step 2: Generate Icons 🔧
After saving the image, open PowerShell and run:

```powershell
cd c:\tm_contractor_tracker
flutter pub run flutter_launcher_icons
```

This command will:
- Generate all Android icon sizes (mipmap-hdpi, mdpi, xhdpi, xxhdpi, xxxhdpi)
- Create adaptive icons with white background
- Update AndroidManifest.xml automatically

#### Step 3: Rebuild APK 📦
```powershell
flutter build apk --release
```

#### Step 4: Install & Test 📱
Install the new APK on your phone and you'll see the contractor tracker logo!

---

### 🛠️ Configuration Details

**pubspec.yaml settings:**
```yaml
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icons/app_icon.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icons/app_icon.png"
```

**What this does:**
- `android: true` - Generate Android icons only
- `image_path` - Path to your logo
- `adaptive_icon_background: "#FFFFFF"` - White background for Android 8.0+ adaptive icons
- `adaptive_icon_foreground` - Your logo as the foreground

---

### 🔍 Troubleshooting

**"Image not found" error:**
- Verify file exists at: `c:\tm_contractor_tracker\assets\icons\app_icon.png`
- Check it's a valid PNG file
- Try opening it in an image viewer

**Icons not updating:**
- Delete the old APK from your phone first
- Clear app data before reinstalling
- Make sure you ran `flutter pub run flutter_launcher_icons` successfully

**Blurry icon:**
- Use a higher resolution image (1024x1024 recommended)
- Make sure the image isn't compressed too much
- PNG format works best

---

### 📁 File Structure After Setup

```
tm_contractor_tracker/
├── assets/
│   └── icons/
│       └── app_icon.png          ← Your logo here!
├── android/
│   └── app/
│       └── src/
│           └── main/
│               └── res/
│                   ├── mipmap-hdpi/
│                   │   └── ic_launcher.png     (generated)
│                   ├── mipmap-mdpi/
│                   │   └── ic_launcher.png     (generated)
│                   ├── mipmap-xhdpi/
│                   │   └── ic_launcher.png     (generated)
│                   ├── mipmap-xxhdpi/
│                   │   └── ic_launcher.png     (generated)
│                   └── mipmap-xxxhdpi/
│                       └── ic_launcher.png     (generated)
```

---

### ✅ Quick Checklist

- [ ] Save logo as `assets/icons/app_icon.png`
- [ ] Run `flutter pub run flutter_launcher_icons`
- [ ] Wait for "Successfully generated launcher icons"
- [ ] Run `flutter build apk --release`
- [ ] Install new APK on phone
- [ ] Check app icon on home screen

---

### 🎯 Alternative Method (Manual)

If the automated tool doesn't work, you can manually:

1. Resize your logo to these sizes:
   - 48x48 (mdpi)
   - 72x72 (hdpi)
   - 96x96 (xhdpi)
   - 144x144 (xxhdpi)
   - 192x192 (xxxhdpi)

2. Replace files in:
   - `android\app\src\main\res\mipmap-mdpi\ic_launcher.png`
   - `android\app\src\main\res\mipmap-hdpi\ic_launcher.png`
   - `android\app\src\main\res\mipmap-xhdpi\ic_launcher.png`
   - `android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png`
   - `android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png`

3. Rebuild APK

---

**Ready to go! Just save the image and run the commands above! 🚀**
