from datetime import timedelta
from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.dependencies import get_db, get_current_active_user
from app.middleware.rate_limiter import limiter, RateLimits
from app.schemas import (
    UserRegister, UserLogin, Token, RefreshTokenRequest, 
    User, UserUpdate, APIResponse
)
from app.services.auth_service import AuthService
from app.models import User as UserModel

router = APIRouter()

@router.post("/register", response_model=APIResponse)
@limiter.limit(RateLimits.AUTH_REGISTER)
async def register(
    request: Request,
    user: UserRegister,
    db: Session = Depends(get_db)
):
    """Register a new user"""
    try:
        db_user = AuthService.create_user(db, user)
        
        # Create tokens
        access_token = AuthService.create_access_token(
            data={"sub": db_user.email}
        )
        refresh_token = AuthService.create_refresh_token(db, db_user.id)
        
        return APIResponse(
            success=True,
            message="User registered successfully",
            data={
                "user": {
                    "id": db_user.id,
                    "email": db_user.email,
                    "name": db_user.name,
                    "personality": db_user.personality
                },
                "tokens": {
                    "access_token": access_token,
                    "refresh_token": refresh_token,
                    "token_type": "bearer"
                }
            }
        )
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Registration failed"
        )

@router.post("/login", response_model=APIResponse)
@limiter.limit(RateLimits.AUTH_LOGIN)
async def login(
    request: Request,
    user: UserLogin,
    db: Session = Depends(get_db)
):
    """Login user"""
    db_user = AuthService.authenticate_user(db, user.email, user.password)
    
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not db_user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user"
        )
    
    # Create tokens
    access_token = AuthService.create_access_token(
        data={"sub": db_user.email}
    )
    refresh_token = AuthService.create_refresh_token(db, db_user.id)
    
    return APIResponse(
        success=True,
        message="Login successful",
        data={
            "user": {
                "id": db_user.id,
                "email": db_user.email,
                "name": db_user.name,
                "personality": db_user.personality,
                "timezone": db_user.timezone,
                "subscription_tier": db_user.subscription_tier
            },
            "tokens": {
                "access_token": access_token,
                "refresh_token": refresh_token,
                "token_type": "bearer"
            }
        }
    )

@router.post("/refresh", response_model=Token)
async def refresh_token(
    refresh_request: RefreshTokenRequest,
    db: Session = Depends(get_db)
):
    """Refresh access token"""
    user = AuthService.verify_refresh_token(db, refresh_request.refresh_token)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token"
        )
    
    # Create new tokens
    access_token = AuthService.create_access_token(
        data={"sub": user.email}
    )
    new_refresh_token = AuthService.create_refresh_token(db, user.id)
    
    return Token(
        access_token=access_token,
        refresh_token=new_refresh_token,
        token_type="bearer"
    )

@router.post("/logout", response_model=APIResponse)
async def logout(
    refresh_request: RefreshTokenRequest,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_active_user)
):
    """Logout user by revoking refresh token"""
    AuthService.revoke_refresh_token(db, refresh_request.refresh_token)
    
    return APIResponse(
        success=True,
        message="Logged out successfully"
    )

@router.get("/me", response_model=User)
async def read_users_me(
    current_user: UserModel = Depends(get_current_active_user)
):
    """Get current user profile"""
    return current_user

@router.put("/me", response_model=APIResponse)
async def update_profile(
    user_update: UserUpdate,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_active_user)
):
    """Update user profile"""
    try:
        # Update user fields
        for field, value in user_update.dict(exclude_unset=True).items():
            setattr(current_user, field, value)
        
        db.commit()
        db.refresh(current_user)
        
        return APIResponse(
            success=True,
            message="Profile updated successfully",
            data={
                "user": {
                    "id": current_user.id,
                    "email": current_user.email,
                    "name": current_user.name,
                    "personality": current_user.personality,
                    "timezone": current_user.timezone
                }
            }
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Profile update failed"
        )