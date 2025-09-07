from sqlalchemy import create_engine, MetaData, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
import time
import logging
from dotenv import load_dotenv

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:password@localhost/nagagent")

def create_database_engine(database_url: str, max_retries: int = 3):
    """Create database engine with retry logic for Railway deployment"""
    for attempt in range(max_retries):
        try:
            logger.info(f"🔌 Attempting to connect to database (attempt {attempt + 1}/{max_retries})")
            
            # Configure engine with Railway-optimized settings
            engine_config = {
                "pool_pre_ping": True,  # Verify connections before use
                "pool_recycle": 300,    # Recycle connections every 5 minutes
                "pool_timeout": 30,     # Wait up to 30 seconds for connection
                "max_overflow": 0,      # Don't create extra connections
                "pool_size": 5,         # Small pool for Railway
                "connect_args": {
                    "connect_timeout": 10,  # 10 second connection timeout
                    "application_name": "nagagent-api",
                }
            }
            
            # Create engine with optimized settings
            engine = create_engine(database_url, **engine_config)
            
            # Test the connection with a simple query
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
                logger.info("✅ Database connection successful!")
                
            return engine, True
            
        except Exception as e:
            logger.warning(f"⚠️ Database connection attempt {attempt + 1} failed: {e}")
            if attempt < max_retries - 1:
                wait_time = (attempt + 1) * 2  # Progressive backoff: 2s, 4s, 6s
                logger.info(f"⏳ Retrying in {wait_time} seconds...")
                time.sleep(wait_time)
            else:
                logger.error("❌ All database connection attempts failed")
                
    return None, False

# Create engine with error handling for missing database
logger.info(f"🗄️ Initializing database connection...")
logger.info(f"📍 DATABASE_URL configured: {'Yes' if DATABASE_URL and DATABASE_URL != 'postgresql://user:password@localhost/nagagent' else 'No'}")

engine, database_available = create_database_engine(DATABASE_URL)

if database_available and engine:
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    logger.info("✅ Database session factory created")
else:
    logger.warning("⚠️ Database not available - running in degraded mode")
    engine = None
    SessionLocal = None
    database_available = False

Base = declarative_base()

def get_db():
    if not database_available or SessionLocal is None:
        raise Exception("Database not available")
    
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()