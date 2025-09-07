from fastapi import APIRouter, Depends, HTTPException, status, Query, Request
from sqlalchemy.orm import Session
from sqlalchemy import and_, desc, func
from typing import List, Optional, Dict, Any
from datetime import datetime, date

from app.dependencies import get_db, get_current_active_user
from app.middleware.rate_limiter import limiter, RateLimits
from app.schemas import (
    ExcuseCreate, Excuse, RoastRequest, RoastResponse, 
    APIResponse, PersonalityResponse
)
from app.models import (
    User, Excuse as ExcuseModel, Roast as RoastModel,
    DailyTask as DailyTaskModel
)
from app.services.personality_service import PersonalityService

router = APIRouter()

@router.get("/personalities", response_model=List[PersonalityResponse])
async def get_personalities():
    """Get all available personalities"""
    ps = PersonalityService()
    personalities = ps.get_all_personalities()
    
    result = []
    for personality_type, personality_data in personalities.items():
        result.append(PersonalityResponse(
            type=personality_type,
            display_name=personality_data["name"],
            emoji=personality_data["emoji"],
            description=personality_data["description"],
            sample_roast=personality_data["sample_phrases"][0] if personality_data.get("sample_phrases") else ""
        ))
    
    return result

@router.post("/excuse", response_model=APIResponse)
@limiter.limit(RateLimits.EXCUSE_SUBMIT)
async def submit_excuse(
    request: Request,
    excuse: ExcuseCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Submit an excuse and get roasted for it"""
    try:
        # Verify task belongs to user if task_id provided
        if excuse.task_id:
            task = db.query(DailyTaskModel).filter(
                and_(
                    DailyTaskModel.id == excuse.task_id,
                    DailyTaskModel.user_id == current_user.id
                )
            ).first()
            
            if not task:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Task not found"
                )
        
        # Create excuse record
        db_excuse = ExcuseModel(
            user_id=current_user.id,
            excuse_text=excuse.excuse_text,
            excuse_category=excuse.excuse_category,
            task_id=excuse.task_id
        )
        
        db.add(db_excuse)
        db.commit()
        db.refresh(db_excuse)
        
        # Generate roast based on excuse
        ps = PersonalityService()
        personality = ps.get_personality(current_user.personality)
        
        context = {
            "excuse": excuse.excuse_text,
            "excuse_category": excuse.excuse_category,
            "user_name": current_user.name,
            "time_of_day": datetime.now().strftime("%H:%M")
        }
        
        # Get user's excuse history for context
        recent_excuses = db.query(ExcuseModel).filter(
            ExcuseModel.user_id == current_user.id
        ).order_by(desc(ExcuseModel.created_at)).limit(5).all()
        
        user_history = {
            "recent_excuses": [e.excuse_text for e in recent_excuses],
            "total_excuses": len(recent_excuses)
        }
        
        roast = personality.generate_response("excuse", context, user_history)
        
        # Save the roast
        db_roast = RoastModel(
            user_id=current_user.id,
            personality=current_user.personality,
            trigger_text=excuse.excuse_text,
            response_text=roast,
            is_shareable=True
        )
        
        db.add(db_roast)
        db.commit()
        
        return APIResponse(
            success=True,
            message="Excuse recorded. Prepare to be roasted! 🔥",
            data={
                "excuse": {
                    "id": db_excuse.id,
                    "excuse_text": db_excuse.excuse_text,
                    "category": db_excuse.excuse_category
                },
                "roast": {
                    "text": roast,
                    "personality": current_user.personality,
                    "shareable": True
                }
            }
        )
    except HTTPException as e:
        db.rollback()
        raise e
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to process excuse"
        )

@router.post("/generate", response_model=RoastResponse)
async def generate_roast(
    request: RoastRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Generate a custom roast"""
    try:
        ps = PersonalityService()
        personality = ps.get_personality(request.personality)
        
        roast = personality.generate_response("custom", request.context, request.user_history)
        
        # Save the roast
        db_roast = RoastModel(
            user_id=current_user.id,
            personality=request.personality,
            trigger_text=str(request.context),
            response_text=roast,
            is_shareable=True
        )
        
        db.add(db_roast)
        db.commit()
        
        return RoastResponse(
            roast=roast,
            personality=request.personality,
            shareable=True
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate roast"
        )

@router.get("/history", response_model=List[Excuse])
async def get_excuse_history(
    limit: int = Query(50, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Get user's excuse history"""
    excuses = db.query(ExcuseModel).filter(
        ExcuseModel.user_id == current_user.id
    ).order_by(desc(ExcuseModel.created_at)).limit(limit).all()
    
    return excuses

@router.get("/roasts", response_model=APIResponse)
async def get_roast_history(
    limit: int = Query(50, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Get user's roast history"""
    roasts = db.query(RoastModel).filter(
        RoastModel.user_id == current_user.id
    ).order_by(desc(RoastModel.created_at)).limit(limit).all()
    
    roast_data = []
    for roast in roasts:
        roast_data.append({
            "id": roast.id,
            "personality": roast.personality,
            "trigger_text": roast.trigger_text,
            "response_text": roast.response_text,
            "created_at": roast.created_at,
            "share_count": roast.share_count
        })
    
    return APIResponse(
        success=True,
        message=f"Here are your {len(roast_data)} most recent roasts",
        data={"roasts": roast_data}
    )

@router.post("/roasts/{roast_id}/share", response_model=APIResponse)
async def share_roast(
    roast_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Share a roast (increment share count)"""
    roast = db.query(RoastModel).filter(
        and_(
            RoastModel.id == roast_id,
            RoastModel.user_id == current_user.id,
            RoastModel.is_shareable == True
        )
    ).first()
    
    if not roast:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Roast not found or not shareable"
        )
    
    try:
        roast.share_count += 1
        db.commit()
        
        return APIResponse(
            success=True,
            message=f"Roast shared! Total shares: {roast.share_count}",
            data={"share_count": roast.share_count}
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to share roast"
        )

@router.get("/stats", response_model=APIResponse)
async def get_roast_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Get roast and excuse statistics"""
    try:
        # Count excuses by category
        excuse_stats = db.query(
            ExcuseModel.excuse_category,
            func.count(ExcuseModel.id).label('count')
        ).filter(
            ExcuseModel.user_id == current_user.id
        ).group_by(ExcuseModel.excuse_category).all()
        
        # Count roasts by personality
        roast_stats = db.query(
            RoastModel.personality,
            func.count(RoastModel.id).label('count')
        ).filter(
            RoastModel.user_id == current_user.id
        ).group_by(RoastModel.personality).all()
        
        # Total shares
        total_shares = db.query(
            func.sum(RoastModel.share_count)
        ).filter(
            RoastModel.user_id == current_user.id
        ).scalar() or 0
        
        return APIResponse(
            success=True,
            message="Your hall of shame statistics",
            data={
                "excuse_categories": {category: count for category, count in excuse_stats},
                "roast_personalities": {personality: count for personality, count in roast_stats},
                "total_excuses": sum([count for _, count in excuse_stats]),
                "total_roasts": sum([count for _, count in roast_stats]),
                "total_shares": total_shares
            }
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get statistics"
        )