import openai
from typing import Dict
import os
from dotenv import load_dotenv

load_dotenv()

class OpenAIService:
    def __init__(self):
        self.client = openai.OpenAI(
            api_key=os.getenv("OPENAI_API_KEY")
        )
        self.model = "gpt-4"
        
    def generate_response(
        self, 
        personality_prompt: str, 
        context: str, 
        user_history: Dict
    ) -> str:
        system_prompt = f"""
        You are {personality_prompt}
        
        Your job is to motivate users through humor, sass, and tough love.
        Be funny enough that users want to screenshot and share your responses.
        Stay in character at all times.
        Maximum 2-3 sentences per response.
        Use appropriate emojis occasionally but don't overdo it.
        """
        
        user_prompt = f"""
        Context: {context}
        User's recent completion rate: {user_history.get('completion_rate', 0)}%
        User's common excuses: {user_history.get('common_excuses', [])}
        User's current streak: {user_history.get('streak', 0)} days
        
        Generate a response that:
        1. Addresses their current situation
        2. Is funny/savage enough to share on social media
        3. Still motivates them to take action
        4. Stays true to your personality
        """
        
        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                max_tokens=150,
                temperature=0.8
            )
            
            return response.choices[0].message.content.strip()
        except Exception as e:
            # Fallback to pre-written responses if OpenAI fails
            return "Well, this is awkward. Even I'm speechless at your level of procrastination."
    
    def categorize_excuse(self, excuse_text: str) -> str:
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
        
        try:
            response = self.client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[{"role": "user", "content": prompt}],
                max_tokens=10,
                temperature=0
            )
            
            return response.choices[0].message.content.strip().lower()
        except Exception as e:
            # Simple keyword-based fallback
            excuse_lower = excuse_text.lower()
            if any(word in excuse_lower for word in ['tired', 'exhausted', 'sleepy']):
                return 'tired'
            elif any(word in excuse_lower for word in ['busy', 'swamped', 'overwhelmed']):
                return 'busy'
            elif any(word in excuse_lower for word in ['forgot', 'remember', 'memory']):
                return 'forgot'
            elif any(word in excuse_lower for word in ['tomorrow', 'later', 'next']):
                return 'tomorrow'
            elif any(word in excuse_lower for word in ['sick', 'ill', 'unwell']):
                return 'sick'
            else:
                return 'other'
    
    def enhance_roast(self, base_roast: str, user_context: Dict) -> str:
        """Use AI to enhance pre-written roasts with user-specific context"""
        prompt = f"""
        Take this base roast: "{base_roast}"
        
        User context:
        - Completion rate: {user_context.get('completion_rate', 0)}%
        - Recent excuses: {user_context.get('recent_excuses', [])}
        - Goals: {user_context.get('current_goals', [])}
        
        Enhance the roast to be more personalized while keeping the same tone and personality.
        Keep it under 2-3 sentences and make it shareable.
        """
        
        try:
            response = self.client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[{"role": "user", "content": prompt}],
                max_tokens=100,
                temperature=0.7
            )
            
            return response.choices[0].message.content.strip()
        except Exception as e:
            # Return original roast if enhancement fails
            return base_roast