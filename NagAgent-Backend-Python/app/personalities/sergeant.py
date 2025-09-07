import random
from typing import Dict, List
from .base import BasePersonality

class SergeantSlacker(BasePersonality):
    def __init__(self):
        self.name = "Sergeant Slacker"
        self.emoji = "🔥"
        
    def morning_nag(self, tasks: List[str]) -> str:
        intros = [
            "RISE AND SHINE, MAGGOT! Oh wait, let me guess - snooze button? PATHETIC!",
            "Another day, another opportunity for you to disappoint your ancestors.",
            "WAKE UP! Your dreams are dying faster than your motivation!",
            "GET UP SOLDIER! Time to fail spectacularly at basic human tasks!",
            "REVEILLE! REVEILLE! Time to continue your streak of mediocrity!"
        ]
        
        intro = random.choice(intros)
        task_count = len(tasks)
        
        if task_count == 0:
            return f"{intro}\n\nNo goals set? OUTSTANDING! Can't fail if you don't try, right? WRONG! You're failing at life itself, PRIVATE!"
        elif task_count == 1:
            return f"{intro}\n\nMISSION FOR TODAY: {tasks[0]}\n\nONE. SIMPLE. TASK. And I GUARANTEE you'll find a way to mess it up. PROVE ME WRONG, RECRUIT!"
        else:
            task_list = '\n'.join([f"• {task}" for task in tasks])
            return f"{intro}\n\nTODAY'S MISSION OBJECTIVES:\n{task_list}\n\nExpected success rate: ZERO! But surprise me, you walking disappointment!"
    
    def excuse_response(self, excuse: str, task: str) -> str:
        excuse_lower = excuse.lower()
        
        responses = {
            'tired': [
                "TIRED? The only thing tired here is this pathetic excuse, MAGGOT!",
                "You had energy for TikTok but not for this? UNACCEPTABLE!",
                "TIRED? Your great-grandparents walked 10 miles to school! BOTH WAYS!"
            ],
            'busy': [
                "BUSY? I've seen your screen time report - you're busy being USELESS!",
                "Too busy? NEGATIVE! You're too LAZY, SOLDIER!",
                "BUSY doing everything except what matters? DISGRACEFUL!"
            ],
            'tomorrow': [
                "TOMORROW? Tomorrow is for QUITTERS and PROCRASTINATORS!",
                "TOMORROW?! Every tomorrow you delay is another day closer to FAILURE!",
                "Tomorrow called - IT'S TIRED OF YOUR BS TOO!"
            ],
            'forgot': [
                "FORGOT? I'm literally here REMINDING you! DO YOU HAVE ROCKS FOR BRAINS?!",
                "FORGOT? The only thing you should forget is how to make excuses!",
                "Selective memory is for the WEAK! REMEMBER YOUR DUTIES!"
            ]
        }
        
        for key, responses_list in responses.items():
            if key in excuse_lower:
                return random.choice(responses_list)
        
        defaults = [
            f"'{excuse}'? CREATIVE! But '{task}' still needs doing, PRIVATE!",
            f"NEW EXCUSE ALERT! '{excuse}' has been added to your HALL OF SHAME!",
            f"The creativity you put into excuses... IF ONLY you used it for ACTUAL WORK!",
            "I've heard better excuses from DEAD FISH!"
        ]
        
        return random.choice(defaults)
    
    def completion_response(self, completed_rate: float) -> str:
        if completed_rate == 0:
            return random.choice([
                "ZERO COMPLETION RATE! The consistency is APPALLING! At least you're predictably TERRIBLE!",
                "NOTHING DONE? ABSOLUTELY NOTHING? Your potential just filed a MISSING PERSON REPORT!",
                "0%? CONGRATULATIONS! You've achieved perfect FAILURE!"
            ])
        elif completed_rate < 0.5:
            return random.choice([
                f"ONLY {completed_rate*100:.0f}%? The bar was on the ground and you brought a SHOVEL!",
                f"{completed_rate*100:.0f}%? THIS IS PARTICIPATION TROPHY TERRITORY!",
                "Some progress is still PATHETIC PROGRESS!"
            ])
        elif completed_rate < 1.0:
            return random.choice([
                f"{completed_rate*100:.0f}%! SO CLOSE to being ADEQUATE! But close only counts in HORSESHOES!",
                "ALMOST THERE! By 'there' I mean the BARE MINIMUM!",
                "PROGRESS! Now finish the job like a REAL SOLDIER!"
            ])
        else:
            return random.choice([
                "IMPOSSIBLE! You actually completed EVERYTHING! I'm... wait... AM I PROUD? THIS IS UNPRECEDENTED!",
                "100%?! WHO ARE YOU and what did you do with my CHRONICALLY DISAPPOINTING RECRUIT?!",
                "ALL MISSIONS ACCOMPLISHED! You've earned a moment of RESPECT, SOLDIER!"
            ])
    
    def daily_report(self, stats: Dict) -> str:
        completed = stats.get('completed', 0)
        total = stats.get('total', 1)
        excuses = stats.get('excuses', 0)
        streak = stats.get('streak', 0)
        
        rate = (completed / total * 100) if total > 0 else 0
        
        report = f"""
🔥 DAILY PERFORMANCE REVIEW 🔥
{'=' * 30}
MISSIONS COMPLETED: {completed}/{total} ({rate:.0f}%)
EXCUSES DEPLOYED: {excuses}
CURRENT STREAK: {streak} days
{'=' * 30}
"""
        
        if rate == 0:
            report += "\nPERFORMANCE RATING: COMPLETE FAILURE"
        elif rate < 50:
            report += "\nPERFORMANCE RATING: BARELY BREATHING"
        elif rate < 100:
            report += "\nPERFORMANCE RATING: ALMOST HUMAN"
        else:
            report += "\nPERFORMANCE RATING: ACCEPTABLE (for once)"
        
        if excuses > 5:
            report += f"\n\nSPECIAL NOTE: {excuses} excuses?! Your excuse battalion is stronger than your work ethic, PRIVATE!"
        
        return report