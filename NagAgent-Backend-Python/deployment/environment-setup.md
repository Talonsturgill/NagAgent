# Environment Variables Setup Guide

## Overview
This guide covers setting up environment variables for NagAgent backend deployment across different platforms and environments.

## Required Environment Variables

### Database Configuration
```bash
# PostgreSQL Database URL (provided by Railway)
DATABASE_URL=postgresql://username:password@host:port/database

# Database Connection Pool Settings
DB_POOL_SIZE=10
DB_POOL_OVERFLOW=20
```

### API Configuration
```bash
# Application Settings
APP_NAME="NagAgent API"
APP_VERSION="1.0.0"
ENVIRONMENT=production  # production, staging, development, test
API_VERSION=v1
API_PREFIX=/api/v1

# Documentation URLs (set to null to disable in production)
DOCS_URL=/docs
REDOC_URL=/redoc
```

### Security & Authentication
```bash
# JWT Configuration - CRITICAL: Generate secure random keys
JWT_SECRET_KEY=your-super-secret-jwt-key-minimum-32-characters-long
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30
JWT_REFRESH_TOKEN_EXPIRE_DAYS=7

# Rate Limiting
RATE_LIMIT_ENABLED=true
RATE_LIMIT_REQUESTS_PER_MINUTE=100
```

### OpenAI Configuration
```bash
# OpenAI API for AI personality responses
OPENAI_API_KEY=sk-your-openai-api-key-here
OPENAI_MODEL=gpt-4o-mini  # or gpt-4-turbo for better responses
OPENAI_MAX_TOKENS=150
OPENAI_TEMPERATURE=0.8
OPENAI_TIMEOUT=30
```

### Twilio Configuration (SMS Notifications)
```bash
# Twilio Account Settings
TWILIO_ACCOUNT_SID=your-twilio-account-sid
TWILIO_AUTH_TOKEN=your-twilio-auth-token
TWILIO_PHONE_NUMBER=+1234567890  # Your Twilio phone number
```

### CORS Configuration
```bash
# Allow origins (comma-separated for multiple domains)
ALLOWED_ORIGINS=https://nagagent.ai,https://www.nagagent.ai,https://app.nagagent.ai
ALLOWED_METHODS=GET,POST,PUT,DELETE,PATCH,OPTIONS
ALLOWED_HEADERS=*
```

### Logging Configuration
```bash
# Logging Level
LOG_LEVEL=INFO  # DEBUG, INFO, WARNING, ERROR, CRITICAL
```

### Feature Flags
```bash
# Enable/disable specific features
ENABLE_WEBHOOK_LEGACY=true
ENABLE_SOCIAL_FEATURES=false
ENABLE_VOICE_MESSAGES=true
ENABLE_ANALYTICS=true
```

## Platform-Specific Setup Instructions

### Railway.app Deployment

#### 1. Via Railway CLI
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login to Railway
railway login

# Link to your project
railway link

# Set environment variables
railway variables set JWT_SECRET_KEY="your-secret-key-here"
railway variables set OPENAI_API_KEY="sk-your-key"
railway variables set TWILIO_ACCOUNT_SID="your-sid"
railway variables set TWILIO_AUTH_TOKEN="your-token"

# Set all variables from file
railway variables set --from-file .env.production
```

#### 2. Via Railway Dashboard
1. Go to your Railway project dashboard
2. Click on your service
3. Go to "Variables" tab
4. Add each variable manually

#### 3. Via railway.json (deprecated, use railway-config.toml)
```json
{
  "build": {
    "builder": "nixpacks"
  },
  "deploy": {
    "startCommand": "uvicorn app.main:app --host 0.0.0.0 --port $PORT"
  }
}
```

### Docker Deployment

#### Docker Compose with Environment Files
```yaml
# docker-compose.prod.yml
version: '3.8'
services:
  api:
    build: .
    env_file:
      - .env.production
    ports:
      - "8000:8000"
    depends_on:
      - database
      - redis

  database:
    image: postgres:15
    environment:
      POSTGRES_DB: nagagent
      POSTGRES_USER: nagagent
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

### Heroku Deployment

#### Via Heroku CLI
```bash
# Set config vars
heroku config:set JWT_SECRET_KEY="your-secret-key"
heroku config:set OPENAI_API_KEY="sk-your-key"
heroku config:set ENVIRONMENT="production"

# Set from file
heroku config:set $(cat .env.production | sed '/^#/d' | sed '/^$/d')
```

### Render.com Deployment

Environment variables are set in the Render dashboard under your service settings.

## Environment Files Structure

### .env.example (Template)
```bash
# Copy this file to .env and fill in your values

# Database
DATABASE_URL=postgresql://localhost:5432/nagagent_dev
DB_POOL_SIZE=10

# API
APP_NAME="NagAgent API"
ENVIRONMENT=development
API_PREFIX=/api/v1

# Security
JWT_SECRET_KEY=generate-a-secure-key-here
JWT_ALGORITHM=HS256

# OpenAI
OPENAI_API_KEY=your-openai-key-here
OPENAI_MODEL=gpt-4o-mini

# Twilio
TWILIO_ACCOUNT_SID=your-twilio-sid
TWILIO_AUTH_TOKEN=your-twilio-token
TWILIO_PHONE_NUMBER=+1234567890

# CORS
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080

# Logging
LOG_LEVEL=DEBUG
```

### .env.production
```bash
# Production environment variables
ENVIRONMENT=production
LOG_LEVEL=INFO
DOCS_URL=null  # Disable docs in production
REDOC_URL=null
RATE_LIMIT_ENABLED=true

# Use production URLs
ALLOWED_ORIGINS=https://nagagent.ai,https://www.nagagent.ai

# Production OpenAI settings
OPENAI_MODEL=gpt-4o-mini
OPENAI_MAX_TOKENS=150
OPENAI_TEMPERATURE=0.8
```

### .env.staging
```bash
# Staging environment variables
ENVIRONMENT=staging
LOG_LEVEL=DEBUG
DOCS_URL=/docs  # Keep docs enabled in staging

# Use staging URLs
ALLOWED_ORIGINS=https://staging.nagagent.ai

# Staging can use same OpenAI settings as production
```

### .env.development
```bash
# Development environment variables
ENVIRONMENT=development
LOG_LEVEL=DEBUG
DATABASE_URL=postgresql://localhost:5432/nagagent_dev
RATE_LIMIT_ENABLED=false

# Local development
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080,http://127.0.0.1:3000

# Development OpenAI settings (can use cheaper model)
OPENAI_MODEL=gpt-4o-mini
OPENAI_MAX_TOKENS=100
```

## Security Best Practices

### 1. Secret Key Generation
```python
# Generate secure JWT secret key
import secrets
jwt_secret = secrets.token_urlsafe(32)
print(f"JWT_SECRET_KEY={jwt_secret}")
```

```bash
# Or use OpenSSL
openssl rand -base64 32
```

### 2. Environment File Security
- Never commit `.env` files to version control
- Add `.env*` to `.gitignore` (except `.env.example`)
- Use different keys for different environments
- Rotate keys regularly in production

### 3. Access Control
- Limit access to production environment variables
- Use platform-specific secret management
- Monitor access to sensitive variables
- Use least-privilege principle

## Validation and Testing

### Environment Variable Validation Script
```python
# scripts/validate_env.py
import os
from typing import List, Dict, Any

def validate_environment():
    """Validate that all required environment variables are set"""
    required_vars = [
        'DATABASE_URL',
        'JWT_SECRET_KEY',
        'OPENAI_API_KEY',
        'TWILIO_ACCOUNT_SID',
        'TWILIO_AUTH_TOKEN',
    ]
    
    optional_vars = {
        'ENVIRONMENT': 'development',
        'LOG_LEVEL': 'INFO',
        'API_PREFIX': '/api/v1',
    }
    
    missing_vars = []
    for var in required_vars:
        if not os.getenv(var):
            missing_vars.append(var)
    
    if missing_vars:
        print("❌ Missing required environment variables:")
        for var in missing_vars:
            print(f"  - {var}")
        return False
    
    print("✅ All required environment variables are set")
    
    # Check optional variables
    for var, default in optional_vars.items():
        value = os.getenv(var, default)
        print(f"  {var}={value}")
    
    return True

if __name__ == "__main__":
    validate_environment()
```

### Test Environment Setup
```bash
# Run validation script
python scripts/validate_env.py

# Test database connection
python -c "from app.database import engine; from sqlalchemy import text; print('DB connection:', engine.execute(text('SELECT 1')))"

# Test OpenAI connection
python -c "from app.services.openai_service import test_connection; test_connection()"
```

## Troubleshooting

### Common Issues

1. **Database Connection Errors**
   - Verify DATABASE_URL format
   - Check network connectivity
   - Ensure database exists and user has permissions

2. **OpenAI API Errors**
   - Verify API key is valid and active
   - Check OpenAI account billing status
   - Verify model name is correct

3. **Twilio Errors**
   - Verify account SID and auth token
   - Check Twilio account status and balance
   - Verify phone number format

4. **CORS Errors**
   - Check ALLOWED_ORIGINS includes your frontend URL
   - Verify protocol (http vs https)
   - Check for trailing slashes

### Environment Variable Priority
1. System environment variables (highest priority)
2. .env file in current directory
3. Default values in code (lowest priority)

## Deployment Checklist

- [ ] All required environment variables set
- [ ] Secrets are secure and rotated
- [ ] Environment-specific configurations applied
- [ ] Database migrations completed
- [ ] Health check endpoints responding
- [ ] Logging levels appropriate for environment
- [ ] CORS origins configured correctly
- [ ] Rate limiting enabled in production
- [ ] Documentation endpoints configured appropriately
- [ ] Monitoring and alerts configured
- [ ] Backup and disaster recovery plans in place

---

**Important**: Always use secure, unique values for production environments and never expose sensitive environment variables in logs or error messages.