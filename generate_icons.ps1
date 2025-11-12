# App Icon Generation Script
# Run this after placing your logo at assets/icons/app_icon.png

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   TM Contractor Tracker - Icon Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if image exists
$imagePath = "assets\icons\app_icon.png"
if (Test-Path $imagePath) {
    Write-Host "Logo image found!" -ForegroundColor Green
    Write-Host "  Location: $imagePath" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "Logo image NOT found!" -ForegroundColor Red
    Write-Host "  Expected location: $imagePath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please save your contractor tracker logo as:" -ForegroundColor Yellow
    Write-Host "  c:\tm_contractor_tracker\assets\icons\app_icon.png" -ForegroundColor White
    Write-Host ""
    Write-Host "Then run this script again." -ForegroundColor Yellow
    Write-Host ""
    pause
    exit
}

# Generate icons
Write-Host "Generating app icons..." -ForegroundColor Cyan
Write-Host ""
flutter pub run flutter_launcher_icons

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "   Icons Generated Successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Build new APK: flutter build apk --release" -ForegroundColor White
    Write-Host "2. Install on your phone" -ForegroundColor White
    Write-Host "3. Check the new app icon!" -ForegroundColor White
    Write-Host ""
    
    # Ask if user wants to build APK now
    $build = Read-Host "Would you like to build the APK now? (y/n)"
    if ($build -eq "y" -or $build -eq "Y") {
        Write-Host ""
        Write-Host "Building release APK..." -ForegroundColor Cyan
        flutter build apk --release
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "APK built successfully!" -ForegroundColor Green
            Write-Host "  Location: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Gray
        }
    }
} else {
    Write-Host ""
    Write-Host "Icon generation failed!" -ForegroundColor Red
    Write-Host "Please check the error messages above." -ForegroundColor Yellow
}

Write-Host ""
pause
