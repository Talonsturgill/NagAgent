# NagAgent MVP 🔥

An AI-powered accountability coach that uses humor, sass, and tough love to help users achieve their goals through WhatsApp messaging.

## Features

- **4 Distinct AI Personalities**: Choose from Sergeant Slacker, Sassy Susan, Passive-Aggressive Pat, or Brutal Brandon
- **WhatsApp Integration**: Get nagged directly through WhatsApp
- **Goal Tracking**: Set daily goals and track completion
- **Smart Scheduling**: Automated morning nags, afternoon check-ins, and evening reports
- **Excuse Detection**: AI categorizes your excuses and roasts them accordingly
- **Daily Reports**: Get brutally honest accountability reports

## Quick Start

### Local Development

1. **Clone the repository**
```bash
git clone <repository-url>
cd NagAgent
```

2. **Set up Python environment**
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

3. **Set up environment variables**
```bash
cp .env.example .env
# Edit .env with your API keys and configuration
```

4. **Set up database**
```bash
# Using Docker
docker run --name nagagent-db -e POSTGRES_PASSWORD=password -e POSTGRES_DB=nagagent -p 5432:5432 -d postgres:15

# Update DATABASE_URL in .env
DATABASE_URL=postgresql://postgres:password@localhost:5432/nagagent
```

5. **Run the application**
```bash
uvicorn app.main:app --reload --port 8000
```

### Docker Development

```bash
docker-compose up --build
```

## API Endpoints

- `GET /` - API status and welcome message
- `GET /health` - Health check endpoint
- `GET /personalities` - Get all available personalities
- `POST /webhook/whatsapp` - Twilio WhatsApp webhook handler

## Environment Variables

Required environment variables (see `.env.example`):

```env
# Twilio Configuration
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_WHATSAPP_NUMBER=whatsapp:+14155238886

# OpenAI Configuration  
OPENAI_API_KEY=your_openai_api_key

# Database Configuration
DATABASE_URL=postgresql://user:password@localhost/nagagent

# App Configuration
SECRET_KEY=your-secret-key-here
ENVIRONMENT=development
DEBUG=True
```

## WhatsApp Setup

1. **Set up Twilio Account**
   - Create account at [Twilio](https://www.twilio.com)
   - Get Account SID and Auth Token
   - Set up WhatsApp Sandbox or approved WhatsApp Business Account

2. **Configure Webhook**
   - Set webhook URL to: `https://your-domain.com/webhook/whatsapp`
   - Use ngrok for local development: `ngrok http 8000`

## User Flow

1. **Onboarding**: User texts the WhatsApp number and selects a personality
2. **Goal Setting**: User sets daily goals via WhatsApp messages
3. **Daily Nags**: Automated morning motivation, afternoon check-ins, evening reports
4. **Excuse Handling**: User makes excuses, AI roasts them appropriately
5. **Progress Tracking**: Daily completion rates and streaks

## Personalities

### 🔥 Sergeant Slacker
Military drill instructor energy. Disappointed in your lack of discipline.
- **Style**: ALL CAPS when angry, military terminology
- **Sample**: "RISE AND SHINE, MAGGOT! Time to disappoint me again!"

### 😈 Sassy Susan  
Your toxic bestie who secretly wants you to succeed.
- **Style**: Valley girl meets corporate burnout, heavy use of "bestie"
- **Sample**: "Morning bestie! Ready to procrastinate? The drama when you don't do it... 🎭"

### 🤖 Passive-Aggressive Pat
Corporate middle manager energy, weaponized disappointment.
- **Style**: Overly polite but dripping with judgment
- **Sample**: "No progress yet? That's... fine. I guess we're going with the 'wing it' approach."

### 👹 Brutal Brandon
Zero filter, just pure unfiltered truth bombs.
- **Style**: Blunt, existential crisis inducer, dark humor
- **Sample**: "Your potential called. It's filing a missing person report."

## Deployment

### Railway Deployment

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login and deploy
railway login
railway init
railway up
```

### Manual Deployment

1. Set up PostgreSQL database
2. Configure environment variables
3. Deploy using Docker or direct Python deployment
4. Set up Twilio webhook URL
5. Test with WhatsApp messages

## Development

### Running Tests

```bash
pytest
```

### Database Migrations

```bash
alembic init alembic
alembic revision --autogenerate -m "Initial migration"
alembic upgrade head
```

### Adding New Features

1. Create models in `app/models.py`
2. Add business logic to `app/services/`
3. Create API endpoints in `app/routers/`
4. Update personality responses in `app/personalities/`

## Architecture

```
User <-> WhatsApp <-> Twilio <-> FastAPI Backend <-> OpenAI
                                        |
                                  PostgreSQL DB
```

## Tech Stack

- **Backend**: FastAPI (Python)
- **Database**: PostgreSQL with SQLAlchemy
- **AI**: OpenAI GPT-4 API
- **Messaging**: Twilio WhatsApp API
- **Scheduling**: APScheduler
- **Deployment**: Railway/Render/Docker

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add your changes
4. Write tests
5. Submit a pull request

## License

MIT License - see LICENSE file for details

---

*"Stop reading documentation and start building, you procrastinating disappointment."*
- Sergeant Slacker