#!/usr/bin/env python3
"""
Startup script for NagAgent API that handles database setup gracefully
"""
import os
import sys
import time
import subprocess
from pathlib import Path

def check_database_connection():
    """Check if database is available"""
    try:
        from app.database import engine, database_available
        if engine is not None and database_available:
            # Try to connect
            connection = engine.connect()
            connection.close()
            return True
    except Exception as e:
        print(f"Database not available: {e}")
    return False

def run_migrations():
    """Run database migrations if database is available"""
    try:
        if check_database_connection():
            print("🗄️ Database available - running migrations...")
            result = subprocess.run(
                [sys.executable, "-m", "alembic", "upgrade", "head"],
                capture_output=True,
                text=True,
                timeout=60
            )
            if result.returncode == 0:
                print("✅ Database migrations completed successfully")
                return True
            else:
                print(f"⚠️ Migration failed: {result.stderr}")
                return False
        else:
            print("⚠️ Database not available - skipping migrations")
            return True  # Not a failure, just skip
    except Exception as e:
        print(f"⚠️ Migration error: {e}")
        return True  # Continue without migrations

def start_application():
    """Start the FastAPI application"""
    port = os.getenv("PORT", "8000")
    host = "0.0.0.0"
    
    print(f"🚀 Starting NagAgent API on {host}:{port}")
    
    # Import after setting up environment
    try:
        import uvicorn
        uvicorn.run(
            "app.main:app",
            host=host,
            port=int(port),
            log_level="info"
        )
    except Exception as e:
        print(f"❌ Failed to start application: {e}")
        sys.exit(1)

def main():
    """Main startup function"""
    print("🔥 NagAgent API Startup")
    print(f"📍 Working directory: {Path.cwd()}")
    print(f"🌍 Environment: {os.getenv('ENVIRONMENT', 'development')}")
    print(f"🔌 Port: {os.getenv('PORT', '8000')}")
    
    # Run migrations (optional)
    run_migrations()
    
    # Start the application
    start_application()

if __name__ == "__main__":
    main()