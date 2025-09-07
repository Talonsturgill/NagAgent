from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn

from app.database import engine, Base
from app.config import settings, validate_settings
from app.routers import webhook, auth, goals, tasks, roasts, reports
from app.services.scheduler_service import start_scheduler, stop_scheduler
from app.middleware.security import SecurityHeadersMiddleware, RequestLoggingMiddleware, UserContextMiddleware
from app.middleware.rate_limiter import limiter, custom_rate_limit_exceeded_handler
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

# Validate configuration on startup
validate_settings()

# Create database tables
Base.metadata.create_all(bind=engine)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    print(f"🔥 Starting {settings.app_name} API v{settings.app_version}...")
    print(f"🌍 Environment: {settings.environment}")
    
    if settings.rate_limit_enabled:
        print("🚦 Rate limiting enabled")
    
    start_scheduler()
    print("📅 Scheduler started")
    yield
    # Shutdown
    print("🛑 Shutting down NagAgent API...")
    stop_scheduler()
    print("📅 Scheduler stopped")

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
@limiter.limit("60/minute")
async def health_check():
    """Health check endpoint"""
    try:
        # Test database connection
        from app.database import SessionLocal
        db = SessionLocal()
        db.execute("SELECT 1")
        db.close()
        db_status = "healthy"
    except Exception as e:
        db_status = f"unhealthy: {str(e)}"
    
    return {
        "status": "healthy" if db_status == "healthy" else "unhealthy",
        "message": "Ready to disappoint users with their lack of progress" if db_status == "healthy" else "Database issues detected",
        "database": db_status,
        "environment": settings.environment,
        "version": settings.app_version
    }

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