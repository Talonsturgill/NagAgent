# 🚂 Deploy NagAgent Backend to Railway

## Quick Deploy Steps (5 minutes)

### 1. Install Railway CLI
```bash
npm install -g @railway/cli
```

### 2. Login to Railway
```bash
railway login
```
This will open your browser to authenticate.

### 3. Initialize Project
```bash
cd C:\Users\Talon\Desktop\Claude-projects\NagAgent-iOS\NagAgent-Backend-Python
railway init
```
- Choose "Create new project"
- Name it: `nagagent-backend`

### 4. Set Environment Variables
```bash
railway variables set OPENAI_API_KEY="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"
railway variables set SECRET_KEY="your-super-secret-key-change-this-12345"
railway variables set DATABASE_URL="${{RAILWAY_DATABASE_URL}}"
```

### 5. Add PostgreSQL Database
```bash
railway add
```
Choose "PostgreSQL" from the list.

### 6. Deploy
```bash
railway up
```

### 7. Get Your Production URL
```bash
railway open
```
Your URL will be something like: `https://nagagent-backend-production.up.railway.app`

## 🎯 Your Production Endpoints

Once deployed, your API will be available at:
- **Base URL**: `https://your-app.up.railway.app`
- **API Docs**: `https://your-app.up.railway.app/docs`
- **Health Check**: `https://your-app.up.railway.app/api/v1/health`

## Alternative: Deploy to Render (Free Tier)

### 1. Push to GitHub
Your code is already on GitHub at: https://github.com/Talonsturgill/NagAgent

### 2. Create Render Account
Go to: https://render.com and sign up (free)

### 3. New Web Service
- Click "New +" → "Web Service"
- Connect your GitHub account
- Select `Talonsturgill/NagAgent` repository
- Root Directory: `NagAgent-Backend-Python`

### 4. Configure Service
- **Name**: `nagagent-api`
- **Environment**: `Python 3`
- **Build Command**: `pip install -r requirements.txt`
- **Start Command**: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`

### 5. Add Environment Variables
Click "Advanced" and add:
- `OPENAI_API_KEY` = Your OpenAI key
- `SECRET_KEY` = Generate a random string
- `DATABASE_URL` = Will be auto-added when you add PostgreSQL

### 6. Deploy
Click "Create Web Service" and wait for deployment (~5 minutes)

Your URL will be: `https://nagagent-api.onrender.com`

## ✅ Test Your Deployed Backend

```bash
# Test health endpoint
curl https://your-backend-url.railway.app/api/v1/health

# Test roast generation
curl -X POST https://your-backend-url.railway.app/api/v1/roasts/generate \
  -H "Content-Type: application/json" \
  -d '{
    "personality": "brutal",
    "context": "morning",
    "task_count": 3
  }'
```

## 📱 Next: Update iOS App

Once you have your production URL, update the iOS app:
1. Open `NagAgent-Swift-Codebase/Services/APIClient.swift`
2. Change the base URL to your production URL
3. Build and test!