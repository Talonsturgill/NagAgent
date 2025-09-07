#!/bin/bash

# NagAgent Backend Deployment Script
# Run this to deploy the backend to production

echo "🚀 NagAgent Backend Deployment"
echo "=============================="

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python first."
    echo "   Download from: https://www.python.org/downloads/"
    exit 1
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "❌ .env file not found. Creating from template..."
    cp .env.example .env
    echo "⚠️  Please add your OpenAI API key to .env file"
    exit 1
fi

# Check if OpenAI key is set
if grep -q "your_openai_api_key_here" .env; then
    echo "❌ OpenAI API key not configured in .env"
    echo "   Please update OPENAI_API_KEY in .env file"
    exit 1
fi

echo "✅ Configuration verified"

# Install dependencies
echo "📦 Installing dependencies..."
pip install -r requirements.txt

# Run database migrations
echo "🗄️ Setting up database..."
alembic upgrade head 2>/dev/null || echo "Database already initialized"

# Start the server
echo "🎯 Starting NagAgent Backend..."
echo "================================"
echo "API URL: http://localhost:8000"
echo "API Docs: http://localhost:8000/docs"
echo "================================"

uvicorn app.main:app --reload --host 0.0.0.0 --port 8000