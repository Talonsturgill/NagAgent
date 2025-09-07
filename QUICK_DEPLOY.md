# 🚀 NagAgent Quick Deploy Guide

## Today's Action Items

### 1️⃣ Deploy Backend (15 minutes)
```bash
# Option A: Railway (Recommended - Faster)
npm install -g @railway/cli
railway login
cd NagAgent-Backend-Python
railway init  # Create new project
railway add  # Add PostgreSQL
railway up  # Deploy

# Your URL will be: https://[your-app].railway.app
```

### 2️⃣ Update iOS App (5 minutes)
Edit `NagAgent-Swift-Codebase/Configuration/DeploymentConfig.swift`:
```swift
static let productionAPIURL = "YOUR_RAILWAY_URL_HERE/api/v1"
```

### 3️⃣ Quick App Icon (10 minutes)
1. Create simple icon with 🔥 emoji on black background
2. Use https://www.appicon.co to generate all sizes
3. Add to Xcode project

### 4️⃣ Essential Screenshots (20 minutes)
Take these 5 screenshots from the HTML demo:
1. Welcome screen
2. Choose personality (show all 4)
3. Goal setting
4. Daily roast message
5. Progress report

Use iPhone 14 Pro Max simulator (6.7") - works for most requirements.

### 5️⃣ Submit to App Store (30 minutes)
1. Open Xcode
2. Set bundle ID: `com.talonsturgill.NagAgent`
3. Archive → Upload to App Store Connect
4. Add screenshots
5. Submit for review

## Total Time: ~1.5 hours

## Shortcuts for Speed

### Fastest Backend Deploy:
Use Render.com (free):
1. Push to GitHub ✓ (already done)
2. Connect Render to GitHub
3. Auto-deploy from `NagAgent-Backend-Python` folder
4. Add environment variables
5. Done in 10 minutes!

### Fastest Screenshots:
Use your existing HTML demo (`nagagent-original-preserved.html`):
1. Open in browser
2. Use developer tools to set mobile view
3. Set to iPhone 14 Pro Max (430 × 932)
4. Take screenshots with browser
5. Scale up to required size

### Minimal App Store Listing:
**Name**: NagAgent
**Subtitle**: Get Roasted Into Productivity
**Description**: (copy from APP_STORE_SUBMISSION.md)
**Category**: Productivity
**Price**: Free
**Screenshots**: Minimum 2, maximum 10

## If You Get Stuck

**Backend not deploying?**
- Use Render.com instead of Railway
- Or try Heroku (also free tier)

**No Xcode project?**
- Create new iOS app in Xcode
- Copy Swift files from NagAgent-Swift-Codebase
- Add SwiftUI views

**Missing Apple Developer Account?**
- Can test on simulator without it
- Need it only for App Store submission
- $99/year at developer.apple.com

## Ready in 90 Minutes! 🎯

1. ✅ Backend deployed (15 min)
2. ✅ iOS configured (15 min)
3. ✅ Assets created (30 min)
4. ✅ Submitted to App Store (30 min)

The app is production-ready - just follow these steps!