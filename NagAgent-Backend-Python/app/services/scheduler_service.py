from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from datetime import datetime, date
import pytz
import asyncio
from sqlalchemy.orm import sessionmaker
from sqlalchemy import and_

from app.database import engine
from app.models import User, DailyTask, Goal
from app.services.twilio_service import TwilioService
from app.services.personality_service import PersonalityService

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

scheduler = AsyncIOScheduler()
twilio_service = TwilioService()
personality_service = PersonalityService()

def start_scheduler():
    """Initialize and start the scheduler"""
    # Morning nags at 9 AM
    scheduler.add_job(
        send_morning_nags,
        CronTrigger(hour=9, minute=0),
        id='morning_nags',
        replace_existing=True
    )
    
    # Afternoon check-ins at 2 PM
    scheduler.add_job(
        send_afternoon_checkup,
        CronTrigger(hour=14, minute=0),
        id='afternoon_checkup',
        replace_existing=True
    )
    
    # Evening reports at 8 PM
    scheduler.add_job(
        send_evening_report,
        CronTrigger(hour=20, minute=0),
        id='evening_report',
        replace_existing=True
    )
    
    # Create daily tasks at midnight
    scheduler.add_job(
        create_daily_tasks,
        CronTrigger(hour=0, minute=1),
        id='create_daily_tasks',
        replace_existing=True
    )
    
    try:
        scheduler.start()
        print("Scheduler started successfully")
    except Exception as e:
        print(f"Failed to start scheduler: {str(e)}")

def send_morning_nags():
    """Send morning motivation/threats to all users"""
    db = SessionLocal()
    
    try:
        # Get all active users
        users = db.query(User).filter(User.is_active == True).all()
        print(f"Sending morning nags to {len(users)} users")
        
        for user in users:
            try:
                # Get today's tasks
                today = date.today()
                tasks = db.query(DailyTask).join(Goal).filter(
                    and_(
                        DailyTask.user_id == user.id,
                        DailyTask.date == today,
                        Goal.archived_at.is_(None)
                    )
                ).all()
                
                if tasks:
                    task_texts = [task.goal.goal_text for task in tasks]
                    message = personality_service.get_morning_nag(user.personality, task_texts)
                    
                    # Send message
                    success = twilio_service.send_whatsapp(user.phone_number, message)
                    
                    if success:
                        print(f"Morning nag sent to {user.phone_number}")
                    else:
                        print(f"Failed to send morning nag to {user.phone_number}")
                        
            except Exception as e:
                print(f"Error sending morning nag to {user.phone_number}: {str(e)}")
                continue
    
    except Exception as e:
        print(f"Error in send_morning_nags: {str(e)}")
    finally:
        db.close()

def send_afternoon_checkup():
    """Send afternoon progress check"""
    db = SessionLocal()
    
    try:
        users = db.query(User).filter(User.is_active == True).all()
        print(f"Sending afternoon checkups to {len(users)} users")
        
        for user in users:
            try:
                today = date.today()
                tasks = db.query(DailyTask).filter(
                    and_(DailyTask.user_id == user.id, DailyTask.date == today)
                ).all()
                
                if tasks:
                    completed = len([t for t in tasks if t.completed])
                    total = len(tasks)
                    completion_rate = completed / total
                    
                    # Generate different messages based on progress
                    if completion_rate == 0:
                        messages = {
                            'sergeant': "SOLDIER! Zero progress detected! Time to MOVE!",
                            'sassy': "Bestie... it's 2 PM and you've done NOTHING. The drama.",
                            'passive': "Just checking in! No progress yet, but that's... fine.",
                            'brutal': "Halfway through the day, zero progress. Predictable."
                        }
                    elif completion_rate < 0.5:
                        messages = {
                            'sergeant': f"PROGRESS REPORT: {completed}/{total} completed. PICK UP THE PACE!",
                            'sassy': f"You did {completed} things! That's... something, I guess.",
                            'passive': f"Some progress made: {completed}/{total}. How... nice.",
                            'brutal': f"{completed}/{total} done. Mediocrity in action."
                        }
                    else:
                        messages = {
                            'sergeant': f"OUTSTANDING! {completed}/{total} completed! KEEP GOING!",
                            'sassy': f"{completed}/{total} done?! Who are you and what did you do with my lazy bestie?",
                            'passive': f"Impressive progress: {completed}/{total}. I'm... surprised.",
                            'brutal': f"{completed}/{total} completed. Acceptable progress, for once."
                        }
                    
                    message = messages.get(user.personality, messages['sassy'])
                    twilio_service.send_whatsapp(user.phone_number, message)
                    
            except Exception as e:
                print(f"Error sending afternoon checkup to {user.phone_number}: {str(e)}")
                continue
    
    except Exception as e:
        print(f"Error in send_afternoon_checkup: {str(e)}")
    finally:
        db.close()

def send_evening_report():
    """Send daily accountability report"""
    db = SessionLocal()
    
    try:
        users = db.query(User).filter(User.is_active == True).all()
        print(f"Sending evening reports to {len(users)} users")
        
        for user in users:
            try:
                today = date.today()
                tasks = db.query(DailyTask).filter(
                    and_(DailyTask.user_id == user.id, DailyTask.date == today)
                ).all()
                
                if tasks:
                    completed = len([t for t in tasks if t.completed])
                    total = len(tasks)
                    
                    # Get excuse count for today
                    from app.models import Excuse
                    excuse_count = db.query(Excuse).filter(
                        and_(
                            Excuse.user_id == user.id,
                            Excuse.created_at >= datetime.combine(today, datetime.min.time())
                        )
                    ).count()
                    
                    stats = {
                        'completed': completed,
                        'total': total,
                        'excuses': excuse_count,
                        'streak': 0  # TODO: Calculate actual streak
                    }
                    
                    report = personality_service.get_daily_report(user.personality, stats)
                    twilio_service.send_whatsapp(user.phone_number, report)
                    
            except Exception as e:
                print(f"Error sending evening report to {user.phone_number}: {str(e)}")
                continue
    
    except Exception as e:
        print(f"Error in send_evening_report: {str(e)}")
    finally:
        db.close()

def create_daily_tasks():
    """Create daily tasks for all users based on their recurring goals"""
    db = SessionLocal()
    
    try:
        # Get all active users with recurring goals
        users = db.query(User).filter(User.is_active == True).all()
        today = date.today()
        
        print(f"Creating daily tasks for {len(users)} users")
        
        for user in users:
            try:
                # Get user's recurring goals
                recurring_goals = db.query(Goal).filter(
                    and_(
                        Goal.user_id == user.id,
                        Goal.is_recurring == True,
                        Goal.archived_at.is_(None)
                    )
                ).all()
                
                for goal in recurring_goals:
                    # Check if task already exists for today
                    existing_task = db.query(DailyTask).filter(
                        and_(
                            DailyTask.user_id == user.id,
                            DailyTask.goal_id == goal.id,
                            DailyTask.date == today
                        )
                    ).first()
                    
                    if not existing_task:
                        # Create new daily task
                        task = DailyTask(
                            user_id=user.id,
                            goal_id=goal.id,
                            date=today
                        )
                        db.add(task)
                
                db.commit()
                
            except Exception as e:
                print(f"Error creating daily tasks for {user.phone_number}: {str(e)}")
                db.rollback()
                continue
    
    except Exception as e:
        print(f"Error in create_daily_tasks: {str(e)}")
    finally:
        db.close()

def stop_scheduler():
    """Stop the scheduler"""
    if scheduler.running:
        scheduler.shutdown()
        print("Scheduler stopped")