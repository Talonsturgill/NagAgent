import os
from typing import List, Optional
from pydantic import BaseSettings, validator


class Settings(BaseSettings):
    # Environment
    environment: str = "development"
    debug: bool = True
    
    # Application
    app_name: str = "NagAgent"
    app_version: str = "1.0.0"
    api_prefix: str = "/api/v1"
    docs_url: Optional[str] = "/docs"
    redoc_url: Optional[str] = "/redoc"
    
    # Database
    database_url: str = "postgresql://nagent:nagentpass@localhost:5432/nagentdb"
    
    # Redis
    redis_url: str = "redis://localhost:6379"
    
    # Security & JWT
    secret_key: str = "your-secret-key-change-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 7
    
    # OpenAI
    openai_api_key: Optional[str] = None
    
    # Rate Limiting
    rate_limit_enabled: bool = True
    
    # CORS
    allowed_origins: List[str] = ["*"]
    allowed_methods: List[str] = ["*"]
    allowed_headers: List[str] = ["*"]
    
    # Logging
    log_level: str = "INFO"
    log_format: str = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    
    # Email
    smtp_server: Optional[str] = None
    smtp_port: int = 587
    smtp_username: Optional[str] = None
    smtp_password: Optional[str] = None
    from_email: Optional[str] = None
    
    # Twilio (legacy)
    twilio_account_sid: Optional[str] = None
    twilio_auth_token: Optional[str] = None
    twilio_phone_number: Optional[str] = None
    
    # Monitoring
    sentry_dsn: Optional[str] = None
    
    # File Upload
    max_file_size: int = 5242880  # 5MB
    allowed_file_types: List[str] = ["jpg", "jpeg", "png", "gif", "pdf"]
    
    # Stripe (for future premium features)
    stripe_publishable_key: Optional[str] = None
    stripe_secret_key: Optional[str] = None
    stripe_webhook_secret: Optional[str] = None
    
    # Push Notifications
    apns_key_id: Optional[str] = None
    apns_team_id: Optional[str] = None
    apns_bundle_id: Optional[str] = None
    apns_private_key_path: Optional[str] = None
    apns_use_sandbox: bool = True
    
    @validator("allowed_origins", pre=True)
    def parse_cors_origins(cls, v):
        if isinstance(v, str):
            return [origin.strip() for origin in v.split(",")]
        return v
    
    @validator("allowed_methods", pre=True)
    def parse_cors_methods(cls, v):
        if isinstance(v, str):
            return [method.strip() for method in v.split(",")]
        return v
    
    @validator("allowed_file_types", pre=True)
    def parse_file_types(cls, v):
        if isinstance(v, str):
            return [file_type.strip() for file_type in v.split(",")]
        return v
    
    @property
    def is_production(self) -> bool:
        return self.environment.lower() == "production"
    
    @property
    def is_development(self) -> bool:
        return self.environment.lower() == "development"
    
    @property
    def database_url_sync(self) -> str:
        """Synchronous database URL for Alembic"""
        return self.database_url.replace("postgresql://", "postgresql://")
    
    @property
    def database_url_async(self) -> str:
        """Asynchronous database URL (if using async driver)"""
        return self.database_url.replace("postgresql://", "postgresql+asyncpg://")
    
    class Config:
        env_file = ".env"
        case_sensitive = False
        # Allow reading from environment variables
        env_file_encoding = 'utf-8'


# Create global settings instance
settings = Settings()


def get_settings() -> Settings:
    """Dependency to get settings"""
    return settings


# Validate critical settings on startup
def validate_settings():
    """Validate critical configuration settings"""
    errors = []
    
    if settings.is_production:
        if settings.secret_key == "your-secret-key-change-in-production":
            errors.append("SECRET_KEY must be changed in production")
        
        if not settings.openai_api_key:
            errors.append("OPENAI_API_KEY is required for roast generation")
        
        if settings.debug:
            errors.append("DEBUG should be False in production")
        
        if "*" in settings.allowed_origins:
            errors.append("ALLOWED_ORIGINS should not include '*' in production")
    
    if errors:
        error_msg = "Configuration errors:\n" + "\n".join(f"- {error}" for error in errors)
        raise ValueError(error_msg)
    
    return True


# Database configuration for Alembic
def get_database_url() -> str:
    """Get database URL for Alembic migrations"""
    return settings.database_url