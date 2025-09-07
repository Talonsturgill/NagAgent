#!/usr/bin/env python3
"""
Simple test script to validate NagAgent MVP functionality
"""

import sys
import os
sys.path.append(os.path.dirname(__file__))

from app.services.personality_service import PersonalityService
from app.services.twilio_service import TwilioService
from app.services.openai_service import OpenAIService

def test_personalities():
    """Test personality system"""
    print("🧪 Testing Personality System...")
    
    ps = PersonalityService()
    
    # Test all personalities
    for personality in ['sergeant', 'sassy', 'passive', 'brutal']:
        print(f"\n--- Testing {personality.title()} ---")
        
        # Test morning nag
        tasks = ["Go to gym", "Finish project", "Read 20 pages"]
        morning_nag = ps.get_morning_nag(personality, tasks)
        print(f"Morning Nag: {morning_nag[:100]}...")
        
        # Test excuse response
        excuse = "I'm too tired"
        excuse_response = ps.get_excuse_response(personality, excuse, "go to gym")
        print(f"Excuse Response: {excuse_response[:100]}...")
        
        # Test completion response
        completion_response = ps.get_completion_response(personality, 0.8)
        print(f"Completion Response: {completion_response[:100]}...")
        
        # Test daily report
        stats = {'completed': 3, 'total': 5, 'excuses': 2, 'streak': 1}
        daily_report = ps.get_daily_report(personality, stats)
        print(f"Daily Report: {daily_report[:100]}...")
    
    print("\n✅ Personality system tests completed!")

def test_services():
    """Test service integrations"""
    print("\n🧪 Testing Services...")
    
    # Test Twilio service (mock mode)
    twilio = TwilioService()
    result = twilio.send_whatsapp("+1234567890", "Test message")
    print(f"Twilio WhatsApp (mock): {result}")
    
    # Test OpenAI service (will fail without API key, but should handle gracefully)
    openai_service = OpenAIService()
    try:
        category = openai_service.categorize_excuse("I'm too tired to go to the gym")
        print(f"OpenAI Excuse Category: {category}")
    except Exception as e:
        print(f"OpenAI Error (expected without API key): {str(e)[:50]}...")
    
    print("✅ Service tests completed!")

def test_api_startup():
    """Test API can start up"""
    print("\n🧪 Testing API Startup...")
    
    try:
        from app.main import app
        print("✅ FastAPI app imported successfully!")
        
        # Test endpoint availability
        print("API Title:", app.title)
        print("API Version:", app.version)
        
    except Exception as e:
        print(f"❌ API startup error: {str(e)}")
    
    print("✅ API startup test completed!")

def test_database_models():
    """Test database models can be imported"""
    print("\n🧪 Testing Database Models...")
    
    try:
        from app.models import User, Goal, DailyTask, Excuse, Roast
        from app.database import Base
        
        print("✅ All models imported successfully!")
        print(f"Models available: {[cls.__name__ for cls in Base.__subclasses__()]}")
        
    except Exception as e:
        print(f"❌ Database model error: {str(e)}")
    
    print("✅ Database model test completed!")

def main():
    """Run all tests"""
    print("🚀 NagAgent MVP Test Suite")
    print("=" * 50)
    
    test_database_models()
    test_personalities()
    test_services()
    test_api_startup()
    
    print("\n" + "=" * 50)
    print("🎉 All tests completed!")
    print("\nNext steps:")
    print("1. Set up .env file with your API keys")
    print("2. Start PostgreSQL database")
    print("3. Run: uvicorn app.main:app --reload")
    print("4. Set up Twilio webhook")
    print("5. Test with WhatsApp messages")
    print("\n💀 Time to stop procrastinating and deploy this thing!")

if __name__ == "__main__":
    main()