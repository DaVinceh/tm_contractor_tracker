# Vercel Deployment Guide for TM Contractor Tracker

## ✅ Setup Complete!

Your project is now ready to deploy to Vercel. Here's what has been configured:

### 📁 Files Created:
- `public/index.html` - Professional landing page with download button
- `public/privacy-policy.html` - Privacy policy page
- `public/downloads/app-release.apk` - Your Android APK (24.5 MB)
- `vercel.json` - Vercel configuration file

## 🚀 Deployment Steps

### Step 1: Install Vercel CLI

Open PowerShell and run:
```powershell
npm install -g vercel
```

### Step 2: Login to Vercel

```powershell
vercel login
```

This will open your browser. Sign up or log in with:
- GitHub
- GitLab
- Bitbucket
- Email

### Step 3: Deploy Your Site

Navigate to your project folder and deploy:
```powershell
cd c:\tm_contractor_tracker
vercel
```

Follow the prompts:
- **Set up and deploy?** → Yes
- **Which scope?** → Select your account
- **Link to existing project?** → No
- **Project name?** → tm-contractor-tracker (or your choice)
- **In which directory is your code located?** → ./ (press Enter)
- **Override settings?** → No

### Step 4: Deploy to Production

After the preview deployment succeeds:
```powershell
vercel --prod
```

## 🔗 Your Live URLs

After deployment, you'll get:
- **Production URL:** `https://tm-contractor-tracker.vercel.app`
- **Custom Domain (optional):** You can add your own domain in Vercel dashboard

## 📱 Accessing Your App

Share this URL with your users:
```
https://your-project.vercel.app
```

They can:
1. Visit the site on their Android device
2. Click the "Download APK" button
3. Install the app following the instructions

## 🔧 Configuration Details

### vercel.json Settings:
- **Static hosting** configured for the `public` folder
- **APK downloads** configured with proper headers
- **Routes** set up for index.html and privacy policy

### Features:
- ✅ Responsive landing page
- ✅ Download button for APK
- ✅ Feature showcase
- ✅ System requirements
- ✅ Installation instructions
- ✅ Privacy policy page
- ✅ Professional design

## 🎨 Customization

### Update the Logo:
Replace the placeholder in `public/index.html` line 118:
```html
<img src="https://via.placeholder.com/150?text=conTRACKtor" alt="TM Contractor Tracker Logo">
```

Replace with:
```html
<img src="/assets/logo.png" alt="TM Contractor Tracker Logo">
```

Then add your actual logo to `public/assets/logo.png`

### Update Contact Information:
Edit `public/privacy-policy.html` to add your:
- Email address
- Phone number
- Company details

## 🔄 Future Updates

When you build a new APK:

1. Build the new version:
```powershell
flutter build apk --release
```

2. Copy to public folder:
```powershell
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" -Destination "public\downloads\app-release.apk" -Force
```

3. Update version in `index.html` (line 146)

4. Redeploy:
```powershell
vercel --prod
```

## 🌐 Custom Domain (Optional)

To use your own domain:

1. Go to https://vercel.com/dashboard
2. Select your project
3. Go to Settings → Domains
4. Add your domain (e.g., `contractor.yourdomain.com`)
5. Update DNS records as instructed by Vercel

## 📊 Monitoring

View analytics and logs:
- Visit https://vercel.com/dashboard
- Select your project
- View deployments, analytics, and logs

## 🆘 Troubleshooting

### APK Not Downloading:
- Clear browser cache
- Check file exists: `public/downloads/app-release.apk`
- Verify vercel.json configuration

### Page Not Loading:
- Check deployment status in Vercel dashboard
- Verify all files are in the `public` folder
- Check browser console for errors

### Need Help?
- Vercel Docs: https://vercel.com/docs
- Vercel Support: https://vercel.com/support

## ✨ Next Steps

1. Install Vercel CLI
2. Run `vercel login`
3. Run `vercel` from project directory
4. Run `vercel --prod` for production
5. Share your URL with users!

---

**Ready to deploy!** Run the commands above to get your app online. 🚀
