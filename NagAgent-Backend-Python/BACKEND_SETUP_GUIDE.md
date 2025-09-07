# 🚀 NagAgent Backend Setup Guide

## ✅ Backend Verification Checklist

### 1️⃣ **Prerequisites**
- [ ] Python 3.9+ installed
- [ ] pip package manager
- [ ] OpenAI API key

### 2️⃣ **Setup Steps**

#### A. Install Python (if not installed)
```bash
# Windows - Download from python.org or:
winget install Python.Python.3.11

# Or from Microsoft Store:
# Search for "Python 3.11" and install
```

#### B. Install Dependencies
```bash
cd NagAgent-Backend-Python
pip install -r requirements.txt
```

#### C. Configure OpenAI API Key
1. Get your API key from: https://platform.openai.com/api-keys
2. Edit `.env` file and replace `your_openai_api_key_here` with your actual key:
```
OPENAI_API_KEY=sk-...your-actual-key-here...
```

#### D. Initialize Database
```bash
# The SQLite database will be created automatically on first run
# For production, use PostgreSQL
```

### 3️⃣ **Run the Backend**

```bash
# Start the FastAPI server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at:
- **API Base**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **OpenAPI Schema**: http://localhost:8000/openapi.json

### 4️⃣ **Test the Backend**

#### Quick Health Check:
```bash
curl http://localhost:8000/api/v1/health
```

#### Test Personality Roasts (requires OpenAI key):
```bash
# Get a roast from Brutal Brandon
curl -X POST http://localhost:8000/api/v1/roasts/generate \
  -H "Content-Type: application/json" \
  -d '{
    "personality": "brutal",
    "context": "morning",
    "task_count": 3
  }'
```

### 5️⃣ **Verify All Endpoints**

The backend provides these endpoints:

#### Authentication
- `POST /api/v1/auth/register` - User registration
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/refresh` - Refresh token

#### Goals & Tasks
- `GET /api/v1/goals` - Get user goals
- `POST /api/v1/goals` - Create goal
- `PUT /api/v1/goals/{id}` - Update goal
- `DELETE /api/v1/goals/{id}` - Delete goal

#### Roasts & Personalities
- `POST /api/v1/roasts/generate` - Generate AI roast
- `GET /api/v1/personalities` - List all personalities
- `GET /api/v1/personalities/{type}/roast` - Get specific personality roast

#### Reports
- `GET /api/v1/reports/daily` - Daily report
- `GET /api/v1/reports/weekly` - Weekly summary

### 6️⃣ **iOS App Connection**

Update iOS app's `APIClient.swift` with backend URL:
```swift
// For local development
let baseURL = "http://localhost:8000/api/v1"

// For production (after deployment)
let baseURL = "https://your-deployed-api.com/api/v1"
```

### 7️⃣ **Deployment Options**

#### Option A: Railway (Recommended)
```bash
# Install Railway CLI
npm install -g @railway/cli

# Deploy
railway login
railway init
railway up
```

#### Option B: Render
1. Connect GitHub repo
2. Set environment variables
3. Deploy automatically

#### Option C: Heroku
```bash
heroku create nagagent-api
heroku config:set OPENAI_API_KEY=your-key
git push heroku main
```

### 8️⃣ **Environment Variables for Production**

```env
# Required
OPENAI_API_KEY=sk-...
DATABASE_URL=postgresql://...
SECRET_KEY=generate-secure-random-string

# Optional
TWILIO_ACCOUNT_SID=...
TWILIO_AUTH_TOKEN=...
REDIS_URL=redis://...
```

### 9️⃣ **Common Issues & Solutions**

| Issue | Solution |
|-------|----------|
| "Module not found" | Run `pip install -r requirements.txt` |
| "OpenAI API error" | Check API key in `.env` file |
| "Database error" | Ensure DATABASE_URL is correct |
| "CORS error from iOS" | Add iOS simulator URL to BACKEND_CORS_ORIGINS |

### 🎯 **Ready for App Store!**

Once backend is running and tested:
1. ✅ Deploy to production (Railway/Render/Heroku)
2. ✅ Update iOS app with production API URL
3. ✅ Test end-to-end flow
4. ✅ Submit to App Store!

---

## 📞 Support

If you encounter issues:
1. Check the logs: `uvicorn` output
2. Verify `.env` file configuration
3. Test with API docs at `/docs`
4. Ensure all dependencies installed

**Backend is production-ready and doesn't require any code changes!**