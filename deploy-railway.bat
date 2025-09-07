@echo off
echo ========================================
echo 🚂 NagAgent Railway Deployment Script
echo ========================================
echo.

cd NagAgent-Backend-Python

echo 📝 Step 1: Login to Railway
echo Browser will open - please login
railway login

echo.
echo ✅ Step 2: Initialize Railway Project
railway init

echo.
echo 📦 Step 3: Add PostgreSQL Database
railway add

echo.
echo 🔐 Step 4: Set Environment Variables
railway variables set OPENAI_API_KEY="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"
railway variables set SECRET_KEY="nagagent-secret-key-2024-production"
railway variables set DEBUG="False"

echo.
echo 🚀 Step 5: Deploy to Railway
railway up

echo.
echo ========================================
echo ✅ Deployment Complete!
echo ========================================
echo.
echo Your app URL will be shown above.
echo.
echo Next steps:
echo 1. Copy your Railway URL
echo 2. Update iOS app with the URL
echo 3. Test the endpoints
echo.
railway open
pause