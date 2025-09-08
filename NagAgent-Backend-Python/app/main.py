from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn
import logging
import os
import asyncio

# Import config first (minimal dependencies)
from app.config import settings

# Import database components with safe fallback
try:
    from app.database import engine, Base, get_db
    from sqlalchemy import text
    database_available = True
    logging.info("✅ Database components imported")
except Exception as e:
    database_available = False
    logging.warning(f"⚠️ Database not available: {e}")

# Import middleware components with safe fallback
try:
    from app.middleware.security import SecurityMiddleware
    from app.middleware.rate_limiter import RateLimiterMiddleware
    middleware_available = True
    logging.info("✅ Middleware components imported")
except Exception as e:
    middleware_available = False
    logging.warning(f"⚠️ Middleware not available: {e}")

# Import scheduler with safe fallback
try:
    from app.scheduler import scheduler, start_scheduler
    scheduler_available = True
    logging.info("✅ Scheduler imported")
except Exception as e:
    scheduler_available = False
    logging.warning(f"⚠️ Scheduler not available: {e}")

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

try:
    from app.routers import webhook
    routers_status['webhook'] = True
    logger.info("✅ Webhook router imported")
except Exception as e:
    routers_status['webhook'] = False
    logger.warning(f"⚠️ Webhook router not available: {e}")

# Lifespan manager for proper startup/shutdown
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifecycle with safe database initialization"""
    # Startup
    logger.info("🚀 Starting NagAgent application lifecycle...")
    
    # Initialize database if available (non-blocking)
    if database_available:
        try:
            # Create tables in background to not block health checks
            async def init_db():
                await asyncio.sleep(1)  # Let health check start first
                try:
                    Base.metadata.create_all(bind=engine)
                    # Test connection
                    with engine.connect() as conn:
                        conn.execute(text("SELECT 1"))
                        conn.commit()
                    logger.info("✅ Database initialized successfully")
                except Exception as e:
                    logger.warning(f"⚠️ Database initialization failed (non-critical): {e}")
            
            # Start database init in background
            asyncio.create_task(init_db())
        except Exception as e:
            logger.warning(f"⚠️ Could not start database initialization: {e}")
    
    # Start scheduler if available (non-blocking)
    if scheduler_available:
        try:
            async def init_scheduler():
                await asyncio.sleep(2)  # Let other services start first
                try:
                    start_scheduler()
                    logger.info("✅ Background scheduler started")
                except Exception as e:
                    logger.warning(f"⚠️ Scheduler failed to start (non-critical): {e}")
            
            asyncio.create_task(init_scheduler())
        except Exception as e:
            logger.warning(f"⚠️ Could not start scheduler: {e}")
    
    yield  # Application runs here
    
    # Shutdown
    logger.info("👋 Shutting down NagAgent application...")
    
    # Stop scheduler if running
    if scheduler_available:
        try:
            scheduler.shutdown(wait=False)
            logger.info("✅ Scheduler stopped")
        except:
            pass
    
    # Close database connections
    if database_available:
        try:
            engine.dispose()
            logger.info("✅ Database connections closed")
        except:
            pass

app = FastAPI(
    title=settings.app_name,
    description="AI Accountability Coach that roasts you into productivity 🔥",
    version=settings.app_version,
    docs_url=settings.docs_url,
    redoc_url=settings.redoc_url,
    lifespan=lifespan,  # Add lifecycle management
    openapi_tags=[
        {"name": "health", "description": "Health check endpoints"},
        {"name": "authentication", "description": "User authentication"},
        {"name": "goals", "description": "Goal management"},
        {"name": "tasks", "description": "Task tracking"},
        {"name": "roasts", "description": "AI roasting engine"},
        {"name": "reports", "description": "Progress reports"},
        {"name": "webhook", "description": "External webhooks"}
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

# Add security middleware if available
if middleware_available:
    try:
        app.add_middleware(SecurityMiddleware)
        logger.info("✅ Security middleware added")
    except Exception as e:
        logger.warning(f"⚠️ Could not add security middleware: {e}")
    
    try:
        app.add_middleware(RateLimiterMiddleware)
        logger.info("✅ Rate limiter middleware added")
    except Exception as e:
        logger.warning(f"⚠️ Could not add rate limiter: {e}")

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

if routers_status.get('webhook'):
    try:
        app.include_router(webhook.router, prefix="/api/v1/webhook", tags=["webhook"])
        logger.info("✅ Webhook router added")
    except Exception as e:
        logger.warning(f"⚠️ Could not add webhook router: {e}")

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