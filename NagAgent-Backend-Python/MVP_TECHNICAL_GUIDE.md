# NagAgent MVP - Technical Implementation Guide

## MVP Scope (2 Week Sprint)

### What We're Building
A WhatsApp/SMS bot that:
1. Onboards users with personality selection
2. Collects daily goals
3. Sends scheduled nags throughout the day
4. Tracks completion and generates responses
5. Creates shareable daily reports

### What We're NOT Building (Yet)
- Mobile app
- Voice messages
- Payment processing
- Social features
- Leaderboards
- Complex gamification

## Architecture Overview

```
User <-> WhatsApp/SMS <-> Twilio <-> FastAPI Backend <-> OpenAI
                                            |
                                      PostgreSQL DB
```

## Database Schema

```sql
-- Users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100),
    personality VARCHAR(20) DEFAULT 'sassy',
    timezone VARCHAR(50) DEFAULT 'America/New_York',
    notification_times JSONB DEFAULT '["09:00", "14:00", "19:00"]',
    subscription_tier VARCHAR(20) DEFAULT 'free',
    created_at TIMESTAMP DEFAULT NOW(),
    last_active TIMESTAMP DEFAULT NOW()
);

-- Goals table
CREATE TABLE goals (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    goal_text TEXT NOT NULL,
    is_recurring BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    archived_at TIMESTAMP
);

-- Daily tasks table
CREATE TABLE daily_tasks (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    goal_id INTEGER REFERENCES goals(id),
    date DATE DEFAULT CURRENT_DATE,
    completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMP,
    excuse_given TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Excuses tracking table
CREATE TABLE excuses (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    excuse_text TEXT NOT NULL,
    excuse_category VARCHAR(50),
    task_id INTEGER REFERENCES daily_tasks(id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Roasts table (for viral content)
CREATE TABLE roasts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    personality VARCHAR(20),
    trigger_text TEXT,
    response_text TEXT NOT NULL,
    is_shareable BOOLEAN DEFAULT true,
    share_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Analytics events table
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    event_type VARCHAR(50) NOT NULL,
    event_data JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);
```

## Backend Implementation (FastAPI)

### Project Structure
```
NagAgent/
├── app/
│   ├── __init__.py
│   ├── main.py           # FastAPI app
│   ├── database.py       # Database connection
│   ├── models.py         # SQLAlchemy models
│   ├── schemas.py        # Pydantic schemas
│   ├── routers/
│   │   ├── webhook.py    # Twilio webhook handler
│   │   ├── users.py      # User management
│   │   └── tasks.py      # Task management
│   ├── services/
│   │   ├── twilio_service.py
│   │   ├── openai_service.py
│   │   ├── personality_service.py
│   │   └── scheduler_service.py
│   ├── personalities/
│   │   ├── base.py
│   │   ├── sergeant.py
│   │   ├── sassy.py
│   │   ├── passive_aggressive.py
│   │   └── brutal.py
│   └── utils/
│       ├── constants.py
│       └── helpers.py
├── requirements.txt
├── .env
└── docker-compose.yml
```

### Core Code Files

**app/main.py**
```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import webhook, users, tasks
from app.database import engine, Base
from app.services.scheduler_service import start_scheduler

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="NagAgent API")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(webhook.router, prefix="/webhook", tags=["webhook"])
app.include_router(users.router, prefix="/users", tags=["users"])
app.include_router(tasks.router, prefix="/tasks", tags=["tasks"])

@app.on_event("startup")
async def startup_event():
    """Start the scheduler for automated nags"""
    start_scheduler()

@app.get("/")
async def root():
    return {"message": "NagAgent API is running. Stop procrastinating!"}
```

**app/services/personality_service.py**
```python
from typing import Dict, List
import random
from app.personalities import sergeant, sassy, passive_aggressive, brutal

class PersonalityService:
    def __init__(self):
        self.personalities = {
            'sergeant': sergeant.SergeantSlacker(),
            'sassy': sassy.SassySusan(),
            'passive': passive_aggressive.PassiveAggressivePat(),
            'brutal': brutal.BrutalBrandon()
        }
    
    def get_response(
        self, 
        personality: str, 
        context: str, 
        user_data: Dict
    ) -> str:
        """Get a response from the specified personality"""
        if personality not in self.personalities:
            personality = 'sassy'  # Default
        
        return self.personalities[personality].generate_response(
            context=context,
            user_data=user_data
        )
    
    def get_morning_nag(self, personality: str, tasks: List[str]) -> str:
        """Get morning motivation/threat"""
        return self.personalities[personality].morning_nag(tasks)
    
    def get_excuse_response(
        self, 
        personality: str, 
        excuse: str, 
        task: str
    ) -> str:
        """Respond to user excuse"""
        return self.personalities[personality].excuse_response(excuse, task)
    
    def get_completion_response(
        self, 
        personality: str, 
        completed_rate: float
    ) -> str:
        """Respond to task completion"""
        return self.personalities[personality].completion_response(
            completed_rate
        )
    
    def get_daily_report(
        self, 
        personality: str, 
        stats: Dict
    ) -> str:
        """Generate daily accountability report"""
        return self.personalities[personality].daily_report(stats)
```

**app/personalities/sassy.py**
```python
import random
from typing import Dict, List

class SassySusan:
    def __init__(self):
        self.name = "Sassy Susan"
        self.emoji = "😈"
        
    def morning_nag(self, tasks: List[str]) -> str:
        """Morning wake-up call"""
        intros = [
            "Morning bestie! Ready to disappoint both of us again? 💅",
            "Oh look who's up! Your bed must be devastated.",
            "Rise and grind? More like snooze and lose, but go off I guess.",
            "Good morning sunshine! JK it's cloudy because you haven't done anything yet.",
            "Wakey wakey! Time to procrastinate on these tasks! 💀"
        ]
        
        intro = random.choice(intros)
        task_count = len(tasks)
        
        if task_count == 0:
            return f"{intro}\n\nOh wait, you haven't even set any goals. The bar is literally underground and you're still limboing under it."
        elif task_count == 1:
            return f"{intro}\n\nYou literally have ONE thing to do today: {tasks[0]}\n\nOne. Thing. The drama when you don't do it... 🎭"
        else:
            task_list = '\n'.join([f"• {task}" for task in tasks])
            return f"{intro}\n\nToday's delusions of productivity:\n{task_list}\n\nCan't wait to see which one you'll blame Mercury retrograde for not doing! 💀"
    
    def excuse_response(self, excuse: str, task: str) -> str:
        """Respond to excuses"""
        excuse_lower = excuse.lower()
        
        responses = {
            'tired': [
                "Tired? The only thing tired here is this excuse, bestie.",
                "You had energy for TikTok but not for this? Make it make sense.",
                "Alexa, play 'Tired' by your excuses on repeat 💀"
            ],
            'busy': [
                "Busy? Your screen time says otherwise, hun.",
                "Too busy? I saw you watch 47 Instagram stories but okay.",
                "Busy doing everything except what matters? Groundbreaking."
            ],
            'tomorrow': [
                "Tomorrow? In this economy? Be serious.",
                "Oh tomorrow! Your favorite day that never comes!",
                "Tomorrow called, she's tired of your BS too."
            ],
            'forgot': [
                "Forgot? I'm literally here REMINDING you. The call is coming from inside the house!",
                "You forgot? Selective memory is giving main character energy.",
                "Forgot... but remembered to check your ex's story. Interesting."
            ]
        }
        
        # Check which excuse category matches
        for key, responses_list in responses.items():
            if key in excuse_lower:
                return random.choice(responses_list)
        
        # Default response for unrecognized excuses
        defaults = [
            f"'{excuse}'? That's creative! Still not doing '{task}' though.",
            f"New excuse just dropped! Unfortunately '{task}' still needs doing.",
            f"I'm adding '{excuse}' to your greatest hits album. Track 47.",
            "The creativity you put into excuses... imagine if you used it for actual work."
        ]
        
        return random.choice(defaults)
    
    def completion_response(self, completed_rate: float) -> str:
        """Response based on completion rate"""
        if completed_rate == 0:
            return random.choice([
                "Zero tasks completed? The consistency is admirable. Consistently terrible, but admirable. 💀",
                "Nothing? Absolutely nothing? Your potential is having a breakdown rn.",
                "0% completion rate? At least you're predictable! 🤡"
            ])
        elif completed_rate < 0.5:
            return random.choice([
                f"Only {completed_rate*100:.0f}%? This is giving participation trophy energy.",
                f"{completed_rate*100:.0f}% done? The bar was on the floor and you brought a shovel.",
                "You did some things! Your trophy is in the mail. JK it's not."
            ])
        elif completed_rate < 1.0:
            return random.choice([
                f"{completed_rate*100:.0f}%! Almost there! By 'there' I mean the bare minimum but progress!",
                "So close! Yet so committed to not quite making it.",
                "Almost perfect! Which is basically failing with extra steps but okay!"
            ])
        else:
            return random.choice([
                "WAIT. You actually did everything?! I'm shook. Literally clutching my pearls rn.",
                "100%?! Who are you and what did you do with my chronically procrastinating bestie?",
                "All tasks done? This is sus. Did someone hack your account? Blink twice if you need help."
            ])
    
    def daily_report(self, stats: Dict) -> str:
        """Generate sassy daily report"""
        completed = stats.get('completed', 0)
        total = stats.get('total', 1)
        excuses = stats.get('excuses', 0)
        streak = stats.get('streak', 0)
        
        rate = (completed / total * 100) if total > 0 else 0
        
        report = f"""
💅 DAILY VIBE CHECK 💅
{'-' * 25}
Tasks slayed: {completed}/{total} ({rate:.0f}%)
Excuses served: {excuses}
Current streak: {streak} days
{'-' * 25}
"""
        
        if rate == 0:
            report += "\nToday's mood: Flop era continues 💀"
        elif rate < 50:
            report += "\nToday's mood: Giving bare minimum"
        elif rate < 100:
            report += "\nToday's mood: Almost iconic"
        else:
            report += "\nToday's mood: SLAY ERA ACTIVATED ✨"
        
        if excuses > 5:
            report += f"\n\nP.S. {excuses} excuses? The creativity! The dedication to not doing things! Your excuse game is stronger than your work ethic and it shows."
        
        return report
```

**app/routers/webhook.py**
```python
from fastapi import APIRouter, Request, Response
from twilio.twiml.messaging_response import MessagingResponse
from app.services import twilio_service, personality_service
from app.database import SessionLocal
from app.models import User, DailyTask, Excuse
import re

router = APIRouter()

@router.post("/whatsapp")
async def whatsapp_webhook(request: Request):
    """Handle incoming WhatsApp messages"""
    form_data = await request.form()
    from_number = form_data.get('From', '').replace('whatsapp:', '')
    message_body = form_data.get('Body', '').strip()
    
    db = SessionLocal()
    response = MessagingResponse()
    
    try:
        # Get or create user
        user = db.query(User).filter(User.phone_number == from_number).first()
        
        if not user:
            # New user onboarding
            user = User(phone_number=from_number)
            db.add(user)
            db.commit()
            
            response.message(
                "Welcome to NagAgent! 🎯\n\n"
                "I'm here to roast you into productivity.\n\n"
                "Choose your accountability style:\n"
                "1️⃣ Sergeant - Military disappointment\n"
                "2️⃣ Sassy - Toxic bestie energy\n"
                "3️⃣ Passive - Corporate disappointment\n"
                "4️⃣ Brutal - No filter truth bombs\n\n"
                "Reply with a number to choose your nagger!"
            )
            return Response(content=str(response), media_type="application/xml")
        
        # Handle personality selection
        if message_body in ['1', '2', '3', '4']:
            personalities = {
                '1': 'sergeant',
                '2': 'sassy',
                '3': 'passive',
                '4': 'brutal'
            }
            user.personality = personalities[message_body]
            db.commit()
            
            response.message(
                f"Perfect! Your personality is set.\n\n"
                f"Now, what are your goals for today?\n"
                f"Send them one by one, or all at once separated by commas.\n\n"
                f"Example: Go to gym, Finish project, Read 20 pages"
            )
            return Response(content=str(response), media_type="application/xml")
        
        # Handle goal setting
        if ',' in message_body or user.last_command == 'SET_GOALS':
            goals = [g.strip() for g in message_body.split(',')]
            # Add goals to database
            for goal_text in goals:
                # Create goal and daily task
                pass  # Implementation here
            
            ps = personality_service.PersonalityService()
            nag = ps.get_morning_nag(user.personality, goals)
            response.message(nag)
            return Response(content=str(response), media_type="application/xml")
        
        # Handle commands
        if message_body.upper() == 'REPORT':
            # Generate daily report
            pass
        elif message_body.upper() == 'DONE':
            # Mark last task as complete
            pass
        else:
            # Treat as excuse or general message
            ps = personality_service.PersonalityService()
            roast = ps.get_excuse_response(
                user.personality, 
                message_body, 
                "your goals"
            )
            response.message(roast)
            
            # Save excuse to database
            excuse = Excuse(
                user_id=user.id,
                excuse_text=message_body
            )
            db.add(excuse)
            db.commit()
            
            return Response(content=str(response), media_type="application/xml")
        
    finally:
        db.close()
```

## OpenAI Integration

**app/services/openai_service.py**
```python
import openai
from typing import Dict
import os

openai.api_key = os.getenv("OPENAI_API_KEY")

class OpenAIService:
    def __init__(self):
        self.model = "gpt-4"
        
    def generate_response(
        self, 
        personality_prompt: str, 
        context: str, 
        user_history: Dict
    ) -> str:
        """Generate AI response based on personality and context"""
        
        system_prompt = f"""
        You are {personality_prompt}
        
        Your job is to motivate users through humor, sass, and tough love.
        Be funny enough that users want to screenshot and share your responses.
        Stay in character at all times.
        Maximum 2-3 sentences per response.
        Use appropriate emojis occasionally.
        """
        
        user_prompt = f"""
        Context: {context}
        User's recent completion rate: {user_history.get('completion_rate', 0)}%
        User's common excuses: {user_history.get('common_excuses', [])}
        
        Generate a response that:
        1. Addresses their current situation
        2. Is funny/savage enough to share
        3. Still motivates them to take action
        """
        
        response = openai.ChatCompletion.create(
            model=self.model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            max_tokens=150,
            temperature=0.8
        )
        
        return response.choices[0].message.content
    
    def categorize_excuse(self, excuse_text: str) -> str:
        """Categorize user excuse for analytics"""
        prompt = f"""
        Categorize this excuse into one of these categories:
        - tired
        - busy
        - forgot
        - tomorrow
        - sick
        - unmotivated
        - external (blame others/circumstances)
        - other
        
        Excuse: "{excuse_text}"
        
        Return only the category name.
        """
        
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[{"role": "user", "content": prompt}],
            max_tokens=10,
            temperature=0
        )
        
        return response.choices[0].message.content.strip().lower()
```

## Scheduler Service

**app/services/scheduler_service.py**
```python
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from datetime import datetime
import pytz
from app.database import SessionLocal
from app.models import User, DailyTask
from app.services import twilio_service, personality_service

scheduler = AsyncIOScheduler()

def start_scheduler():
    """Initialize and start the scheduler"""
    scheduler.add_job(
        send_morning_nags,
        'cron',
        hour=9,
        minute=0,
        id='morning_nags'
    )
    
    scheduler.add_job(
        send_afternoon_checkup,
        'cron',
        hour=14,
        minute=0,
        id='afternoon_checkup'
    )
    
    scheduler.add_job(
        send_evening_report,
        'cron',
        hour=20,
        minute=0,
        id='evening_report'
    )
    
    scheduler.start()

async def send_morning_nags():
    """Send morning motivation/threats to all users"""
    db = SessionLocal()
    ps = personality_service.PersonalityService()
    ts = twilio_service.TwilioService()
    
    try:
        # Get all active users
        users = db.query(User).filter(User.is_active == True).all()
        
        for user in users:
            # Get today's tasks
            tasks = db.query(DailyTask).filter(
                DailyTask.user_id == user.id,
                DailyTask.date == datetime.now().date()
            ).all()
            
            if tasks:
                task_texts = [t.goal.goal_text for t in tasks]
                message = ps.get_morning_nag(user.personality, task_texts)
                ts.send_whatsapp(user.phone_number, message)
    
    finally:
        db.close()

async def send_afternoon_checkup():
    """Send afternoon progress check"""
    # Similar implementation
    pass

async def send_evening_report():
    """Send daily accountability report"""
    # Similar implementation
    pass
```

## Environment Variables (.env)

```env
# Twilio Configuration
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_WHATSAPP_NUMBER=whatsapp:+14155238886
TWILIO_SMS_NUMBER=+1234567890

# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key

# Database Configuration
DATABASE_URL=postgresql://user:password@localhost/nagagent

# App Configuration
SECRET_KEY=your-secret-key-here
ENVIRONMENT=development
DEBUG=True

# Redis Configuration (for rate limiting)
REDIS_URL=redis://localhost:6379
```

## Deployment Guide

### Local Development

1. **Setup Python Environment**
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

2. **Setup PostgreSQL**
```bash
# Using Docker
docker run --name nagagent-db -e POSTGRES_PASSWORD=password -p 5432:5432 -d postgres
```

3. **Setup Ngrok for WhatsApp Testing**
```bash
ngrok http 8000
# Copy the HTTPS URL for Twilio webhook configuration
```

4. **Run the Application**
```bash
uvicorn app.main:app --reload --port 8000
```

### Production Deployment (Railway/Render)

1. **Prepare for Deployment**
```bash
# Add Procfile
echo "web: uvicorn app.main:app --host 0.0.0.0 --port $PORT" > Procfile

# Add runtime.txt
echo "python-3.11.0" > runtime.txt
```

2. **Deploy to Railway**
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login and initialize
railway login
railway init

# Deploy
railway up
```

3. **Configure Environment Variables**
- Add all variables from .env to Railway dashboard
- Set up PostgreSQL addon
- Configure domain for webhooks

## Testing Strategy

### Unit Tests
```python
# tests/test_personalities.py
import pytest
from app.personalities.sassy import SassySusan

def test_sassy_morning_nag():
    sassy = SassySusan()
    tasks = ["Go to gym", "Finish project"]
    response = sassy.morning_nag(tasks)
    
    assert len(response) > 0
    assert any(word in response.lower() for word in ['bestie', 'hun', 'babe'])
    assert any(task in response for task in tasks)

def test_sassy_excuse_response():
    sassy = SassySusan()
    response = sassy.excuse_response("I'm too tired", "go to gym")
    
    assert len(response) > 0
    assert 'tired' in response.lower() or 'excuse' in response.lower()
```

### Integration Tests
```python
# tests/test_webhook.py
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_new_user_onboarding():
    response = client.post(
        "/webhook/whatsapp",
        data={
            "From": "whatsapp:+1234567890",
            "Body": "Hi"
        }
    )
    
    assert response.status_code == 200
    assert "Welcome to NagAgent" in response.text
```

## Launch Checklist

### Week 1: Development
- [ ] Set up development environment
- [ ] Implement basic personality responses
- [ ] Create WhatsApp webhook handler
- [ ] Build user onboarding flow
- [ ] Implement goal tracking
- [ ] Create daily report generation
- [ ] Test with 10 friends

### Week 2: Beta Testing
- [ ] Deploy to production
- [ ] Get 50 beta users from Reddit
- [ ] Collect feedback and iterate
- [ ] Fix critical bugs
- [ ] Gather best roasts for marketing
- [ ] Create sharing mechanism
- [ ] Prepare launch content

### Launch Day
- [ ] Post on ProductHunt
- [ ] Launch TikTok campaign
- [ ] Post in Reddit communities
- [ ] Send to press contacts
- [ ] Monitor and respond to feedback
- [ ] Track metrics
- [ ] Celebrate! (Then get back to work, you procrastinator)

---

*"This documentation is longer than your attention span. Just start coding already!"*
- Brutal Brandon