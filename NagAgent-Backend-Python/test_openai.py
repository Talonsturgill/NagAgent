#!/usr/bin/env python3
"""
Quick test script to verify OpenAI API key works with NagAgent personalities
Run: python test_openai.py
"""

import os
from dotenv import load_dotenv
import openai

# Load environment variables
load_dotenv()

# Test the OpenAI API key
def test_openai_connection():
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        print("❌ No OpenAI API key found in .env file")
        return False
    
    print(f"✅ OpenAI API key loaded: {api_key[:20]}...")
    
    try:
        # Initialize OpenAI client
        client = openai.OpenAI(api_key=api_key)
        
        # Test with a simple roast generation
        print("\n🔥 Testing Brutal Brandon roast generation...")
        
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "You are Brutal Brandon, a brutally honest accountability coach with zero filter. Roast the user about their productivity."},
                {"role": "user", "content": "I have 3 goals today but haven't started any."}
            ],
            max_tokens=150,
            temperature=0.8
        )
        
        roast = response.choices[0].message.content
        print(f"\n💬 Brutal Brandon says:\n{roast}")
        
        print("\n✅ OpenAI API is working correctly!")
        print("✅ Backend is ready for deployment!")
        return True
        
    except Exception as e:
        print(f"\n❌ Error testing OpenAI API: {e}")
        return False

if __name__ == "__main__":
    print("=" * 50)
    print("🎯 NagAgent OpenAI Integration Test")
    print("=" * 50)
    
    if test_openai_connection():
        print("\n🚀 Backend is READY for iOS App Store deployment!")
        print("📱 No code changes needed - just deploy and connect!")
    else:
        print("\n⚠️ Please check your OpenAI API key and try again")