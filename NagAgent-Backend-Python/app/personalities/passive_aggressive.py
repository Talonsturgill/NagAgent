import random
from typing import Dict, List
from .base import BasePersonality

class PassiveAggressivePat(BasePersonality):
    def __init__(self):
        self.name = "Passive-Aggressive Pat"
        self.emoji = "🤖"
        
    def morning_nag(self, tasks: List[str]) -> str:
        intros = [
            "Good morning! I see we're starting another day of... potential. How refreshing.",
            "Hope this message finds you well! Unlike your goals, which are presumably dead.",
            "Happy Monday! Or as you call it, 'I'll start next Monday' day.",
            "Morning! Ready to continue your impressive streak of mediocrity?",
            "Good day! Time for another round of creative task avoidance!"
        ]
        
        intro = random.choice(intros)
        task_count = len(tasks)
        
        if task_count == 0:
            return f"{intro}\n\nNo tasks set? That's... fine. I guess we're going with the 'wing it' approach to life. Bold choice."
        elif task_count == 1:
            return f"{intro}\n\nJust one task today: {tasks[0]}\n\nOne task. So manageable. So achievable. So... probably not happening, but who am I to judge? 🙂"
        else:
            task_list = '\n'.join([f"• {task}" for task in tasks])
            return f"{intro}\n\nToday's ambitious agenda:\n{task_list}\n\nLovely list! I'm sure you'll tackle these with your usual... enthusiasm."
    
    def excuse_response(self, excuse: str, task: str) -> str:
        excuse_lower = excuse.lower()
        
        responses = {
            'tired': [
                "Oh, you're tired? How... unexpected. From all that sitting around, I imagine.",
                "Tired, you say? Well, rest is important. Even if you've been resting for 12 hours.",
                "Fatigue is rough. Good thing you conserved energy by not doing anything yesterday."
            ],
            'busy': [
                "So busy! I saw your 6-hour Netflix session. Very... productive.",
                "Busy, busy, busy! Just not with the things that matter, apparently.",
                "Totally understand! Scrolling takes so much time and energy."
            ],
            'tomorrow': [
                "Tomorrow! Your favorite day of the week. Right next to 'someday'.",
                "Tomorrow works! Just like yesterday's tomorrow worked out so well.",
                "As per your previous 47 commitments, tomorrow seems... optimistic."
            ],
            'forgot': [
                "You forgot? With me constantly reminding you? Fascinating.",
                "Memory issues, I see. Must be from all that... selective attention.",
                "Forgot! But I'm sure you remembered every TikTok you watched today."
            ]
        }
        
        for key, responses_list in responses.items():
            if key in excuse_lower:
                return random.choice(responses_list)
        
        defaults = [
            f"'{excuse}' - creative! Still doesn't change the fact that '{task}' needs doing, but points for originality.",
            f"I'll file '{excuse}' under 'Classic Excuses, Volume 12.' The collection grows.",
            f"Interesting take! '{excuse}' is definitely... a choice.",
            "I mean, I guess that's one way to avoid responsibility. Different approach, but okay."
        ]
        
        return random.choice(defaults)
    
    def completion_response(self, completed_rate: float) -> str:
        if completed_rate == 0:
            return random.choice([
                "Zero percent! Well, consistency is a virtue. Consistently disappointing, but still consistent.",
                "Nothing accomplished? That's... fine. I wasn't expecting much anyway.",
                "0%? Impressive! Not everyone can achieve such perfect inaction."
            ])
        elif completed_rate < 0.5:
            return random.choice([
                f"{completed_rate*100:.0f}%? Well, it's... something. I suppose we should celebrate small victories.",
                f"Only {completed_rate*100:.0f}%? No, no, that's fine. The bar wasn't that high anyway.",
                "Some progress! More than I expected, honestly."
            ])
        elif completed_rate < 1.0:
            return random.choice([
                f"{completed_rate*100:.0f}%! So close to adequacy! But close is... close.",
                "Almost there! 'Almost' being the operative word, as usual.",
                "Nearly complete! 'Nearly' - such a lovely word for 'not quite good enough.'"
            ])
        else:
            return random.choice([
                "100%?! Well! This is... unexpected. I'll need to update my expectations.",
                "Everything done? Huh. I guess miracles do happen. Occasionally.",
                "Complete success! I'm genuinely surprised. Pleasantly surprised, but surprised nonetheless."
            ])
    
    def daily_report(self, stats: Dict) -> str:
        completed = stats.get('completed', 0)
        total = stats.get('total', 1)
        excuses = stats.get('excuses', 0)
        streak = stats.get('streak', 0)
        
        rate = (completed / total * 100) if total > 0 else 0
        
        report = f"""
🤖 DAILY PERFORMANCE SUMMARY 🤖
{'~' * 35}
Tasks Completed: {completed}/{total} ({rate:.0f}%)
Excuses Generated: {excuses}
Success Streak: {streak} days
{'~' * 35}
"""
        
        if rate == 0:
            report += "\nOverall Assessment: As expected"
        elif rate < 50:
            report += "\nOverall Assessment: Meeting low expectations"
        elif rate < 100:
            report += "\nOverall Assessment: Surprisingly adequate"
        else:
            report += "\nOverall Assessment: Exceeding expectations (shocking)"
        
        if excuses > 5:
            report += f"\n\nSpecial Recognition: {excuses} excuses today! Your creativity in avoidance is... remarkable. 🙂"
        
        return report