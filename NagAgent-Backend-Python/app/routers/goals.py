from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import and_, func
from typing import List
from datetime import date, datetime

from app.dependencies import get_db, get_current_active_user
from app.schemas import (
    GoalCreate, Goal, GoalWithTasks, APIResponse, DailyTask
)
from app.models import User, Goal as GoalModel, DailyTask as DailyTaskModel

router = APIRouter()

@router.post("/", response_model=APIResponse)
async def create_goal(
    goal: GoalCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Create a new goal for the user"""
    try:
        db_goal = GoalModel(
            user_id=current_user.id,
            goal_text=goal.goal_text,
            is_recurring=goal.is_recurring
        )
        
        db.add(db_goal)
        db.commit()
        db.refresh(db_goal)
        
        # If recurring, create today's task
        if goal.is_recurring:
            today_task = DailyTaskModel(
                user_id=current_user.id,
                goal_id=db_goal.id,
                date=date.today()
            )
            db.add(today_task)
            db.commit()
        
        return APIResponse(
            success=True,
            message="Goal created successfully! Time to prove you won't give up on day 1.",
            data={
                "goal": {
                    "id": db_goal.id,
                    "goal_text": db_goal.goal_text,
                    "is_recurring": db_goal.is_recurring,
                    "created_at": db_goal.created_at
                }
            }
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create goal"
        )

@router.get("/", response_model=List[GoalWithTasks])
async def get_goals(
    include_archived: bool = False,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Get all goals for the current user"""
    query = db.query(GoalModel).filter(GoalModel.user_id == current_user.id)
    
    if not include_archived:
        query = query.filter(GoalModel.archived_at.is_(None))
    
    goals = query.order_by(GoalModel.created_at.desc()).all()
    
    # Get today's tasks for each goal
    today = date.today()
    result = []
    
    for goal in goals:
        # Get tasks for this goal (recent ones)
        tasks = db.query(DailyTaskModel).filter(
            and_(
                DailyTaskModel.goal_id == goal.id,
                DailyTaskModel.date >= today
            )
        ).order_by(DailyTaskModel.date.desc()).limit(7).all()
        
        goal_with_tasks = GoalWithTasks(
            id=goal.id,
            user_id=goal.user_id,
            goal_text=goal.goal_text,
            is_recurring=goal.is_recurring,
            created_at=goal.created_at,
            archived_at=goal.archived_at,
            daily_tasks=tasks
        )
        result.append(goal_with_tasks)
    
    return result

@router.get("/{goal_id}", response_model=GoalWithTasks)
async def get_goal(
    goal_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Get a specific goal with its tasks"""
    goal = db.query(GoalModel).filter(
        and_(
            GoalModel.id == goal_id,
            GoalModel.user_id == current_user.id
        )
    ).first()
    
    if not goal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Goal not found. Did you give up on it already?"
        )
    
    # Get all tasks for this goal
    tasks = db.query(DailyTaskModel).filter(
        DailyTaskModel.goal_id == goal_id
    ).order_by(DailyTaskModel.date.desc()).all()
    
    return GoalWithTasks(
        id=goal.id,
        user_id=goal.user_id,
        goal_text=goal.goal_text,
        is_recurring=goal.is_recurring,
        created_at=goal.created_at,
        archived_at=goal.archived_at,
        daily_tasks=tasks
    )

@router.put("/{goal_id}", response_model=APIResponse)
async def update_goal(
    goal_id: int,
    goal_update: GoalCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Update a goal"""
    goal = db.query(GoalModel).filter(
        and_(
            GoalModel.id == goal_id,
            GoalModel.user_id == current_user.id,
            GoalModel.archived_at.is_(None)
        )
    ).first()
    
    if not goal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Goal not found or already archived"
        )
    
    try:
        goal.goal_text = goal_update.goal_text
        goal.is_recurring = goal_update.is_recurring
        
        db.commit()
        db.refresh(goal)
        
        return APIResponse(
            success=True,
            message="Goal updated successfully. Let's see if you stick to this version.",
            data={
                "goal": {
                    "id": goal.id,
                    "goal_text": goal.goal_text,
                    "is_recurring": goal.is_recurring,
                    "created_at": goal.created_at
                }
            }
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update goal"
        )

@router.delete("/{goal_id}", response_model=APIResponse)
async def archive_goal(
    goal_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Archive a goal (soft delete)"""
    goal = db.query(GoalModel).filter(
        and_(
            GoalModel.id == goal_id,
            GoalModel.user_id == current_user.id,
            GoalModel.archived_at.is_(None)
        )
    ).first()
    
    if not goal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Goal not found or already archived"
        )
    
    try:
        goal.archived_at = datetime.utcnow()
        db.commit()
        
        return APIResponse(
            success=True,
            message="Goal archived successfully. Another one bites the dust! 🎵"
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to archive goal"
        )

@router.post("/{goal_id}/restore", response_model=APIResponse)
async def restore_goal(
    goal_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Restore an archived goal"""
    goal = db.query(GoalModel).filter(
        and_(
            GoalModel.id == goal_id,
            GoalModel.user_id == current_user.id,
            GoalModel.archived_at.is_not(None)
        )
    ).first()
    
    if not goal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Archived goal not found"
        )
    
    try:
        goal.archived_at = None
        
        # If recurring, create today's task if it doesn't exist
        if goal.is_recurring:
            today = date.today()
            existing_task = db.query(DailyTaskModel).filter(
                and_(
                    DailyTaskModel.goal_id == goal_id,
                    DailyTaskModel.date == today
                )
            ).first()
            
            if not existing_task:
                today_task = DailyTaskModel(
                    user_id=current_user.id,
                    goal_id=goal.id,
                    date=today
                )
                db.add(today_task)
        
        db.commit()
        
        return APIResponse(
            success=True,
            message="Goal restored! Ready for round 2 of disappointment?"
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to restore goal"
        )