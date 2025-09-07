from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import and_, func, desc
from typing import List, Optional
from datetime import date, datetime, timedelta

from app.dependencies import get_db, get_current_active_user
from app.schemas import (
    DailyTask, TaskUpdateRequest, APIResponse
)
from app.models import (
    User, DailyTask as DailyTaskModel, Goal as GoalModel
)
from app.services.personality_service import PersonalityService

router = APIRouter()

@router.get("/today", response_model=List[DailyTask])
async def get_today_tasks(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Get today's tasks for the current user"""
    today = date.today()
    
    # Get all active goals for the user
    active_goals = db.query(GoalModel).filter(
        and_(
            GoalModel.user_id == current_user.id,
            GoalModel.is_recurring == True,
            GoalModel.archived_at.is_(None)
        )
    ).all()
    
    # Create today's tasks if they don't exist
    for goal in active_goals:
        existing_task = db.query(DailyTaskModel).filter(
            and_(
                DailyTaskModel.goal_id == goal.id,
                DailyTaskModel.date == today
            )
        ).first()
        
        if not existing_task:
            task = DailyTaskModel(
                user_id=current_user.id,
                goal_id=goal.id,
                date=today
            )
            db.add(task)
    
    db.commit()
    
    # Get today's tasks
    tasks = db.query(DailyTaskModel).filter(
        and_(
            DailyTaskModel.user_id == current_user.id,
            DailyTaskModel.date == today
        )
    ).all()
    
    return tasks

@router.get("/", response_model=List[DailyTask])
async def get_tasks(
    start_date: Optional[date] = Query(None, description="Start date filter"),
    end_date: Optional[date] = Query(None, description="End date filter"),
    completed: Optional[bool] = Query(None, description="Filter by completion status"),
    limit: int = Query(50, le=100, description="Maximum number of tasks to return"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Get tasks for the current user with optional filters"""
    query = db.query(DailyTaskModel).filter(
        DailyTaskModel.user_id == current_user.id
    )
    
    if start_date:
        query = query.filter(DailyTaskModel.date >= start_date)
    
    if end_date:
        query = query.filter(DailyTaskModel.date <= end_date)
    
    if completed is not None:
        query = query.filter(DailyTaskModel.completed == completed)
    
    tasks = query.order_by(desc(DailyTaskModel.date)).limit(limit).all()
    return tasks

@router.get("/{task_id}", response_model=DailyTask)
async def get_task(
    task_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Get a specific task"""
    task = db.query(DailyTaskModel).filter(
        and_(
            DailyTaskModel.id == task_id,
            DailyTaskModel.user_id == current_user.id
        )
    ).first()
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found. Maybe you imagined it?"
        )
    
    return task

@router.put("/{task_id}", response_model=APIResponse)
async def update_task(
    task_id: int,
    task_update: TaskUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Update task completion status"""
    task = db.query(DailyTaskModel).filter(
        and_(
            DailyTaskModel.id == task_id,
            DailyTaskModel.user_id == current_user.id
        )
    ).first()
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found"
        )
    
    try:
        old_completed = task.completed
        task.completed = task_update.completed
        task.excuse_given = task_update.excuse_given
        
        if task_update.completed and not old_completed:
            task.completed_at = datetime.utcnow()
        elif not task_update.completed and old_completed:
            task.completed_at = None
        
        db.commit()
        db.refresh(task)
        
        # Generate appropriate response message
        if task_update.completed:
            message = "Task completed! Look who actually followed through for once! 🎉"
        else:
            message = "Task marked as incomplete. Back to the usual disappointment, I see."
        
        return APIResponse(
            success=True,
            message=message,
            data={
                "task": {
                    "id": task.id,
                    "completed": task.completed,
                    "completed_at": task.completed_at,
                    "excuse_given": task.excuse_given
                }
            }
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update task"
        )

@router.post("/{task_id}/complete", response_model=APIResponse)
async def complete_task(
    task_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Mark task as completed"""
    task = db.query(DailyTaskModel).filter(
        and_(
            DailyTaskModel.id == task_id,
            DailyTaskModel.user_id == current_user.id
        )
    ).first()
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found"
        )
    
    if task.completed:
        return APIResponse(
            success=True,
            message="Task was already completed. Trying to get double credit? Nice try."
        )
    
    try:
        task.completed = True
        task.completed_at = datetime.utcnow()
        db.commit()
        
        # Get a congratulatory roast
        ps = PersonalityService()
        personality = ps.get_personality(current_user.personality)
        
        context = {
            "task_completed": True,
            "goal_text": task.goal.goal_text,
            "completion_time": datetime.utcnow().strftime("%H:%M")
        }
        
        roast = personality.generate_response("task_completion", context, {})
        
        return APIResponse(
            success=True,
            message="Congratulations! You actually did it!",
            data={
                "task": {
                    "id": task.id,
                    "completed": task.completed,
                    "completed_at": task.completed_at
                },
                "roast": roast
            }
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to complete task"
        )

@router.get("/stats/streak", response_model=APIResponse)
async def get_streak(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Get current completion streak"""
    try:
        # Calculate current streak by checking consecutive days
        current_date = date.today()
        streak = 0
        check_date = current_date
        
        # Go back day by day until we find an incomplete day
        while True:
            # Get tasks for this date
            day_tasks = db.query(DailyTaskModel).filter(
                and_(
                    DailyTaskModel.user_id == current_user.id,
                    DailyTaskModel.date == check_date
                )
            ).all()
            
            if not day_tasks:
                # No tasks for this day, break if it's not today
                if check_date < current_date:
                    break
            else:
                # Check if all tasks were completed
                completed_tasks = [t for t in day_tasks if t.completed]
                if len(completed_tasks) == len(day_tasks) and len(day_tasks) > 0:
                    streak += 1
                else:
                    # Found an incomplete day
                    if check_date < current_date:
                        break
            
            check_date -= timedelta(days=1)
            
            # Don't go back more than 100 days
            if (current_date - check_date).days > 100:
                break
        
        # Get total stats
        total_tasks = db.query(DailyTaskModel).filter(
            DailyTaskModel.user_id == current_user.id
        ).count()
        
        completed_tasks = db.query(DailyTaskModel).filter(
            and_(
                DailyTaskModel.user_id == current_user.id,
                DailyTaskModel.completed == True
            )
        ).count()
        
        completion_rate = (completed_tasks / total_tasks * 100) if total_tasks > 0 else 0
        
        return APIResponse(
            success=True,
            message=f"Your current streak is {streak} days. {'Not bad!' if streak > 7 else 'Keep going!'}",
            data={
                "current_streak": streak,
                "total_tasks": total_tasks,
                "completed_tasks": completed_tasks,
                "completion_rate": round(completion_rate, 2)
            }
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to calculate streak"
        )