# 📱 iOS App Store Submission Guide

## Prerequisites Checklist
- [ ] Apple Developer Account ($99/year) - https://developer.apple.com
- [ ] Xcode 14+ installed
- [ ] Backend deployed and accessible
- [ ] Production API URL configured

## Step 1: Configure Xcode Project

### A. Open Project
```bash
cd C:\Users\Talon\Desktop\Claude-projects\NagAgent-iOS\NagAgent-Swift-Codebase
open NagAgent.xcodeproj
```
Or create new Xcode project and import the Swift files.

### B. Project Settings
1. **General Tab:**
   - Display Name: `NagAgent`
   - Bundle Identifier: `com.talonsturgill.NagAgent`
   - Version: `1.0.0`
   - Build: `1`

2. **Signing & Capabilities:**
   - Team: Select your Apple Developer team
   - Signing Certificate: Automatic manage signing ✓
   - Provisioning Profile: Automatic

3. **Info.plist Updates:**
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
</dict>

<key>NSCameraUsageDescription</key>
<string>NagAgent needs camera access to let you share your progress</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>NagAgent needs photo access to save and share your achievement cards</string>

<key>UIRequiresFullScreen</key>
<true/>

<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
</array>
```

## Step 2: Create App Icon

### Required Sizes (create from 1024x1024 master):
Create a 1024x1024 app icon with 🔥 flame emoji or custom design.

Save as `AppIcon.png` and use an online tool to generate all sizes:
- https://www.appicon.co
- https://makeappicon.com

### Icon Requirements:
- No transparency
- No rounded corners (iOS adds them)
- 1024x1024px for App Store
- Include all required sizes in Assets.xcassets

## Step 3: Generate Screenshots

### Required Screenshot Sizes:
1. **iPhone 6.7" (1290 × 2796)** - iPhone 14 Pro Max
2. **iPhone 6.5" (1242 × 2688)** - iPhone 11 Pro Max
3. **iPhone 5.5" (1242 × 2208)** - iPhone 8 Plus
4. **iPad 12.9" (2048 × 2732)** - iPad Pro

### Screenshot Content Ideas:
1. Welcome screen with app title
2. Personality selection (4 coaches)
3. Goal setting screen
4. Daily roast from Brutal Brandon
5. Progress tracking/report card

### Tools for Screenshots:
- Xcode Simulator (Command+S for screenshot)
- Figma/Sketch for mockups
- https://screenshots.pro for frames

## Step 4: App Store Connect Setup

### A. Create App
1. Go to https://appstoreconnect.apple.com
2. Click "My Apps" → "+"
3. Select "New App"

### B. App Information
```
Platform: iOS
Name: NagAgent
Primary Language: English (U.S.)
Bundle ID: com.talonsturgill.NagAgent
SKU: NAGAGENT001
```

### C. App Store Listing

**Subtitle** (30 chars):
"Get Roasted Into Productivity"

**Description**:
```
NagAgent: The AI accountability coach that bullies you into success!

Tired of gentle motivation that doesn't work? Meet your new accountability coaches who will roast you into achieving your goals with brutal honesty and zero sugar-coating.

CHOOSE YOUR COACH:
🔥 Sergeant Slacker - Military drill instructor who's perpetually disappointed in your life choices
😈 Sassy Susan - Your toxic bestie who secretly wants you to succeed (but will drag you first)
🤖 Passive-Aggressive Pat - Corporate middle manager energy with a side of subtle shade
👹 Brutal Brandon - Zero filter, maximum truth bombs, no survivors

FEATURES THAT ACTUALLY WORK:
• Set daily goals and get held accountable (harshly)
• Receive personality-specific roasts throughout the day
• Track your progress with brutal honesty reports
• Get graded on your productivity (spoiler: you're failing)
• Share your shameful results on social media
• Morning wake-up roasts that hit different
• Excuse detection system (your coach knows you're lying)

WHY NAGAGENT WORKS:
Traditional motivation apps coddle you. NagAgent doesn't. Our AI-powered coaches use advanced roasting technology to shame you into productivity. It's tough love without the love part.

WARNING: This app will hurt your feelings. It will call you out. It will not accept your excuses. But it will get you to actually do the things you said you'd do.

Perfect for:
• Chronic procrastinators
• People who need tough love
• Anyone tired of gentle motivation
• Goal-setters who never follow through
• People with thick skin and thin patience

Download NagAgent today and get bullied into the best version of yourself. Your future self will thank you (your current self will hate it).

Note: Contains harsh language and brutal honesty. Not for the easily offended.
```

**Keywords** (100 chars):
```
productivity,motivation,goals,accountability,roast,tough love,habit,tasks,brutal,coach,ai,funny
```

**Category**: Productivity
**Secondary**: Health & Fitness

**Age Rating**: 12+ (Infrequent/Mild Profanity or Crude Humor)

## Step 5: Build and Submit

### A. Archive Build
1. Select "Any iOS Device" as target
2. Product → Archive
3. Wait for build to complete
4. Window → Organizer opens automatically

### B. Upload to App Store Connect
1. Click "Distribute App"
2. Select "App Store Connect"
3. Select "Upload"
4. Follow prompts (use defaults)
5. Wait for processing (~30 minutes)

### C. Submit for Review
1. Go back to App Store Connect
2. Select your app
3. Add build to version
4. Fill in all required fields:
   - Screenshots (upload all)
   - App Preview (optional video)
   - Review notes (explain test credentials if needed)
   - Contact information

### D. Review Information
**Demo Account** (if needed):
```
Username: demo@nagagent.com
Password: TestAccount123
Note: Select "Brutal Brandon" for full experience
```

**Notes for Reviewer**:
```
NagAgent is an AI-powered accountability coach that uses humor and tough love to motivate users. The "roasts" are comedic in nature and designed to be motivational through humor. No actual bullying or harmful content is included.
```

## Step 6: Submit and Monitor

1. Click "Submit for Review"
2. Status changes to "Waiting for Review"
3. Review typically takes 24-48 hours
4. Check email for updates

## Common Rejection Reasons & Solutions

| Issue | Solution |
|-------|----------|
| Crashes on launch | Test on real device, check API connectivity |
| Inappropriate content | Emphasize humor/motivation in review notes |
| Missing functionality | Ensure all features work without login |
| Metadata issues | Review screenshots and description |

## Timeline
- Day 1: Deploy backend, configure Xcode
- Day 2: Create assets, submit to App Store
- Day 3-5: Apple review
- Day 5-7: Approved and live!

## 🎉 Launch Checklist
- [ ] Backend deployed and tested
- [ ] API URL updated in app
- [ ] App icon created (1024x1024)
- [ ] Screenshots for all devices
- [ ] App Store listing complete
- [ ] Build uploaded
- [ ] Submitted for review

## Support
- Apple Developer Forums: https://developer.apple.com/forums
- App Store Review Guidelines: https://developer.apple.com/app-store/review/guidelines
- Contact Apple: https://developer.apple.com/contact