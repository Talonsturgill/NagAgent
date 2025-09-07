from twilio.rest import Client
from twilio.twiml.messaging_response import MessagingResponse
import os
from dotenv import load_dotenv

load_dotenv()

class TwilioService:
    def __init__(self):
        self.account_sid = os.getenv("TWILIO_ACCOUNT_SID")
        self.auth_token = os.getenv("TWILIO_AUTH_TOKEN")
        self.whatsapp_number = os.getenv("TWILIO_WHATSAPP_NUMBER", "whatsapp:+14155238886")
        self.sms_number = os.getenv("TWILIO_SMS_NUMBER")
        
        if self.account_sid and self.auth_token:
            self.client = Client(self.account_sid, self.auth_token)
        else:
            self.client = None
            print("Warning: Twilio credentials not configured")
    
    def send_whatsapp(self, to_number: str, message: str) -> bool:
        """Send WhatsApp message to user"""
        if not self.client:
            print(f"Mock WhatsApp to {to_number}: {message}")
            return False
        
        try:
            # Ensure number has whatsapp: prefix
            if not to_number.startswith('whatsapp:'):
                to_number = f"whatsapp:{to_number}"
            
            message = self.client.messages.create(
                body=message,
                from_=self.whatsapp_number,
                to=to_number
            )
            
            print(f"WhatsApp sent to {to_number}: {message.sid}")
            return True
        except Exception as e:
            print(f"Failed to send WhatsApp to {to_number}: {str(e)}")
            return False
    
    def send_sms(self, to_number: str, message: str) -> bool:
        """Send SMS message to user"""
        if not self.client or not self.sms_number:
            print(f"Mock SMS to {to_number}: {message}")
            return False
        
        try:
            message = self.client.messages.create(
                body=message,
                from_=self.sms_number,
                to=to_number
            )
            
            print(f"SMS sent to {to_number}: {message.sid}")
            return True
        except Exception as e:
            print(f"Failed to send SMS to {to_number}: {str(e)}")
            return False
    
    def create_twiml_response(self, message: str) -> str:
        """Create TwiML response for webhook"""
        response = MessagingResponse()
        response.message(message)
        return str(response)
    
    def validate_webhook(self, request_data: dict) -> dict:
        """Validate and parse webhook data"""
        return {
            'from_number': request_data.get('From', '').replace('whatsapp:', ''),
            'to_number': request_data.get('To', '').replace('whatsapp:', ''),
            'message_body': request_data.get('Body', '').strip(),
            'message_sid': request_data.get('MessageSid', ''),
            'account_sid': request_data.get('AccountSid', ''),
            'media_count': int(request_data.get('NumMedia', 0))
        }