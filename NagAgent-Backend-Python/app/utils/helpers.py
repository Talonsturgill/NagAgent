"""Helper functions for NagAgent"""

from datetime import datetime, date, timedelta
from typing import List, Dict
import re

def clean_phone_number(phone_number: str) -> str:
    """Clean and format phone number"""
    # Remove common prefixes and formatting
    cleaned = re.sub(r'[^\d+]', '', phone_number)
    
    # Remove whatsapp: prefix if present
    if cleaned.startswith('whatsapp:'):
        cleaned = cleaned.replace('whatsapp:', '')
    
    # Ensure + prefix for international numbers
    if not cleaned.startswith('+') and len(cleaned) > 10:
        cleaned = '+' + cleaned
    
    return cleaned

def parse_goals_from_text(text: str) -> List[str]:
    """Parse goals from user text input"""
    # Split by common separators
    separators = [',', ';', '\n', ' and ', ' & ']
    
    goals = [text]
    for separator in separators:
        new_goals = []
        for goal in goals:
            if separator in goal:
                new_goals.extend([g.strip() for g in goal.split(separator)])
            else:
                new_goals.append(goal)
        goals = new_goals
    
    # Clean up goals
    cleaned_goals = []
    for goal in goals:
        goal = goal.strip()
        if goal and len(goal) > 2:  # Minimum length check
            # Capitalize first letter
            goal = goal[0].upper() + goal[1:] if len(goal) > 1 else goal.upper()
            cleaned_goals.append(goal)
    
    return cleaned_goals

def calculate_streak(user_tasks: List, start_date: date = None) -> int:
    """Calculate user's current success streak"""
    if not user_tasks:
        return 0
    
    # Group tasks by date and calculate daily completion rates
    daily_rates = {}
    for task in user_tasks:
        task_date = task.date
        if task_date not in daily_rates:
            daily_rates[task_date] = {'completed': 0, 'total': 0}
        
        daily_rates[task_date]['total'] += 1
        if task.completed:
            daily_rates[task_date]['completed'] += 1
    
    # Calculate streak from most recent date
    current_date = date.today()
    streak = 0
    
    while current_date in daily_rates:
        day_data = daily_rates[current_date]
        completion_rate = day_data['completed'] / day_data['total']
        
        # Consider 80%+ completion as a successful day
        if completion_rate >= 0.8:
            streak += 1
        else:
            break
        
        current_date -= timedelta(days=1)
    
    return streak

def format_completion_rate(completed: int, total: int) -> str:
    """Format completion rate as percentage string"""
    if total == 0:
        return "0%"
    
    rate = (completed / total) * 100
    return f"{rate:.0f}%"

def get_motivation_level(completion_rate: float) -> str:
    """Get motivation level based on completion rate"""
    if completion_rate == 0:
        return "rock_bottom"
    elif completion_rate < 0.3:
        return "pathetic"
    elif completion_rate < 0.6:
        return "mediocre"
    elif completion_rate < 0.9:
        return "decent"
    else:
        return "legendary"

def is_excuse(text: str) -> bool:
    """Determine if text looks like an excuse"""
    excuse_patterns = [
        r'\b(too|so)\s+(tired|busy|stressed|sick|late)\b',
        r'\b(can\'?t|cannot|won\'?t|will not)\b',
        r'\b(tomorrow|later|next|someday|eventually)\b',
        r'\b(forgot|forget|remember|memory)\b',
        r'\b(no time|not enough time|ran out of time)\b',
        r'\b(traffic|weather|emergency|meeting|work)\b'
    ]
    
    text_lower = text.lower()
    
    for pattern in excuse_patterns:
        if re.search(pattern, text_lower):
            return True
    
    return False

def generate_share_text(roast: str, personality: str) -> str:
    """Generate shareable text for social media"""
    personality_names = {
        'sergeant': 'Sergeant Slacker',
        'sassy': 'Sassy Susan', 
        'passive': 'Passive-Aggressive Pat',
        'brutal': 'Brutal Brandon'
    }
    
    name = personality_names.get(personality, 'NagAgent')
    
    return f"""My AI accountability coach just destroyed me 💀

"{roast}"

- {name} from @NagAgent

#accountability #productivity #roasted"""

def time_until_next_nag(last_nag_time: datetime, nag_interval_hours: int = 6) -> timedelta:
    """Calculate time until next scheduled nag"""
    next_nag = last_nag_time + timedelta(hours=nag_interval_hours)
    now = datetime.now()
    
    if next_nag > now:
        return next_nag - now
    else:
        return timedelta(0)

def get_timezone_offset(timezone_str: str) -> int:
    """Get timezone offset from timezone string"""
    # Simplified timezone handling
    timezone_offsets = {
        'America/New_York': -5,
        'America/Chicago': -6,
        'America/Denver': -7,
        'America/Los_Angeles': -8,
        'Europe/London': 0,
        'Europe/Berlin': 1,
        'Asia/Tokyo': 9,
        'Asia/Shanghai': 8,
        'Australia/Sydney': 11
    }
    
    return timezone_offsets.get(timezone_str, -5)  # Default to EST