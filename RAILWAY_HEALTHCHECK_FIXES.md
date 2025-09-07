# Railway Healthcheck Fixes

This document outlines the fixes implemented to resolve Railway healthcheck failures for the NagAgent API.

## Issues Identified

1. **Database Connection Blocking**: Health check was trying to connect to PostgreSQL during startup, causing timeouts
2. **Slow Health Endpoint**: The `/health` endpoint was performing actual database queries, making it slow
3. **Railway Internal Network**: Database at `postgres.railway.internal:5432` only works within Railway's private network
4. **Startup Process**: Application startup was blocking on database migrations
5. **Missing Debug Logging**: Insufficient logging to identify deployment issues

## Fixes Implemented

### 1. Optimized Database Connection (`app/database.py`)
- Added retry logic with progressive backoff for Railway database connections
- Configured connection pool settings optimized for Railway
- Added connection timeout and application name for better monitoring
- Graceful degradation when database is not available

### 2. Fast Health Check Endpoint (`app/main.py`)
- **`/health`**: Fast endpoint that doesn't block on database connections
- **`/health/detailed`**: Slower endpoint for actual database health monitoring
- Response time optimized to under 1 second
- Always returns "healthy" status if application is responding

### 3. Improved Startup Process (`startup.py`)
- Non-blocking database connection checks with timeout
- Optional database migrations with timeout protection
- Environment-aware configuration (production vs development)
- Graceful continuation even if migrations fail

### 4. Railway Configuration (`railway.json`)
- Reduced healthcheck timeout from 300s to 30s
- Added healthcheck interval of 30s
- Reduced restart retries to prevent cascading failures
- Added environment variables for better control

### 5. Comprehensive Logging
- Added structured logging throughout the application
- Environment-based log levels
- Startup process logging for debugging
- Database connection status logging

## Key Changes

### Health Check Endpoints

```python
# Fast health check (used by Railway)
GET /health
{
    "status": "healthy",
    "app": "NagAgent",
    "database": "configured",  # Quick status, no connection test
    "environment": "production",
    "timestamp": "2025-09-07T..."
}

# Detailed health check (for monitoring)
GET /health/detailed
{
    "status": "healthy",
    "checks": {
        "database": {
            "status": "healthy",
            "response_time_ms": 45
        }
    }
}
```

### Database Connection with Retry Logic

```python
def create_database_engine(database_url: str, max_retries: int = 3):
    """Create database engine with retry logic for Railway deployment"""
    for attempt in range(max_retries):
        try:
            engine_config = {
                "pool_pre_ping": True,
                "pool_recycle": 300,
                "pool_timeout": 30,
                "connect_args": {
                    "connect_timeout": 10,
                    "application_name": "nagagent-api",
                }
            }
            engine = create_engine(database_url, **engine_config)
            # Test connection
            with engine.connect() as conn:
                conn.execute("SELECT 1")
            return engine, True
        except Exception as e:
            # Progressive backoff: 2s, 4s, 6s
            time.sleep((attempt + 1) * 2)
```

### Environment Variables

```json
{
  "envVars": {
    "PORT": "${{PORT}}",
    "ENVIRONMENT": "production",
    "SKIP_MIGRATIONS": "false",
    "LOG_LEVEL": "INFO"
  }
}
```

## Testing

Run the test script to verify all fixes work correctly:

```bash
python test-local-health.py
```

This will test:
- Fast health check endpoint
- Detailed health check endpoint
- Application startup with the startup script
- Database connection handling
- Logging output

## Deployment Instructions

1. **Environment Variables to Set in Railway:**
   ```
   DATABASE_URL=postgresql://postgres:TGuRlWrKBMZmfZwTqWGjzLWUNkYrGkWk@postgres.railway.internal:5432/railway
   ENVIRONMENT=production
   LOG_LEVEL=INFO
   OPENAI_API_KEY=your_openai_key
   SECRET_KEY=your_secret_key
   ```

2. **Railway Configuration:**
   - Health check path: `/health`
   - Health check timeout: 30 seconds
   - Start command: `python startup.py`

3. **Expected Behavior:**
   - Application starts within 30 seconds
   - Health check responds immediately (< 1 second)
   - Database connections are established with retry logic
   - Migrations run automatically (can be skipped with `SKIP_MIGRATIONS=true`)
   - Comprehensive logging for debugging

## Monitoring

- Use `/health` for Railway health checks (fast)
- Use `/health/detailed` for monitoring systems (slower but more detailed)
- Check logs for startup issues and database connection status
- Monitor response times and error rates

## Benefits

1. **Reliable Health Checks**: Fast response time eliminates timeout issues
2. **Resilient Database Connections**: Handles Railway's internal network timing
3. **Better Debugging**: Comprehensive logging for troubleshooting
4. **Graceful Degradation**: Application continues even if database is temporarily unavailable
5. **Production Ready**: Optimized configuration for Railway deployment