@echo off
REM NagAgent Backend Deployment Script for Windows
REM Run this to deploy the backend to production

echo ========================================
echo 🚀 NagAgent Backend Deployment
echo ========================================

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python is not installed. Please install Python first.
    echo    Download from: https://www.python.org/downloads/
    echo    Or install from Microsoft Store: search "Python 3.11"
    pause
    exit /b 1
)

REM Check if .env file exists
if not exist ".env" (
    echo ❌ .env file not found. Creating from template...
    copy .env.example .env
    echo ⚠️  Please add your OpenAI API key to .env file
    pause
    exit /b 1
)

echo ✅ Configuration verified
echo.

REM Install dependencies
echo 📦 Installing dependencies...
pip install -r requirements.txt
echo.

REM Initialize database
echo 🗄️ Setting up database...
python -c "from app.database import engine, Base; Base.metadata.create_all(bind=engine); print('Database initialized!')" 2>nul || echo Database already initialized
echo.

REM Start the server
echo ========================================
echo 🎯 Starting NagAgent Backend...
echo ========================================
echo API URL: http://localhost:8000
echo API Docs: http://localhost:8000/docs
echo ========================================
echo.
echo Press Ctrl+C to stop the server
echo.

uvicorn app.main:app --reload --host 0.0.0.0 --port 8000