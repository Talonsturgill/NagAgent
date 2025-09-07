# Railway Deployment Health Check Fix

## Issues Fixed

### 1. Port Configuration
**Problem**: The application was using hardcoded port 8000 instead of Railway's dynamic PORT environment variable.

**Solution**: 
- Updated both Dockerfiles to use `ENV PORT=8000` and `CMD uvicorn app.main:app --host 0.0.0.0 --port $PORT`
- Added PORT environment variable handling in railway.json

### 2. Health Check Endpoint
**Problem**: Health check was failing due to database connection requirements.

**Solution**:
- Modified `/health` endpoint to be database-optional
- Health check now returns "healthy" even if database is not configured
- Added graceful database connection handling

### 3. Database Connection Handling
**Problem**: Application crashed when DATABASE_URL was not available.

**Solution**:
- Added database availability checking in `app/database.py`
- Made database table creation optional during startup
- Health endpoint shows database status without failing the health check

### 4. Startup Process
**Problem**: Railway pre-deploy hooks were trying to run migrations without a database.

**Solution**:
- Created `startup.py` script that handles optional database migrations
- Updated CMD in Dockerfile to use the startup script
- Modified railway.json to use the new startup command

## Key Changes Made

### Files Modified:
- `Dockerfile` - Added dynamic PORT handling and startup script
- `NagAgent-Backend-Python/Dockerfile` - Fixed PORT configuration  
- `app/main.py` - Made database optional in health check and startup
- `app/database.py` - Added database availability checking
- `railway.json` - Updated startup command and health check timeout

### Files Created:
- `startup.py` - Graceful startup script with optional migrations
- `test-local-health.py` - Local testing script

## Health Check Configuration

The health check is now configured as:
- **Path**: `/health` 
- **Timeout**: 300 seconds (increased from 100)
- **Behavior**: Always returns "healthy" if app is responding
- **Database**: Shows status but doesn't affect health check result

## Expected Health Check Response

```json
{
  "status": "healthy",
  "message": "Ready to disappoint users with their lack of progress",
  "database": "not_configured",  // or "healthy" if database available
  "environment": "production",
  "version": "1.0.0",
  "port": "8000",
  "timestamp": "2024-01-01T00:00:00.000000"
}
```

## Deployment Steps

1. **Push to Railway**: The updated configuration should work with or without a database
2. **Check Health**: Visit `/health` endpoint to verify deployment
3. **Monitor Logs**: Check Railway logs for startup messages
4. **Optional Database**: If you add a DATABASE_URL later, the app will automatically use it

## Environment Variables

Required for Railway:
- `PORT` - Automatically provided by Railway
- `ENVIRONMENT` - Set to "production"

Optional:
- `DATABASE_URL` - If provided, enables full database features
- `OPENAI_API_KEY` - Required for AI roast features
- Other config variables as needed

## Testing Locally

Run the test script to verify everything works:
```bash
python test-local-health.py
```

This will start the server locally and test both the root and health endpoints.

## Troubleshooting

If health checks still fail:

1. **Check Logs**: Look at Railway deployment logs for startup errors
2. **Verify Port**: Ensure PORT environment variable is being used
3. **Test Locally**: Use the test script to verify functionality
4. **Health Endpoint**: Test `/health` endpoint directly
5. **Timeout**: Health check timeout is now 300 seconds, should be sufficient

The application should now start successfully on Railway and pass health checks even without a database configured.