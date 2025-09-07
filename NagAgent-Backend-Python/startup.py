#!/usr/bin/env python3
"""
Startup script for NagAgent API optimized for Railway deployment
"""
import os
import sys
import time
import subprocess
import logging
from pathlib import Path

# Configure logging for startup process
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def check_database_connection(max_wait: int = 30):
    """Check if database is available with timeout"""
    logger.info("🔍 Checking database availability...")
    
    start_time = time.time()
    while (time.time() - start_time) < max_wait:
        try:
            # Import here to avoid issues with module loading
            from app.database import engine, database_available
            
            if engine is not None and database_available:
                # Try to connect with timeout
                from sqlalchemy import text
                connection = engine.connect()
                connection.execute(text("SELECT 1"))
                connection.close()
                logger.info("✅ Database connection successful")
                return True
        except Exception as e:
            logger.debug(f"Database connection attempt failed: {e}")
            
        # Wait before retrying
        time.sleep(2)
        logger.debug("⏳ Retrying database connection...")
    
    logger.warning("⚠️ Database not available after waiting")
    return False

def run_migrations():
    """Run database migrations if database is available"""
    logger.info("🗄️ Checking if migrations should run...")
    
    # Only try migrations in production or if explicitly requested
    environment = os.getenv('ENVIRONMENT', 'development').lower()
    skip_migrations = os.getenv('SKIP_MIGRATIONS', 'false').lower() == 'true'
    
    if skip_migrations:
        logger.info("⏭️ Migrations skipped (SKIP_MIGRATIONS=true)")
        return True
        
    try:
        # Check if database is ready (but don't wait too long)
        if check_database_connection(max_wait=15):
            logger.info("🔧 Running database migrations...")
            
            result = subprocess.run(
                [sys.executable, "-m", "alembic", "upgrade", "head"],
                capture_output=True,
                text=True,
                timeout=120  # 2 minute timeout for migrations
            )
            
            if result.returncode == 0:
                logger.info("✅ Database migrations completed successfully")
                return True
            else:
                logger.warning(f"⚠️ Migration failed: {result.stderr}")
                # Don't fail startup for migration issues in production
                if environment == 'production':
                    logger.info("🔄 Continuing startup despite migration issues (production mode)")
                    return True
                return False
        else:
            logger.info("⚠️ Database not ready - skipping migrations")
            return True  # Not a failure, just skip
            
    except subprocess.TimeoutExpired:
        logger.error("⏰ Migration timeout - continuing without migrations")
        return True  # Continue startup
    except Exception as e:
        logger.warning(f"⚠️ Migration error: {e}")
        return True  # Continue without migrations

def start_application():
    """Start the FastAPI application"""
    port = int(os.getenv("PORT", "8000"))
    host = "0.0.0.0"
    environment = os.getenv("ENVIRONMENT", "development").lower()
    
    logger.info(f"🚀 Starting NagAgent API on {host}:{port}")
    logger.info(f"🌍 Environment: {environment}")
    
    # Configure uvicorn settings based on environment
    if environment == "production":
        log_level = "warning"
        reload = False
        workers = 1  # Single worker for Railway
    else:
        log_level = "info"
        reload = False  # Disable reload in containers
        workers = 1
    
    try:
        import uvicorn
        
        # Configure uvicorn for Railway deployment
        config = uvicorn.Config(
            "app.main:app",
            host=host,
            port=port,
            log_level=log_level,
            reload=reload,
            workers=workers,
            access_log=True,
            server_header=False,  # Don't expose server info
            date_header=True,
        )
        
        server = uvicorn.Server(config)
        logger.info("🎯 Application ready to serve requests")
        server.run()
        
    except Exception as e:
        logger.error(f"❌ Failed to start application: {e}")
        sys.exit(1)

def print_environment_info():
    """Print environment information for debugging"""
    logger.info("🔥 NagAgent API Startup")
    logger.info(f"📍 Working directory: {Path.cwd()}")
    logger.info(f"🌍 Environment: {os.getenv('ENVIRONMENT', 'development')}")
    logger.info(f"🔌 Port: {os.getenv('PORT', '8000')}")
    logger.info(f"🗄️ Database URL configured: {'Yes' if os.getenv('DATABASE_URL') else 'No'}")
    logger.info(f"🤖 OpenAI API Key configured: {'Yes' if os.getenv('OPENAI_API_KEY') else 'No'}")
    logger.info(f"🐍 Python version: {sys.version}")
    
    # Log Railway-specific environment variables
    railway_vars = ['RAILWAY_ENVIRONMENT', 'RAILWAY_SERVICE_NAME', 'RAILWAY_DEPLOYMENT_ID']
    for var in railway_vars:
        if os.getenv(var):
            logger.info(f"🚂 {var}: {os.getenv(var)}")

def main():
    """Main startup function"""
    try:
        print_environment_info()
        
        # Run migrations (optional and non-blocking)
        migration_success = run_migrations()
        
        if not migration_success:
            logger.warning("⚠️ Migrations had issues but continuing startup")
        
        # Start the application (this will block)
        start_application()
        
    except KeyboardInterrupt:
        logger.info("🛑 Received interrupt signal, shutting down...")
        sys.exit(0)
    except Exception as e:
        logger.error(f"❌ Startup failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()