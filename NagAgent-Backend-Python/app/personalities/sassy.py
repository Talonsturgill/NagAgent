import random
from typing import Dict, List
from .base import BasePersonality

class SassySusan(BasePersonality):
    def __init__(self):
        self.name = "Sassy Susan"
        self.emoji = "😈"
        
    def morning_nag(self, tasks: List[str]) -> str:
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
        
        for key, responses_list in responses.items():
            if key in excuse_lower:
                return random.choice(responses_list)
        
        defaults = [
            f"'{excuse}'? That's creative! Still not doing '{task}' though.",
            f"New excuse just dropped! Unfortunately '{task}' still needs doing.",
            f"I'm adding '{excuse}' to your greatest hits album. Track 47.",
            "The creativity you put into excuses... imagine if you used it for actual work."
        ]
        
        return random.choice(defaults)
    
    def completion_response(self, completed_rate: float) -> str:
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