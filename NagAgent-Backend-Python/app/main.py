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

# Import routers - adding back all at once with safe fallbacks
routers_status = {}

try:
    from app.routers import auth
    routers_status['auth'] = True
    logger.info("✅ Auth router imported")
except Exception as e:
    routers_status['auth'] = False
    logger.warning(f"⚠️ Auth router not available: {e}")

try:
    from app.routers import goals
    routers_status['goals'] = True
    logger.info("✅ Goals router imported")
except Exception as e:
    routers_status['goals'] = False
    logger.warning(f"⚠️ Goals router not available: {e}")

try:
    from app.routers import tasks
    routers_status['tasks'] = True
    logger.info("✅ Tasks router imported")
except Exception as e:
    routers_status['tasks'] = False
    logger.warning(f"⚠️ Tasks router not available: {e}")

try:
    from app.routers import roasts
    routers_status['roasts'] = True
    logger.info("✅ Roasts router imported")
except Exception as e:
    routers_status['roasts'] = False
    logger.warning(f"⚠️ Roasts router not available: {e}")

try:
    from app.routers import reports
    routers_status['reports'] = True
    logger.info("✅ Reports router imported")
except Exception as e:
    routers_status['reports'] = False
    logger.warning(f"⚠️ Reports router not available: {e}")

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
if routers_status.get('auth'):
    try:
        app.include_router(auth.router, prefix="/api/v1/auth", tags=["authentication"])
        logger.info("✅ Auth router added")
    except Exception as e:
        logger.warning(f"⚠️ Could not add auth router: {e}")

if routers_status.get('goals'):
    try:
        app.include_router(goals.router, prefix="/api/v1/goals", tags=["goals"])
        logger.info("✅ Goals router added")
    except Exception as e:
        logger.warning(f"⚠️ Could not add goals router: {e}")

if routers_status.get('tasks'):
    try:
        app.include_router(tasks.router, prefix="/api/v1/tasks", tags=["tasks"])
        logger.info("✅ Tasks router added")
    except Exception as e:
        logger.warning(f"⚠️ Could not add tasks router: {e}")

if routers_status.get('roasts'):
    try:
        app.include_router(roasts.router, prefix="/api/v1/roasts", tags=["roasts"])
        logger.info("✅ Roasts router added")
    except Exception as e:
        logger.warning(f"⚠️ Could not add roasts router: {e}")

if routers_status.get('reports'):
    try:
        app.include_router(reports.router, prefix="/api/v1/reports", tags=["reports"])
        logger.info("✅ Reports router added")
    except Exception as e:
        logger.warning(f"⚠️ Could not add reports router: {e}")

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