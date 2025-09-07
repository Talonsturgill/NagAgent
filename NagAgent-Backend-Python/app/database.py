from sqlalchemy import create_engine, MetaData
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:password@localhost/nagagent")

# Create engine with error handling for missing database
try:
    engine = create_engine(DATABASE_URL)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    database_available = True
except Exception as e:
    print(f"⚠️ Database connection failed: {e}")
    # Create a dummy engine for graceful degradation
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