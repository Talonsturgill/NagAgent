from pydantic import BaseModel, EmailStr, validator
from typing import List, Optional, Dict, Any
from datetime import datetime, date

# Authentication Schemas
class UserRegister(BaseModel):
    email: EmailStr
    password: str
    name: str
    personality: str = 'sassy'
    timezone: str = 'America/New_York'
    
    @validator('password')
    def validate_password(cls, v):
        if len(v) < 6:
            raise ValueError('Password must be at least 6 characters long')
        return v

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

class TokenData(BaseModel):
    email: Optional[str] = None

class RefreshTokenRequest(BaseModel):
    refresh_token: str

# User Schemas
class UserBase(BaseModel):
    email: EmailStr
    name: Optional[str] = None
    personality: str = 'sassy'
    timezone: str = 'America/New_York'
    notification_times: List[str] = ["09:00", "14:00", "19:00"]
    subscription_tier: str = 'free'

class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    name: Optional[str] = None
    personality: Optional[str] = None
    timezone: Optional[str] = None
    notification_times: Optional[List[str]] = None

class User(UserBase):
    id: int
    is_active: bool
    is_verified: bool
    created_at: datetime
    last_active: datetime
    phone_number: Optional[str] = None

    class Config:
        from_attributes = True

class GoalBase(BaseModel):
    goal_text: str
    is_recurring: bool = True

class GoalCreate(GoalBase):
    pass

class Goal(GoalBase):
    id: int
    user_id: int
    created_at: datetime
    archived_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class DailyTaskBase(BaseModel):
    goal_id: int
    date: date
    completed: bool = False
    excuse_given: Optional[str] = None

class DailyTaskCreate(DailyTaskBase):
    pass

class DailyTask(DailyTaskBase):
    id: int
    user_id: int
    completed_at: Optional[datetime] = None
    created_at: datetime

    class Config:
        from_attributes = True

class ExcuseBase(BaseModel):
    excuse_text: str
    excuse_category: Optional[str] = None
    task_id: Optional[int] = None

class ExcuseCreate(ExcuseBase):
    pass

class Excuse(ExcuseBase):
    id: int
    user_id: int
    created_at: datetime

    class Config:
        from_attributes = True

class RoastBase(BaseModel):
    personality: str
    trigger_text: Optional[str] = None
    response_text: str
    is_shareable: bool = True

class RoastCreate(RoastBase):
    pass

class Roast(RoastBase):
    id: int
    user_id: int
    share_count: int
    created_at: datetime

    class Config:
        from_attributes = True

class RoastRequest(BaseModel):
    personality: str
    context: Dict[str, Any]
    user_history: Dict[str, Any]

class RoastResponse(BaseModel):
    roast: str
    personality: str
    shareable: bool = True

class DailyStatsResponse(BaseModel):
    date: date
    tasks_completed: int
    tasks_total: int
    completion_rate: float
    excuses_made: int
    current_streak: int
    ranking: Optional[int] = None
    roast: str

class GoalWithTasks(Goal):
    daily_tasks: List[DailyTask] = []

class UserProfile(User):
    goals: List[GoalWithTasks] = []
    total_goals: int = 0
    total_completed_tasks: int = 0
    current_streak: int = 0

class APIResponse(BaseModel):
    success: bool
    message: str
    data: Optional[Any] = None

class TaskUpdateRequest(BaseModel):
    completed: bool
    excuse_given: Optional[str] = None

class PersonalityResponse(BaseModel):
    type: str
    display_name: str
    emoji: str
    description: str
    sample_roast: str