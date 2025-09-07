import random
from typing import Dict, List
from .base import BasePersonality

class BrutalBrandon(BasePersonality):
    def __init__(self):
        self.name = "Brutal Brandon"
        self.emoji = "👹"
        
    def morning_nag(self, tasks: List[str]) -> str:
        intros = [
            "Another day of pretending you'll change. Admirable consistency in your delusion.",
            "Your potential called. It's filing a missing person report.",
            "Day 247 of 'your year.' Going exactly as expected.",
            "Morning! Time to continue disappointing everyone who believes in you.",
            "Rise and shine! Your mediocrity awaits."
        ]
        
        intro = random.choice(intros)
        task_count = len(tasks)
        
        if task_count == 0:
            return f"{intro}\n\nNo goals? Smart. Can't fail if you don't try. Except you're already failing at life itself."
        elif task_count == 1:
            return f"{intro}\n\nOne task: {tasks[0]}\n\nOne simple task. And we both know you'll find a way to avoid it. The human capacity for self-sabotage never ceases to amaze."
        else:
            task_list = '\n'.join([f"• {task}" for task in tasks])
            return f"{intro}\n\nToday's pipe dreams:\n{task_list}\n\nA beautiful list of things that won't happen. Your future self is watching. They're not impressed."
    
    def excuse_response(self, excuse: str, task: str) -> str:
        excuse_lower = excuse.lower()
        
        responses = {
            'tired': [
                "Tired from what? Existing? The bar is so low it's underground.",
                "Your excuse game is stronger than your work ethic. That's not a compliment.",
                "Tired of being tired of making excuses? Join the club."
            ],
            'busy': [
                "Busy avoiding responsibility. It's a full-time job, apparently.",
                "Busy being busy. A masterclass in self-deception.",
                "The only thing you're busy with is finding new ways to disappoint."
            ],
            'tomorrow': [
                "Tomorrow. The eternal escape hatch of the chronically mediocre.",
                "Tomorrow never comes for people like you. It's always today, and today you fail.",
                "Your relationship with 'tomorrow' is the longest commitment you've ever kept."
            ],
            'forgot': [
                "Forgot? Your brain saves TikToks but deletes responsibilities. Priorities.",
                "Selective amnesia is an art form. You've mastered it.",
                "Memory works fine for things that don't matter. Interesting phenomenon."
            ]
        }
        
        for key, responses_list in responses.items():
            if key in excuse_lower:
                return random.choice(responses_list)
        
        defaults = [
            f"'{excuse}' - the creativity you waste on avoidance could fuel actual achievement. But here we are.",
            f"Adding '{excuse}' to your greatest hits. Volume 47 is getting thick.",
            f"The mental gymnastics required for '{excuse}' deserve an Olympic medal.",
            "New excuse, same result. The only consistent thing about you is inconsistency."
        ]
        
        return random.choice(defaults)
    
    def completion_response(self, completed_rate: float) -> str:
        if completed_rate == 0:
            return random.choice([
                "Zero. Absolute zero. Your consistency in failure is almost impressive.",
                "Nothing done. Again. At this point, it's performance art.",
                "0%? You've achieved perfect mediocrity. Congratulations on the consistency."
            ])
        elif completed_rate < 0.5:
            return random.choice([
                f"{completed_rate*100:.0f}%? Below average, as usual. Mediocrity would be an improvement.",
                f"Only {completed_rate*100:.0f}%? The bar was on the ground. You brought a shovel.",
                "Partial success is still mostly failure. Math is brutal."
            ])
        elif completed_rate < 1.0:
            return random.choice([
                f"{completed_rate*100:.0f}%? Close doesn't count. Excellence is binary.",
                "Almost there? 'Almost' is the story of your life.",
                "Nearly perfect is perfectly imperfect. Your specialty."
            ])
        else:
            return random.choice([
                "100%? Suspicious. Did someone else do this? The plot twist no one saw coming.",
                "Everything done? I'm checking for signs of the apocalypse. This is unprecedented.",
                "Perfect completion? You've broken the pattern. Don't let it go to your head."
            ])
    
    def daily_report(self, stats: Dict) -> str:
        completed = stats.get('completed', 0)
        total = stats.get('total', 1)
        excuses = stats.get('excuses', 0)
        streak = stats.get('streak', 0)
        
        rate = (completed / total * 100) if total > 0 else 0
        
        report = f"""
👹 DAILY REALITY CHECK 👹
{'▬' * 30}
Tasks Completed: {completed}/{total} ({rate:.0f}%)
Excuses Generated: {excuses}
Success Streak: {streak} days
Failure Streak: Still counting...
{'▬' * 30}
"""
        
        if rate == 0:
            report += "\nVerdict: Predictably disappointing"
        elif rate < 50:
            report += "\nVerdict: Below your already low standards"
        elif rate < 100:
            report += "\nVerdict: Mediocre with potential"
        else:
            report += "\nVerdict: Shocking competence detected"
        
        if excuses > 5:
            report += f"\n\nSpecial Achievement: {excuses} excuses in one day. Your creativity in avoidance exceeds your productivity by a factor of infinity."
        
        report += "\n\nRemember: Your future self is watching. They're taking notes."
        
        return report