# NagAgent Backend API

AI Accountability Coach that roasts you into productivity! 🔥

This is the production-ready FastAPI backend that powers the NagAgent iOS app, providing JWT authentication, goal tracking, task management, and AI-powered roasts.

## 🚀 Features

- **JWT Authentication** - Secure user registration and login
- **Goal Management** - Create, update, and track personal goals
- **Daily Task Tracking** - Mark tasks complete, track streaks
- **AI-Powered Roasts** - Submit excuses and get roasted by different personalities
- **Progress Reports** - Daily, weekly, and monthly progress analytics
- **Rate Limiting** - Protect against abuse with Redis-backed rate limiting
- **Security Headers** - Production-ready security middleware
- **API Documentation** - Auto-generated OpenAPI/Swagger docs
- **Database Migrations** - Alembic for database schema management

## 🏗️ Tech Stack

- **FastAPI** - Modern, fast web framework
- **PostgreSQL** - Primary database
- **Redis** - Rate limiting and caching
- **SQLAlchemy** - ORM and database toolkit
- **Alembic** - Database migration tool
- **JWT** - Authentication tokens
- **OpenAI API** - AI roast generation
- **Docker** - Containerization

## 🔧 Setup & Installation

### Prerequisites

- Python 3.9+
- PostgreSQL 13+
- Redis 6+
- Docker & Docker Compose (optional)

### Local Development

1. **Clone the repository**
```bash
cd NagAgent
```

2. **Create virtual environment**
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. **Install dependencies**
```bash
pip install -r requirements.txt
```

4. **Set up environment variables**
```bash
cp .env.example .env
# Edit .env with your configuration
```

5. **Start services with Docker Compose**
```bash
docker-compose up -d db redis
```

6. **Run database migrations**
```bash
alembic upgrade head
```

7. **Start the development server**
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Docker Development

1. **Start all services**
```bash
docker-compose up --build
```

2. **Run migrations in container**
```bash
docker-compose exec web alembic upgrade head
```

The API will be available at:
- **API**: http://localhost:8000
- **Docs**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **Adminer**: http://localhost:8080

## 📚 API Documentation

### Base URL
```
http://localhost:8000/api/v1
```

### Authentication

All protected endpoints require a JWT token in the Authorization header:
```
Authorization: Bearer <your-jwt-token>
```

### Main Endpoints

#### Authentication
- `POST /auth/register` - Register new user
- `POST /auth/login` - Login user
- `POST /auth/refresh` - Refresh access token
- `POST /auth/logout` - Logout user
- `GET /auth/me` - Get current user profile
- `PUT /auth/me` - Update user profile

#### Goals
- `GET /goals` - Get user's goals
- `POST /goals` - Create new goal
- `GET /goals/{id}` - Get specific goal
- `PUT /goals/{id}` - Update goal
- `DELETE /goals/{id}` - Archive goal

#### Tasks
- `GET /tasks/today` - Get today's tasks
- `GET /tasks` - Get tasks with filters
- `PUT /tasks/{id}` - Update task completion
- `POST /tasks/{id}/complete` - Mark task complete
- `GET /tasks/stats/streak` - Get completion streak

#### Roasts & Excuses
- `GET /roasts/personalities` - Get available personalities
- `POST /roasts/excuse` - Submit excuse and get roasted
- `POST /roasts/generate` - Generate custom roast
- `GET /roasts/history` - Get excuse history
- `GET /roasts/roasts` - Get roast history

#### Reports
- `GET /reports/daily` - Get daily report
- `GET /reports/weekly` - Get weekly report
- `GET /reports/monthly` - Get monthly report
- `GET /reports/overview` - Get overall statistics

### Rate Limits

- **Authentication**: 5-20 requests/minute
- **Goal/Task CRUD**: 10-30 requests/minute
- **Roast Generation**: 20 requests/minute
- **Reports**: 10-60 requests/minute
- **General API**: 100 requests/minute

## 🔑 Environment Variables

Key environment variables (see `.env.example` for complete list):

```bash
# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/nagentdb

# Security
SECRET_KEY=your-super-secret-jwt-key
ALGORITHM=HS256

# OpenAI
OPENAI_API_KEY=your-openai-api-key

# Redis
REDIS_URL=redis://localhost:6379

# Environment
ENVIRONMENT=development
DEBUG=true
```

## 🗄️ Database

### Migrations

Create new migration:
```bash
alembic revision --autogenerate -m "Description"
```

Apply migrations:
```bash
alembic upgrade head
```

Rollback migrations:
```bash
alembic downgrade -1
```

### Schema

Main tables:
- `users` - User accounts and profiles
- `refresh_tokens` - JWT refresh tokens
- `goals` - User goals and objectives
- `daily_tasks` - Daily task instances
- `excuses` - User excuses for incomplete tasks
- `roasts` - AI-generated roasts and responses

## 🎭 Personalities

Available AI personalities for roasts:

- **Sergeant Slacker** 🔥 - Military drill instructor energy
- **Sassy Susan** 😈 - Your toxic bestie who wants you to succeed
- **Passive-Aggressive Pat** 🤖 - Corporate middle manager vibes
- **Brutal Brandon** 👹 - Zero filter, just truth bombs

## 📊 Monitoring

### Health Check
```bash
curl http://localhost:8000/health
```

### Logs
```bash
# Docker logs
docker-compose logs -f web

# Application logs in development
# Logs are printed to stdout
```

## 🚀 Deployment

### Production Checklist

1. **Environment Variables**
   - Set `ENVIRONMENT=production`
   - Set `DEBUG=false`
   - Use strong `SECRET_KEY`
   - Configure proper `ALLOWED_ORIGINS`

2. **Database**
   - Use managed PostgreSQL service
   - Set up connection pooling
   - Configure SSL

3. **Redis**
   - Use managed Redis service
   - Enable persistence
   - Configure authentication

4. **Security**
   - Enable HTTPS
   - Configure proper CORS
   - Set up monitoring and alerting

5. **Scaling**
   - Use multiple app instances
   - Configure load balancer
   - Set up database read replicas

### Docker Production

```dockerfile
# Use production Docker compose
docker-compose -f docker-compose.prod.yml up -d
```

## 🧪 Testing

Run tests:
```bash
pytest
```

Run with coverage:
```bash
pytest --cov=app tests/
```

## 📱 iOS App Integration

The API is designed to work seamlessly with the NagAgent iOS app:

1. **Authentication Flow**
   - Register/login with email/password
   - Receive JWT tokens
   - Use refresh token for token renewal

2. **Data Sync**
   - Create goals in app
   - Sync daily tasks
   - Submit excuses and receive roasts
   - View progress reports

3. **Offline Support**
   - Cache data locally in iOS app
   - Sync when network available
   - Handle token refresh automatically

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

This project is proprietary software. All rights reserved.

## 🆘 Support

For support and questions:
- Check the API documentation at `/docs`
- Review this README
- Check application logs
- Test endpoints with the interactive docs

---

**Ready to get roasted into productivity? Start your NagAgent journey today! 🔥**