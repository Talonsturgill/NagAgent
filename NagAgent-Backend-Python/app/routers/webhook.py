from fastapi import APIRouter, Request, Response, Depends
from sqlalchemy.orm import Session
from sqlalchemy import and_
from datetime import datetime, date
import re

from app.database import get_db
from app.models import User, Goal, DailyTask, Excuse, Roast
from app.services.twilio_service import TwilioService
from app.services.personality_service import PersonalityService
from app.services.openai_service import OpenAIService

router = APIRouter()
twilio_service = TwilioService()
personality_service = PersonalityService()
openai_service = OpenAIService()

@router.post("/whatsapp")
async def whatsapp_webhook(request: Request, db: Session = Depends(get_db)):
    """Handle incoming WhatsApp messages"""
    form_data = await request.form()
    webhook_data = twilio_service.validate_webhook(dict(form_data))
    
    from_number = webhook_data['from_number']
    message_body = webhook_data['message_body']
    
    try:
        # Get or create user
        user = db.query(User).filter(User.phone_number == from_number).first()
        
        if not user:
            # New user onboarding
            response_message = handle_new_user(db, from_number)
        else:
            # Existing user - route message based on context
            response_message = handle_existing_user(db, user, message_body)
        
        # Create TwiML response
        twiml_response = twilio_service.create_twiml_response(response_message)
        return Response(content=twiml_response, media_type="application/xml")
        
    except Exception as e:
        print(f"Error processing webhook: {str(e)}")
        error_response = twilio_service.create_twiml_response(
            "Oops! Something went wrong. Even I'm embarrassed by this technical failure. Try again?"
        )
        return Response(content=error_response, media_type="application/xml")

def handle_new_user(db: Session, phone_number: str) -> str:
    """Handle new user onboarding"""
    # Create new user
    user = User(phone_number=phone_number, last_command='ONBOARDING')
    db.add(user)
    db.commit()
    
    return """Welcome to NagAgent! 🎯

I'm here to roast you into productivity.

Choose your accountability style:
1️⃣ Sergeant - Military disappointment
2️⃣ Sassy - Toxic bestie energy  
3️⃣ Passive - Corporate disappointment
4️⃣ Brutal - No filter truth bombs

Reply with a number to choose your nagger!"""

def handle_existing_user(db: Session, user: User, message_body: str) -> str:
    """Handle messages from existing users"""
    # Update user activity
    user.last_active = datetime.now()
    
    # Handle personality selection during onboarding
    if user.last_command == 'ONBOARDING' and message_body in ['1', '2', '3', '4']:
        return handle_personality_selection(db, user, message_body)
    
    # Handle goal setting
    if user.last_command == 'SET_GOALS' or (',' in message_body and len(message_body.split(',')) > 1):
        return handle_goal_setting(db, user, message_body)
    
    # Handle specific commands
    command = message_body.upper().strip()
    
    if command == 'REPORT':
        return handle_daily_report(db, user)
    elif command in ['DONE', 'COMPLETED', 'FINISHED']:
        return handle_task_completion(db, user)
    elif command == 'HELP':
        return handle_help_command(user)
    elif command in ['GOALS', 'TASKS', 'TODO']:
        return handle_show_goals(db, user)
    else:
        # Treat as excuse or general message
        return handle_excuse_or_general(db, user, message_body)

def handle_personality_selection(db: Session, user: User, selection: str) -> str:
    """Handle personality selection during onboarding"""
    personalities = {
        '1': 'sergeant',
        '2': 'sassy', 
        '3': 'passive',
        '4': 'brutal'
    }
    
    user.personality = personalities[selection]
    user.last_command = 'SET_GOALS'
    db.commit()
    
    personality_info = personality_service.get_personality_info(user.personality)
    
    return f"""Perfect! Your personality is set to {personality_info['name']} {personality_info['emoji']}

Now, what are your goals for today?
Send them one by one, or all at once separated by commas.

Example: Go to gym, Finish project, Read 20 pages

Ready to disappoint me? 😈"""

def handle_goal_setting(db: Session, user: User, message_body: str) -> str:
    """Handle goal setting from user"""
    # Parse goals from message
    if ',' in message_body:
        goals = [g.strip() for g in message_body.split(',')]
    else:
        goals = [message_body.strip()]
    
    # Create goals and daily tasks
    created_goals = []
    for goal_text in goals:
        if goal_text and len(goal_text) > 0:
            # Create or get existing goal
            goal = db.query(Goal).filter(
                and_(Goal.user_id == user.id, Goal.goal_text == goal_text, Goal.archived_at.is_(None))
            ).first()
            
            if not goal:
                goal = Goal(user_id=user.id, goal_text=goal_text)
                db.add(goal)
                db.flush()
            
            # Create today's task
            existing_task = db.query(DailyTask).filter(
                and_(DailyTask.user_id == user.id, DailyTask.goal_id == goal.id, DailyTask.date == date.today())
            ).first()
            
            if not existing_task:
                task = DailyTask(user_id=user.id, goal_id=goal.id)
                db.add(task)
                created_goals.append(goal_text)
    
    user.last_command = 'ACTIVE'
    db.commit()
    
    # Generate morning nag
    morning_nag = personality_service.get_morning_nag(user.personality, created_goals)
    
    return morning_nag

def handle_daily_report(db: Session, user: User) -> str:
    """Generate daily accountability report"""
    today = date.today()
    
    # Get today's tasks
    tasks = db.query(DailyTask).filter(
        and_(DailyTask.user_id == user.id, DailyTask.date == today)
    ).all()
    
    # Calculate stats
    total_tasks = len(tasks)
    completed_tasks = len([t for t in tasks if t.completed])
    completion_rate = (completed_tasks / total_tasks * 100) if total_tasks > 0 else 0
    
    # Get excuse count
    excuse_count = db.query(Excuse).filter(
        and_(Excuse.user_id == user.id, Excuse.created_at >= datetime.combine(today, datetime.min.time()))
    ).count()
    
    # Calculate streak (simplified)
    streak = 0  # TODO: Implement proper streak calculation
    
    stats = {
        'completed': completed_tasks,
        'total': total_tasks,
        'excuses': excuse_count,
        'streak': streak,
        'rate': completion_rate / 100
    }
    
    # Generate report
    report = personality_service.get_daily_report(user.personality, stats)
    
    # Save roast
    roast = Roast(
        user_id=user.id,
        personality=user.personality,
        trigger_text="daily_report",
        response_text=report
    )
    db.add(roast)
    db.commit()
    
    return report

def handle_task_completion(db: Session, user: User) -> str:
    """Handle task completion"""
    today = date.today()
    
    # Find the most recent incomplete task
    task = db.query(DailyTask).filter(
        and_(
            DailyTask.user_id == user.id,
            DailyTask.date == today,
            DailyTask.completed == False
        )
    ).first()
    
    if not task:
        return "No incomplete tasks found. Either you're already perfect or you haven't set any goals. 🤔"
    
    # Mark as completed
    task.completed = True
    task.completed_at = datetime.now()
    db.commit()
    
    # Calculate completion rate
    all_tasks = db.query(DailyTask).filter(
        and_(DailyTask.user_id == user.id, DailyTask.date == today)
    ).all()
    
    completed_count = len([t for t in all_tasks if t.completed])
    completion_rate = completed_count / len(all_tasks)
    
    # Generate completion response
    response = personality_service.get_completion_response(user.personality, completion_rate)
    
    # Save roast
    roast = Roast(
        user_id=user.id,
        personality=user.personality,
        trigger_text=f"completed_{task.goal.goal_text}",
        response_text=response
    )
    db.add(roast)
    db.commit()
    
    return response

def handle_excuse_or_general(db: Session, user: User, message_body: str) -> str:
    """Handle excuse or general message"""
    # Categorize the excuse
    excuse_category = openai_service.categorize_excuse(message_body)
    
    # Save excuse
    excuse = Excuse(
        user_id=user.id,
        excuse_text=message_body,
        excuse_category=excuse_category
    )
    db.add(excuse)
    
    # Generate roast response
    response = personality_service.get_excuse_response(
        user.personality, 
        message_body, 
        "your goals"
    )
    
    # Save roast
    roast = Roast(
        user_id=user.id,
        personality=user.personality,
        trigger_text=message_body,
        response_text=response
    )
    db.add(roast)
    db.commit()
    
    return response

def handle_help_command(user: User) -> str:
    """Handle help command"""
    return """NagAgent Commands:

📋 GOALS - See your current goals
✅ DONE - Mark a task as complete  
📊 REPORT - Get your daily report
❓ HELP - Show this menu

Or just text me your excuses so I can roast them! 🔥

Your current personality: """ + personality_service.get_personality_info(user.personality)['name']

def handle_show_goals(db: Session, user: User) -> str:
    """Show user's current goals"""
    today = date.today()
    tasks = db.query(DailyTask).filter(
        and_(DailyTask.user_id == user.id, DailyTask.date == today)
    ).all()
    
    if not tasks:
        return "No goals set for today. The bar is literally underground and you're still not reaching it."
    
    goal_list = []
    for task in tasks:
        status = "✅" if task.completed else "❌"
        goal_list.append(f"{status} {task.goal.goal_text}")
    
    goals_text = '\n'.join(goal_list)
    completed = len([t for t in tasks if t.completed])
    total = len(tasks)
    
    return f"""Today's Goals ({completed}/{total} completed):

{goals_text}

{personality_service.get_completion_response(user.personality, completed/total)}"""