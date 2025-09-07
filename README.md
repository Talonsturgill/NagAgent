# 🔥 NagAgent - AI Accountability Coach

**The only app that bullies you into success!**

NagAgent is an iOS app featuring AI-powered accountability coaches with distinct personalities who roast you into productivity. Choose your toxic motivator and get brutally honest feedback on your daily goals.

## 🎭 Meet Your Coaches

- **🔥 Sergeant Slacker** - Military drill instructor who's perpetually disappointed
- **😈 Sassy Susan** - Your toxic bestie who secretly wants you to succeed  
- **🤖 Passive-Aggressive Pat** - Corporate middle manager energy
- **👹 Brutal Brandon** - Zero filter, just truth bombs

## 📱 Features

- ✅ Personality selection that persists
- ✅ Daily goal setting and tracking
- ✅ Personality-specific roasts and motivation
- ✅ Progress tracking with harsh reality checks
- ✅ Daily report cards with brutal grades
- ✅ Share your shame on social media

## 🚀 Tech Stack

### iOS App (Swift/SwiftUI)
- SwiftUI for modern iOS UI
- Core Data for offline persistence
- PersonalityManager singleton for state management
- RevenueCat for subscriptions
- Firebase for push notifications

### Backend (Python/FastAPI)
- FastAPI REST API
- PostgreSQL database
- JWT authentication
- OpenAI integration for dynamic roasts
- Twilio for SMS/WhatsApp notifications
- Docker containerization

## 📂 Project Structure

```
NagAgent-iOS/
├── NagAgent-Swift-Codebase/     # iOS app source code
│   ├── Views/                   # SwiftUI views
│   ├── Services/                # Business logic
│   ├── Models/                  # Data models
│   └── ViewModels/              # View models
├── NagAgent-Backend-Python/     # Backend API
│   ├── app/                     # FastAPI application
│   ├── personalities/           # AI personality implementations
│   └── routers/                 # API endpoints
└── nagagent-original-preserved.html  # Interactive demo

```

## 🐛 Fixed Bugs

1. **Personality Selection Persistence** - Created PersonalityManager singleton to maintain selection across screens
2. **Goal Adding Button** - Fixed button action binding and state management

## 🎯 Quick Start

### View the Demo
Open `nagagent-original-preserved.html` in any browser to see the interactive UI preview.

### Run the Backend
```bash
cd NagAgent-Backend-Python
pip install -r requirements.txt
uvicorn app.main:app --reload
```

### Run the iOS App
1. Open `NagAgent-Swift-Codebase` in Xcode
2. Select your simulator or device
3. Build and run (⌘R)

## 🔑 Environment Variables

Create a `.env` file in the backend directory:

```env
OPENAI_API_KEY=your_key_here
DATABASE_URL=postgresql://user:pass@localhost/nagagent
SECRET_KEY=your-secret-key
TWILIO_ACCOUNT_SID=your_sid
TWILIO_AUTH_TOKEN=your_token
```

## 📝 License

MIT License - Roast responsibly!

## 🤝 Contributing

Pull requests welcome! The more brutal the roasts, the better.

---

**Warning:** This app contains harsh motivation. Not for the faint of heart or easily offended. Your feelings will be hurt, but your goals will be achieved! 💪