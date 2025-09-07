from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from fastapi import Request, Response
from fastapi.responses import JSONResponse
import redis
import os

# Redis connection for rate limiting
redis_url = os.getenv("REDIS_URL", "redis://localhost:6379")
try:
    redis_client = redis.from_url(redis_url, decode_responses=True)
    redis_client.ping()  # Test connection
except (redis.ConnectionError, redis.RedisError):
    # Fallback to in-memory storage if Redis is not available
    redis_client = None

def get_remote_address_or_user(request: Request):
    """
    Get the user's ID if authenticated, otherwise fall back to IP address
    This allows for more accurate rate limiting per user
    """
    # Try to get user ID from the request state (set by auth middleware)
    user_id = getattr(request.state, 'user_id', None)
    if user_id:
        return f"user:{user_id}"
    
    # Fall back to IP address
    return get_remote_address(request)

# Create limiter instance
limiter = Limiter(
    key_func=get_remote_address_or_user,
    storage_uri=redis_url if redis_client else "memory://",
    default_limits=["1000/hour"]  # Default limit
)

# Custom rate limit exceeded handler
async def custom_rate_limit_exceeded_handler(request: Request, exc: RateLimitExceeded):
    """Custom handler for rate limit exceeded errors"""
    return JSONResponse(
        status_code=429,
        content={
            "success": False,
            "message": "Whoa there, speed demon! You're making requests faster than you complete your goals. Slow down! 🐌",
            "detail": f"Rate limit exceeded: {exc.detail}",
            "retry_after": exc.retry_after
        },
        headers={"Retry-After": str(exc.retry_after)} if exc.retry_after else {}
    )

# Rate limiting decorators for different endpoints
class RateLimits:
    # Authentication endpoints - more restrictive
    AUTH_REGISTER = "5/minute"
    AUTH_LOGIN = "10/minute"
    AUTH_REFRESH = "20/minute"
    
    # CRUD operations - moderate limits
    GOALS_CREATE = "10/minute"
    GOALS_UPDATE = "20/minute"
    TASKS_UPDATE = "30/minute"
    
    # Roast generation - limited due to AI API costs
    ROAST_GENERATE = "20/minute"
    EXCUSE_SUBMIT = "15/minute"
    
    # Reports and stats - less restrictive
    REPORTS_DAILY = "60/minute"
    REPORTS_WEEKLY = "30/minute"
    REPORTS_MONTHLY = "10/minute"
    
    # General API calls
    GENERAL = "100/minute"