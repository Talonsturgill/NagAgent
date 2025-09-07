#!/usr/bin/env python3
"""
Simple test script to verify the /health endpoint works immediately
"""
import requests
import time
import sys
import subprocess
import os
from threading import Thread

def test_health_endpoint():
    """Test the /health endpoint"""
    print("🧪 Testing health endpoint...")
    
    try:
        # Test both root and health endpoints
        endpoints = ["http://localhost:8000/", "http://localhost:8000/health"]
        
        for endpoint in endpoints:
            print(f"📡 Testing {endpoint}")
            start_time = time.time()
            response = requests.get(endpoint, timeout=5)
            end_time = time.time()
            
            print(f"✅ Status Code: {response.status_code}")
            print(f"⏱️ Response Time: {(end_time - start_time):.3f} seconds")
            print(f"📄 Response: {response.json()}")
            
            if response.status_code == 200:
                print(f"✅ {endpoint} is working!")
            else:
                print(f"❌ {endpoint} returned status {response.status_code}")
            print("-" * 50)
            
    except Exception as e:
        print(f"❌ Health endpoint test failed: {e}")
        return False
    
    return True

if __name__ == "__main__":
    print("🔥 NagAgent Health Check Test")
    print("=" * 50)
    
    # Test the health endpoint
    success = test_health_endpoint()
    
    if success:
        print("✅ All health checks passed!")
        sys.exit(0)
    else:
        print("❌ Health checks failed!")
        sys.exit(1)