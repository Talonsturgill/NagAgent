from abc import ABC, abstractmethod
from typing import List, Dict
import random

class BasePersonality(ABC):
    def __init__(self):
        self.name = ""
        self.emoji = ""
        
    @abstractmethod
    def morning_nag(self, tasks: List[str]) -> str:
        pass
    
    @abstractmethod
    def excuse_response(self, excuse: str, task: str) -> str:
        pass
    
    @abstractmethod
    def completion_response(self, completed_rate: float) -> str:
        pass
    
    @abstractmethod
    def daily_report(self, stats: Dict) -> str:
        pass
    
    def generate_response(self, context: str, user_data: Dict) -> str:
        context_type = user_data.get('context_type', 'general')
        
        if context_type == 'morning':
            return self.morning_nag(user_data.get('tasks', []))
        elif context_type == 'excuse':
            return self.excuse_response(
                user_data.get('excuse', ''),
                user_data.get('task', 'your task')
            )
        elif context_type == 'completion':
            return self.completion_response(
                user_data.get('completion_rate', 0)
            )
        elif context_type == 'daily_report':
            return self.daily_report(user_data.get('stats', {}))
        else:
            return self.get_general_response(context, user_data)
    
    def get_general_response(self, context: str, user_data: Dict) -> str:
        return f"I see you're trying to communicate with me. Try being more specific, you procrastinating disappointment."