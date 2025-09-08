from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import logging
import os

# Import config first (minimal dependencies)
from app.config import settings

# Configure logging based on environment
log_level = os.getenv("LOG_LEVEL", "INFO").upper()
logging.basicConfig(
    level=getattr(logging, log_level, logging.INFO),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

logger.info("🔥 Initializing NagAgent API application...")
logger.info(f"🌍 Environment: {settings.environment}")
logger.info(f"🔌 Port: {os.getenv('PORT', '8000')}")
logger.info(f"📊 Log level: {log_level}")

# Import routers - adding back one at a time
try:
    from app.routers import auth
    auth_available = True
    logger.info("✅ Auth router imported successfully")
except Exception as e:
    auth_available = False
    logger.warning(f"⚠️ Auth router not available: {e}")

# Skip ALL database and complex startup checks for Railway healthcheck
logger.info("⚡ Skipping database initialization for fast startup")

app = FastAPI(
    title=settings.app_name,
    description="AI Accountability Coach that roasts you into productivity 🔥",
    version=settings.app_version,
    docs_url=settings.docs_url,
    redoc_url=settings.redoc_url,
    openapi_tags=[
        {"name": "health", "description": "Health check endpoints"}
    ]
)

# Add CORS middleware for all endpoints
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],  # Allow all methods for API endpoints
    allow_headers=["*"],
)

# Add routers if available
if auth_available:
    try:
        app.include_router(auth.router, prefix="/api/v1/auth", tags=["authentication"])
        logger.info("✅ Auth router added to app")
    except Exception as e:
        logger.warning(f"⚠️ Could not add auth router: {e}")

logger.info("⚡ Middleware and routers configured")

@app.get("/", tags=["health"])
async def root():
    """Root endpoint with API information"""
    return {
        "name": settings.app_name,
        "version": settings.app_version,
        "message": "NagAgent API is running. Stop procrastinating!",
        "status": "healthy",
        "environment": settings.environment
    }

@app.get("/health", tags=["health"])
async def health_check():
    """
    Ultra-fast health check endpoint optimized for Railway deployment
    Returns immediately without ANY blocking operations
    """
    return {
        "status": "healthy",
        "app": settings.app_name,
        "version": settings.app_version,
        "environment": settings.environment,
        "message": "Railway healthcheck passing"
    }


# Application ready for Railway deployment with minimal dependencies
logger.info("✅ NagAgent API initialized successfully for Railway healthcheck")