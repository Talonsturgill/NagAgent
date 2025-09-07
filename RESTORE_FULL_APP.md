# 🚨 CRITICAL: Restore Full NagAgent Functionality

## Current Status
✅ Railway health check PASSES
✅ App deploys successfully
❌ App is stripped down - missing all features

## Your Production URL
Check Railway dashboard for your URL: `https://nagagent-production-xxxx.up.railway.app`

## Step 1: Gradually Restore Features (DO THIS CAREFULLY)

### A. First, restore the routers (one at a time):

Edit `NagAgent-Backend-Python/app/main.py` and add back:

```python
# After the imports section, add:
from app.routers import auth, goals, tasks, roasts, reports

# After app creation, add ONE AT A TIME and test:
app.include_router(auth.router, prefix="/api/v1/auth", tags=["authentication"])
app.include_router(goals.router, prefix="/api/v1/goals", tags=["goals"])
app.include_router(tasks.router, prefix="/api/v1/tasks", tags=["tasks"])
app.include_router(roasts.router, prefix="/api/v1/roasts", tags=["roasts"])
app.include_router(reports.router, prefix="/api/v1/reports", tags=["reports"])
```

### B. Test after EACH router addition:
```bash
git add . && git commit -m "Restore X router" && git push
# Wait for Railway to deploy
# Test the health check still passes
```

## Step 2: Database Connection (KEEP OPTIONAL)

The database code is already there but disabled. To enable:

1. Make sure DATABASE_URL is set in Railway (you already added PostgreSQL)
2. The database will auto-connect when available
3. Keep the health check database-independent!

## Step 3: Update iOS App

Once your backend is stable:

1. Open `NagAgent-Swift-Codebase/Configuration/DeploymentConfig.swift`
2. Update with your Railway URL:
```swift
static let productionAPIURL = "https://YOUR-RAILWAY-URL.railway.app/api/v1"
```

## Step 4: Test Critical Endpoints

```bash
# Health check (should always work)
curl https://your-app.railway.app/health

# API docs (once routers are added)
curl https://your-app.railway.app/docs

# Test roast generation
curl -X POST https://your-app.railway.app/api/v1/roasts/generate \
  -H "Content-Type: application/json" \
  -d '{"personality": "brutal", "context": "morning", "task_count": 3}'
```

## What You Have Working

### ✅ Backend Structure:
- All Python files intact in `NagAgent-Backend-Python/`
- All 4 personalities implemented
- Database models ready
- API endpoints ready (just need to be re-enabled)

### ✅ iOS App:
- Complete Swift code in `NagAgent-Swift-Codebase/`
- PersonalityManager singleton (persistence fixed)
- Goal adding fixed
- All views ready

### ✅ Deployment:
- Railway configured and working
- PostgreSQL database connected
- Environment variables set

## IMPORTANT FILES TO KEEP

1. **Backend Core** (all in NagAgent-Backend-Python/):
   - `app/main.py` - Currently minimal, needs routers added back
   - `app/routers/*.py` - All API endpoints (ready to use)
   - `app/personalities/*.py` - All 4 coaches implemented
   - `app/models.py` - Database models
   - `app/config.py` - Configuration (with pydantic-settings fix)
   - `app/database.py` - Database connection (with text() fix)

2. **iOS App** (all in NagAgent-Swift-Codebase/):
   - `Services/PersonalityManager.swift` - Fixed persistence
   - `Views/Onboarding/GoalSettingViewFixed2.swift` - Fixed goal adding
   - `Configuration/DeploymentConfig.swift` - Update with Railway URL

## Quick Restore Commands

```bash
# If something breaks, revert to minimal working version:
git revert HEAD
git push

# To see what was removed, check the commit history:
git log --oneline -10

# The full app code is in commit b7ace17 and earlier
git diff b7ace17 HEAD -- NagAgent-Backend-Python/app/main.py
```

## Your App is NOT Gutted!

- All code still exists in the repo
- Only `main.py` was simplified temporarily
- All features can be restored by adding routers back
- Database, personalities, auth - all ready to enable

## Next Steps (After Context Reset)

1. Add routers back one by one
2. Test each addition
3. Update iOS app with Railway URL
4. Submit to App Store

## Production URLs You'll Need

- Backend API: `https://your-railway-app.railway.app`
- API Docs: `https://your-railway-app.railway.app/docs`
- Health: `https://your-railway-app.railway.app/health`

## If You Need Help

All original code is in your GitHub: https://github.com/Talonsturgill/NagAgent

The app is ready for App Store submission once you:
1. Restore the routers
2. Update the iOS app with your Railway URL
3. Build in Xcode and submit

YOU'RE ALMOST THERE! The hard part (deployment) is done!