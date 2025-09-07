from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn
import logging
import os

from app.database import engine, Base
from sqlalchemy import text
from app.config import settings, validate_settings
from app.routers import webhook, auth, goals, tasks, roasts, reports
from app.services.scheduler_service import start_scheduler, stop_scheduler
from app.middleware.security import SecurityHeadersMiddleware, RequestLoggingMiddleware, UserContextMiddleware
from app.middleware.rate_limiter import limiter, custom_rate_limit_exceeded_handler
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

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

# Validate configuration on startup
try:
    validate_settings()
    logger.info("✅ Configuration validation completed")
except Exception as e:
    logger.error(f"❌ Configuration validation failed: {e}")
    raise

# Create database tables (gracefully handle missing database)
try:
    if engine is not None:
        logger.info("🗄️ Creating/verifying database tables...")
        Base.metadata.create_all(bind=engine)
        logger.info("✅ Database tables created/verified successfully")
    else:
        logger.warning("⚠️ Database engine not available - skipping table creation")
        logger.info("📝 Application will continue without database - some features may be limited")
except Exception as e:
    logger.warning(f"⚠️ Database not available during startup: {e}")
    logger.info("📝 Application will continue without database - some features may be limited")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info(f"🚀 Starting {settings.app_name} API v{settings.app_version}...")
    logger.info(f"🌍 Environment: {settings.environment}")
    
    if settings.rate_limit_enabled:
        logger.info("🚦 Rate limiting enabled")
    else:
        logger.info("🚦 Rate limiting disabled")
    
    try:
        start_scheduler()
        logger.info("📅 Scheduler started successfully")
    except Exception as e:
        logger.error(f"❌ Failed to start scheduler: {e}")
        logger.info("📝 Application will continue without scheduler")
    
    logger.info("✨ Application startup completed successfully")
    logger.info(f"📡 Health check available at /health")
    logger.info(f"📚 API documentation available at {settings.docs_url}")
    
    yield
    
    # Shutdown
    logger.info("🛑 Shutting down NagAgent API...")
    try:
        stop_scheduler()
        logger.info("📅 Scheduler stopped successfully")
    except Exception as e:
        logger.warning(f"⚠️ Error stopping scheduler: {e}")
    
    logger.info("👋 Application shutdown completed")

app = FastAPI(
    title=settings.app_name,
    description="AI Accountability Coach that roasts you into productivity 🔥\n\n"
                "## Features\n"
                "- 🎯 Goal setting and tracking\n"
                "- ✅ Daily task management\n"
                "- 😈 AI-powered roasts and accountability\n"
                "- 📊 Progress reports and statistics\n"
                "- 🔐 JWT authentication\n"
                "- 📱 iOS app support\n\n"
                "Choose your accountability personality and get roasted into productivity!",
    version=settings.app_version,
    docs_url=settings.docs_url,
    redoc_url=settings.redoc_url,
    lifespan=lifespan,
    openapi_tags=[
        {"name": "auth", "description": "Authentication endpoints"},
        {"name": "goals", "description": "Goal management"},
        {"name": "tasks", "description": "Daily task tracking"},
        {"name": "roasts", "description": "AI roasts and excuse processing"},
        {"name": "reports", "description": "Progress reports and statistics"},
        {"name": "webhook", "description": "Legacy webhook endpoints"},
        {"name": "health", "description": "Health check endpoints"}
    ]
)

# Add rate limiting
if settings.rate_limit_enabled:
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, custom_rate_limit_exceeded_handler)

# Add security middleware
app.add_middleware(SecurityHeadersMiddleware)
app.add_middleware(UserContextMiddleware)

if settings.is_development:
    app.add_middleware(RequestLoggingMiddleware)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=settings.allowed_methods,
    allow_headers=settings.allowed_headers,
)

# Include API routers
api_prefix = settings.api_prefix

app.include_router(auth.router, prefix=f"{api_prefix}/auth", tags=["auth"])
app.include_router(goals.router, prefix=f"{api_prefix}/goals", tags=["goals"])
app.include_router(tasks.router, prefix=f"{api_prefix}/tasks", tags=["tasks"])
app.include_router(roasts.router, prefix=f"{api_prefix}/roasts", tags=["roasts"])
app.include_router(reports.router, prefix=f"{api_prefix}/reports", tags=["reports"])

# Legacy webhook router (for backward compatibility)
app.include_router(webhook.router, prefix="/webhook", tags=["webhook"])

@app.get("/", tags=["health"])
async def root():
    """Root endpoint with API information"""
    return {
        "name": settings.app_name,
        "version": settings.app_version,
        "message": "NagAgent API is running. Stop procrastinating!",
        "status": "Your accountability coach is ready to roast you into productivity 🔥",
        "environment": settings.environment,
        "docs": f"{settings.api_prefix}/docs" if settings.docs_url else None,
        "endpoints": {
            "auth": f"{settings.api_prefix}/auth",
            "goals": f"{settings.api_prefix}/goals", 
            "tasks": f"{settings.api_prefix}/tasks",
            "roasts": f"{settings.api_prefix}/roasts",
            "reports": f"{settings.api_prefix}/reports"
        }
    }

@app.get("/health", tags=["health"])
async def health_check():
    """
    Fast health check endpoint optimized for Railway deployment
    Returns immediately without blocking on database connections
    """
    import os
    from datetime import datetime
    
    # Fast response - don't block on database connections for health checks
    health_response = {
        "status": "healthy",
        "message": "Ready to disappoint users with their lack of progress",
        "app": settings.app_name,
        "version": settings.app_version,
        "environment": settings.environment,
        "port": os.getenv("PORT", "8000"),
        "host": "0.0.0.0",
        "timestamp": datetime.utcnow().isoformat()
    }
    
    # Quick database status check (non-blocking)
    try:
        from app.database import database_available, engine
        
        if database_available and engine is not None:
            health_response["database"] = "configured"
        else:
            health_response["database"] = "not_available"
            
    except Exception as e:
        health_response["database"] = f"error: {str(e)[:50]}"
    
    return health_response

@app.get("/health/detailed", tags=["health"])
@limiter.limit("10/minute")
async def detailed_health_check():
    """
    Detailed health check that actually tests database connections
    Use this for monitoring, not for Railway health checks
    """
    import os
    from datetime import datetime
    
    health_response = {
        "status": "healthy",
        "message": "Detailed system health check",
        "app": settings.app_name,
        "version": settings.app_version,
        "environment": settings.environment,
        "timestamp": datetime.utcnow().isoformat(),
        "checks": {}
    }
    
    # Database connection test (this can be slow)
    try:
        from app.database import database_available, SessionLocal
        
        database_url = os.getenv("DATABASE_URL", settings.database_url)
        
        if database_available and database_url and "postgresql://" in database_url:
            if SessionLocal is not None:
                start_time = datetime.utcnow()
                db = SessionLocal()
                db.execute(text("SELECT 1"))
                db.close()
                end_time = datetime.utcnow()
                
                health_response["checks"]["database"] = {
                    "status": "healthy",
                    "response_time_ms": int((end_time - start_time).total_seconds() * 1000),
                    "url_configured": True
                }
            else:
                health_response["checks"]["database"] = {
                    "status": "not_available",
                    "error": "SessionLocal is None"
                }
        else:
            health_response["checks"]["database"] = {
                "status": "not_configured",
                "url_configured": bool(database_url and "postgresql://" in database_url)
            }
            
    except Exception as e:
        health_response["checks"]["database"] = {
            "status": "error",
            "error": str(e)[:200]
        }
    
    # OpenAI API check
    try:
        openai_configured = bool(os.getenv("OPENAI_API_KEY"))
        health_response["checks"]["openai"] = {
            "status": "configured" if openai_configured else "not_configured",
            "api_key_present": openai_configured
        }
    except Exception as e:
        health_response["checks"]["openai"] = {
            "status": "error",
            "error": str(e)[:100]
        }
    
    return health_response

@app.get(f"{settings.api_prefix}/personalities", tags=["roasts"])
@limiter.limit("100/minute")
async def get_personalities():
    """Get all available personalities (public endpoint)"""
    from app.services.personality_service import PersonalityService
    ps = PersonalityService()
    
    personalities = ps.get_all_personalities()
    
    return {
        "personalities": personalities,
        "message": "Choose your preferred method of accountability torture"
    }

if __name__ == "__main__":
    uvicorn.run(
        "app.main:app", 
        host="0.0.0.0", 
        port=8000, 
        reload=True
    )