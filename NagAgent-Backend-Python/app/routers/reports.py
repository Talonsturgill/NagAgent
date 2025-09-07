from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import and_, func, desc
from typing import List, Optional, Dict
from datetime import datetime, date, timedelta

from app.dependencies import get_db, get_current_active_user
from app.schemas import DailyStatsResponse, APIResponse
from app.models import (
    User, DailyTask as DailyTaskModel, Excuse as ExcuseModel,
    Goal as GoalModel
)
from app.services.personality_service import PersonalityService

router = APIRouter()

@router.get("/daily", response_model=DailyStatsResponse)
async def get_daily_report(
    report_date: Optional[date] = Query(None, description="Date for the report (defaults to today)"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Generate daily report for a specific date"""
    if report_date is None:
        report_date = date.today()
    
    try:
        # Get tasks for the date
        day_tasks = db.query(DailyTaskModel).filter(
            and_(
                DailyTaskModel.user_id == current_user.id,
                DailyTaskModel.date == report_date
            )
        ).all()
        
        tasks_total = len(day_tasks)
        tasks_completed = len([t for t in day_tasks if t.completed])
        completion_rate = (tasks_completed / tasks_total * 100) if tasks_total > 0 else 0
        
        # Get excuses for the date
        excuses_made = db.query(ExcuseModel).filter(
            and_(
                ExcuseModel.user_id == current_user.id,
                func.date(ExcuseModel.created_at) == report_date
            )
        ).count()
        
        # Calculate current streak
        current_streak = await _calculate_streak(db, current_user.id, report_date)
        
        # Generate daily roast based on performance
        ps = PersonalityService()
        personality = ps.get_personality(current_user.personality)
        
        context = {
            "date": report_date.strftime("%Y-%m-%d"),
            "tasks_completed": tasks_completed,
            "tasks_total": tasks_total,
            "completion_rate": completion_rate,
            "excuses_made": excuses_made,
            "current_streak": current_streak,
            "user_name": current_user.name
        }
        
        user_history = {
            "recent_performance": await _get_recent_performance(db, current_user.id, 7)
        }
        
        roast = personality.generate_response("daily_report", context, user_history)
        
        return DailyStatsResponse(
            date=report_date,
            tasks_completed=tasks_completed,
            tasks_total=tasks_total,
            completion_rate=round(completion_rate, 2),
            excuses_made=excuses_made,
            current_streak=current_streak,
            roast=roast
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate daily report"
        )

@router.get("/weekly", response_model=APIResponse)
async def get_weekly_report(
    week_start: Optional[date] = Query(None, description="Start date of the week"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Generate weekly report"""
    if week_start is None:
        # Get start of current week (Monday)
        today = date.today()
        week_start = today - timedelta(days=today.weekday())
    
    week_end = week_start + timedelta(days=6)
    
    try:
        # Get weekly stats
        weekly_tasks = db.query(DailyTaskModel).filter(
            and_(
                DailyTaskModel.user_id == current_user.id,
                DailyTaskModel.date >= week_start,
                DailyTaskModel.date <= week_end
            )
        ).all()
        
        # Group by day
        daily_stats = {}
        for day_offset in range(7):
            current_day = week_start + timedelta(days=day_offset)
            day_tasks = [t for t in weekly_tasks if t.date == current_day]
            completed_tasks = [t for t in day_tasks if t.completed]
            
            daily_stats[current_day.strftime("%Y-%m-%d")] = {
                "total": len(day_tasks),
                "completed": len(completed_tasks),
                "completion_rate": (len(completed_tasks) / len(day_tasks) * 100) if day_tasks else 0
            }
        
        # Overall weekly stats
        total_tasks = len(weekly_tasks)
        completed_tasks = len([t for t in weekly_tasks if t.completed])
        weekly_completion_rate = (completed_tasks / total_tasks * 100) if total_tasks > 0 else 0
        
        # Weekly excuses
        weekly_excuses = db.query(ExcuseModel).filter(
            and_(
                ExcuseModel.user_id == current_user.id,
                func.date(ExcuseModel.created_at) >= week_start,
                func.date(ExcuseModel.created_at) <= week_end
            )
        ).count()
        
        # Generate weekly roast
        ps = PersonalityService()
        personality = ps.get_personality(current_user.personality)
        
        context = {
            "week_start": week_start.strftime("%Y-%m-%d"),
            "week_end": week_end.strftime("%Y-%m-%d"),
            "total_tasks": total_tasks,
            "completed_tasks": completed_tasks,
            "weekly_completion_rate": weekly_completion_rate,
            "weekly_excuses": weekly_excuses,
            "best_day": max(daily_stats.items(), key=lambda x: x[1]["completion_rate"])[0] if daily_stats else None,
            "worst_day": min(daily_stats.items(), key=lambda x: x[1]["completion_rate"])[0] if daily_stats else None
        }
        
        roast = personality.generate_response("weekly_report", context, {})
        
        return APIResponse(
            success=True,
            message="Your weekly performance review",
            data={
                "week_period": f"{week_start} to {week_end}",
                "overall_stats": {
                    "total_tasks": total_tasks,
                    "completed_tasks": completed_tasks,
                    "completion_rate": round(weekly_completion_rate, 2),
                    "total_excuses": weekly_excuses
                },
                "daily_breakdown": daily_stats,
                "roast": roast
            }
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate weekly report"
        )

@router.get("/monthly", response_model=APIResponse)
async def get_monthly_report(
    year: int = Query(None, description="Year for the report"),
    month: int = Query(None, description="Month for the report (1-12)"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Generate monthly report"""
    if year is None:
        year = date.today().year
    if month is None:
        month = date.today().month
    
    # Get first and last day of the month
    month_start = date(year, month, 1)
    if month == 12:
        month_end = date(year + 1, 1, 1) - timedelta(days=1)
    else:
        month_end = date(year, month + 1, 1) - timedelta(days=1)
    
    try:
        # Get monthly tasks
        monthly_tasks = db.query(DailyTaskModel).filter(
            and_(
                DailyTaskModel.user_id == current_user.id,
                DailyTaskModel.date >= month_start,
                DailyTaskModel.date <= month_end
            )
        ).all()
        
        total_tasks = len(monthly_tasks)
        completed_tasks = len([t for t in monthly_tasks if t.completed])
        monthly_completion_rate = (completed_tasks / total_tasks * 100) if total_tasks > 0 else 0
        
        # Monthly excuses
        monthly_excuses = db.query(ExcuseModel).filter(
            and_(
                ExcuseModel.user_id == current_user.id,
                func.date(ExcuseModel.created_at) >= month_start,
                func.date(ExcuseModel.created_at) <= month_end
            )
        ).count()
        
        # Calculate streaks in the month
        best_streak = await _calculate_best_streak_in_period(
            db, current_user.id, month_start, month_end
        )
        
        # Goals created/completed in month
        monthly_goals = db.query(GoalModel).filter(
            and_(
                GoalModel.user_id == current_user.id,
                func.date(GoalModel.created_at) >= month_start,
                func.date(GoalModel.created_at) <= month_end
            )
        ).count()
        
        # Generate monthly roast
        ps = PersonalityService()
        personality = ps.get_personality(current_user.personality)
        
        context = {
            "month": month_start.strftime("%B %Y"),
            "total_tasks": total_tasks,
            "completed_tasks": completed_tasks,
            "monthly_completion_rate": monthly_completion_rate,
            "monthly_excuses": monthly_excuses,
            "best_streak": best_streak,
            "new_goals": monthly_goals
        }
        
        roast = personality.generate_response("monthly_report", context, {})
        
        return APIResponse(
            success=True,
            message=f"Your {month_start.strftime('%B %Y')} performance summary",
            data={
                "month": month_start.strftime("%B %Y"),
                "stats": {
                    "total_tasks": total_tasks,
                    "completed_tasks": completed_tasks,
                    "completion_rate": round(monthly_completion_rate, 2),
                    "total_excuses": monthly_excuses,
                    "best_streak": best_streak,
                    "new_goals": monthly_goals
                },
                "roast": roast
            }
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate monthly report"
        )

@router.get("/overview", response_model=APIResponse)
async def get_overview(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Get overall account statistics and insights"""
    try:
        # Overall stats
        total_goals = db.query(GoalModel).filter(
            GoalModel.user_id == current_user.id
        ).count()
        
        active_goals = db.query(GoalModel).filter(
            and_(
                GoalModel.user_id == current_user.id,
                GoalModel.archived_at.is_(None)
            )
        ).count()
        
        total_tasks = db.query(DailyTaskModel).filter(
            DailyTaskModel.user_id == current_user.id
        ).count()
        
        completed_tasks = db.query(DailyTaskModel).filter(
            and_(
                DailyTaskModel.user_id == current_user.id,
                DailyTaskModel.completed == True
            )
        ).count()
        
        total_excuses = db.query(ExcuseModel).filter(
            ExcuseModel.user_id == current_user.id
        ).count()
        
        overall_completion_rate = (completed_tasks / total_tasks * 100) if total_tasks > 0 else 0
        
        # Current streak
        current_streak = await _calculate_streak(db, current_user.id, date.today())
        
        # Days since account creation
        days_active = (date.today() - current_user.created_at.date()).days + 1
        
        return APIResponse(
            success=True,
            message="Your complete NagAgent journey so far",
            data={
                "account_info": {
                    "member_since": current_user.created_at.date(),
                    "days_active": days_active,
                    "personality": current_user.personality,
                    "subscription_tier": current_user.subscription_tier
                },
                "goals": {
                    "total": total_goals,
                    "active": active_goals,
                    "archived": total_goals - active_goals
                },
                "tasks": {
                    "total": total_tasks,
                    "completed": completed_tasks,
                    "completion_rate": round(overall_completion_rate, 2)
                },
                "accountability": {
                    "total_excuses": total_excuses,
                    "current_streak": current_streak,
                    "excuses_per_task": round(total_excuses / total_tasks, 2) if total_tasks > 0 else 0
                }
            }
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate overview"
        )

# Helper functions
async def _calculate_streak(db: Session, user_id: int, end_date: date) -> int:
    """Calculate current streak up to end_date"""
    streak = 0
    check_date = end_date
    
    while True:
        day_tasks = db.query(DailyTaskModel).filter(
            and_(
                DailyTaskModel.user_id == user_id,
                DailyTaskModel.date == check_date
            )
        ).all()
        
        if not day_tasks:
            if check_date < end_date:
                break
        else:
            completed_tasks = [t for t in day_tasks if t.completed]
            if len(completed_tasks) == len(day_tasks):
                streak += 1
            else:
                if check_date < end_date:
                    break
        
        check_date -= timedelta(days=1)
        
        if (end_date - check_date).days > 100:
            break
    
    return streak

async def _calculate_best_streak_in_period(
    db: Session, user_id: int, start_date: date, end_date: date
) -> int:
    """Calculate the best streak within a date range"""
    best_streak = 0
    current_streak = 0
    check_date = start_date
    
    while check_date <= end_date:
        day_tasks = db.query(DailyTaskModel).filter(
            and_(
                DailyTaskModel.user_id == user_id,
                DailyTaskModel.date == check_date
            )
        ).all()
        
        if day_tasks:
            completed_tasks = [t for t in day_tasks if t.completed]
            if len(completed_tasks) == len(day_tasks):
                current_streak += 1
                best_streak = max(best_streak, current_streak)
            else:
                current_streak = 0
        else:
            current_streak = 0
        
        check_date += timedelta(days=1)
    
    return best_streak

async def _get_recent_performance(db: Session, user_id: int, days: int) -> List[Dict]:
    """Get performance data for the last N days"""
    performance = []
    today = date.today()
    
    for i in range(days):
        check_date = today - timedelta(days=i)
        day_tasks = db.query(DailyTaskModel).filter(
            and_(
                DailyTaskModel.user_id == user_id,
                DailyTaskModel.date == check_date
            )
        ).all()
        
        total = len(day_tasks)
        completed = len([t for t in day_tasks if t.completed])
        
        performance.append({
            "date": check_date.strftime("%Y-%m-%d"),
            "total_tasks": total,
            "completed_tasks": completed,
            "completion_rate": (completed / total * 100) if total > 0 else 0
        })
    
    return performance