from typing import Dict, List
import random
from app.personalities.sergeant import SergeantSlacker
from app.personalities.sassy import SassySusan
from app.personalities.passive_aggressive import PassiveAggressivePat
from app.personalities.brutal import BrutalBrandon

class PersonalityService:
    def __init__(self):
        self.personalities = {
            'sergeant': SergeantSlacker(),
            'sassy': SassySusan(),
            'passive': PassiveAggressivePat(),
            'brutal': BrutalBrandon()
        }
    
    def get_response(
        self, 
        personality: str, 
        context: str, 
        user_data: Dict
    ) -> str:
        if personality not in self.personalities:
            personality = 'sassy'  # Default to sassy
        
        return self.personalities[personality].generate_response(
            context=context,
            user_data=user_data
        )
    
    def get_morning_nag(self, personality: str, tasks: List[str]) -> str:
        if personality not in self.personalities:
            personality = 'sassy'
        
        return self.personalities[personality].morning_nag(tasks)
    
    def get_excuse_response(
        self, 
        personality: str, 
        excuse: str, 
        task: str
    ) -> str:
        if personality not in self.personalities:
            personality = 'sassy'
        
        return self.personalities[personality].excuse_response(excuse, task)
    
    def get_completion_response(
        self, 
        personality: str, 
        completed_rate: float
    ) -> str:
        if personality not in self.personalities:
            personality = 'sassy'
        
        return self.personalities[personality].completion_response(completed_rate)
    
    def get_daily_report(
        self, 
        personality: str, 
        stats: Dict
    ) -> str:
        if personality not in self.personalities:
            personality = 'sassy'
        
        return self.personalities[personality].daily_report(stats)
    
    def get_personality_info(self, personality: str) -> Dict:
        if personality not in self.personalities:
            personality = 'sassy'
        
        p = self.personalities[personality]
        return {
            'name': p.name,
            'emoji': p.emoji,
            'type': personality
        }
    
    def get_all_personalities(self) -> Dict:
        result = {}
        for key, personality in self.personalities.items():
            result[key] = {
                'name': personality.name,
                'emoji': personality.emoji,
                'type': key
            }
        return result