# 🔧 Railway Manual Configuration Fix

If automatic deployment is still failing, use these manual steps in Railway Dashboard:

## Option 1: Override Build Settings in Railway

1. **Go to your Railway project dashboard**
2. **Click on your service (nagagent)**
3. **Go to Settings → Build**
4. **Override these settings:**

### Build Command (copy exactly):
```bash
pip install --upgrade pip && pip install -r NagAgent-Backend-Python/requirements.txt
```

### Start Command (copy exactly):
```bash
cd NagAgent-Backend-Python && python -m uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

### Root Directory:
Leave empty (uses repository root)

### Watch Paths:
```
NagAgent-Backend-Python/**
Dockerfile
requirements.txt
```

## Option 2: Use Railway CLI to Force Settings

```bash
# Login to Railway
railway login

# Link to your project
railway link

# Set build command
railway variables set RAILWAY_BUILD_COMMAND="pip install -r NagAgent-Backend-Python/requirements.txt"

# Set start command  
railway variables set RAILWAY_START_COMMAND="cd NagAgent-Backend-Python && uvicorn app.main:app --host 0.0.0.0 --port \$PORT"

# Force redeploy
railway up
```

## Option 3: Delete and Recreate Service

1. **In Railway Dashboard:**
   - Delete the current service
   - Create new service
   - Select GitHub repo
   - Use Dockerfile (it should auto-detect)

2. **Add Environment Variables:**
```
OPENAI_API_KEY=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
SECRET_KEY=nagagent-secret-2024
```

3. **Add PostgreSQL:**
   - New → Database → PostgreSQL
   - Railway auto-sets DATABASE_URL

## Option 4: Use Render Instead (Free Alternative)

If Railway continues to fail:

1. **Go to https://render.com**
2. **New → Web Service**
3. **Connect GitHub: Talonsturgill/NagAgent**
4. **Settings:**
   - Name: `nagagent-api`
   - Root Directory: `NagAgent-Backend-Python`
   - Runtime: Python 3
   - Build: `pip install -r requirements.txt`
   - Start: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`

5. **Add same environment variables**

## What Should Happen

Once properly configured, you should see:
1. Build logs showing pip installing packages
2. "Build successful" message
3. Service starts with "Uvicorn running on http://0.0.0.0:8000"
4. Green status indicator
5. Your URL like: `https://nagagent-production.up.railway.app`

## Test Your Deployment

```bash
# Check health endpoint
curl https://your-app.up.railway.app/health

# Should return:
{"status":"healthy","version":"1.0.0"}
```

## If All Else Fails

The backend works locally, so you can:
1. Run locally for testing
2. Deploy to Heroku (very reliable)
3. Use Render.com (easier than Railway)
4. Contact Railway support with error logs