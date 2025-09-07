#!/usr/bin/env python3
"""
Test script to verify the application starts and health check works
"""
import sys
import os
import subprocess
import time
import requests
from threading import Thread

def test_health_check():
    """Test if the health endpoint responds correctly"""
    try:
        # Test the health endpoint
        response = requests.get("http://localhost:8000/health", timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Health check successful!")
            print(f"   Status: {data.get('status')}")
            print(f"   Database: {data.get('database')}")
            print(f"   Port: {data.get('port')}")
            print(f"   Environment: {data.get('environment')}")
            return True
        else:
            print(f"❌ Health check failed with status {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Health check failed: {e}")
        return False

def test_root_endpoint():
    """Test if the root endpoint responds correctly"""
    try:
        response = requests.get("http://localhost:8000/", timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Root endpoint successful!")
            print(f"   App: {data.get('name')}")
            print(f"   Version: {data.get('version')}")
            return True
        else:
            print(f"❌ Root endpoint failed with status {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Root endpoint failed: {e}")
        return False

def main():
    """Main test function"""
    print("🚀 Testing NagAgent API locally...")
    
    # Change to the backend directory
    backend_dir = "NagAgent-Backend-Python"
    if os.path.exists(backend_dir):
        os.chdir(backend_dir)
        print(f"📁 Changed to directory: {os.getcwd()}")
    
    # Set environment variables for testing
    os.environ['PORT'] = '8000'
    os.environ['ENVIRONMENT'] = 'development'
    
    # Start the server
    print("🔥 Starting uvicorn server...")
    try:
        # Start server in background
        server_process = subprocess.Popen([
            sys.executable, "-m", "uvicorn", 
            "app.main:app", 
            "--host", "0.0.0.0", 
            "--port", "8000",
            "--reload"
        ], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        
        # Wait a moment for server to start
        print("⏳ Waiting for server to start...")
        time.sleep(5)
        
        # Test endpoints
        health_ok = test_health_check()
        root_ok = test_root_endpoint()
        
        if health_ok and root_ok:
            print("\n🎉 All tests passed! The application is ready for Railway deployment.")
        else:
            print("\n❌ Some tests failed. Check the output above.")
        
        # Stop the server
        server_process.terminate()
        server_process.wait()
        
    except Exception as e:
        print(f"❌ Failed to start server: {e}")
        return False
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)