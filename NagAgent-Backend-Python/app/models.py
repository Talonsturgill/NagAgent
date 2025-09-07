from sqlalchemy import Column, Integer, String, Text, Boolean, DateTime, Date, ForeignKey, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    hashed_password = Column(String(255), nullable=False)
    name = Column(String(100))
    personality = Column(String(20), default='sassy')
    timezone = Column(String(50), default='America/New_York')
    notification_times = Column(JSON, default=["09:00", "14:00", "19:00"])
    subscription_tier = Column(String(20), default='free')
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    last_command = Column(String(50))
    created_at = Column(DateTime, default=func.now())
    last_active = Column(DateTime, default=func.now())
    
    # Keep phone number for legacy support (optional for iOS)
    phone_number = Column(String(20), unique=True, nullable=True, index=True)

    # Relationships
    goals = relationship("Goal", back_populates="user")
    daily_tasks = relationship("DailyTask", back_populates="user")
    excuses = relationship("Excuse", back_populates="user")
    roasts = relationship("Roast", back_populates="user")

class Goal(Base):
    __tablename__ = "goals"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    goal_text = Column(Text, nullable=False)
    is_recurring = Column(Boolean, default=True)
    created_at = Column(DateTime, default=func.now())
    archived_at = Column(DateTime)

    # Relationships
    user = relationship("User", back_populates="goals")
    daily_tasks = relationship("DailyTask", back_populates="goal")

class DailyTask(Base):
    __tablename__ = "daily_tasks"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    goal_id = Column(Integer, ForeignKey("goals.id"), nullable=False)
    date = Column(Date, default=func.current_date())
    completed = Column(Boolean, default=False)
    completed_at = Column(DateTime)
    excuse_given = Column(Text)
    created_at = Column(DateTime, default=func.now())

    # Relationships
    user = relationship("User", back_populates="daily_tasks")
    goal = relationship("Goal", back_populates="daily_tasks")
    excuses = relationship("Excuse", back_populates="task")

class Excuse(Base):
    __tablename__ = "excuses"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    excuse_text = Column(Text, nullable=False)
    excuse_category = Column(String(50))
    task_id = Column(Integer, ForeignKey("daily_tasks.id"))
    created_at = Column(DateTime, default=func.now())

    # Relationships
    user = relationship("User", back_populates="excuses")
    task = relationship("DailyTask", back_populates="excuses")

class Roast(Base):
    __tablename__ = "roasts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    personality = Column(String(20), nullable=False)
    trigger_text = Column(Text)
    response_text = Column(Text, nullable=False)
    is_shareable = Column(Boolean, default=True)
    share_count = Column(Integer, default=0)
    created_at = Column(DateTime, default=func.now())

    # Relationships
    user = relationship("User", back_populates="roasts")

class Event(Base):
    __tablename__ = "events"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    event_type = Column(String(50), nullable=False)
    event_data = Column(JSON)
    created_at = Column(DateTime, default=func.now())

class RefreshToken(Base):
    __tablename__ = "refresh_tokens"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    token = Column(String(255), unique=True, nullable=False, index=True)
    expires_at = Column(DateTime, nullable=False)
    is_revoked = Column(Boolean, default=False)
    created_at = Column(DateTime, default=func.now())
    
    # Relationship
    user = relationship("User")