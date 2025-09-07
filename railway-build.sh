#!/bin/bash
# Railway build script
set -e

echo "🔧 Railway Build Starting..."

# Navigate to backend directory
cd NagAgent-Backend-Python

# Install Python dependencies
echo "📦 Installing Python packages..."
python -m pip install --upgrade pip
python -m pip install -r requirements.txt

echo "✅ Build complete!"