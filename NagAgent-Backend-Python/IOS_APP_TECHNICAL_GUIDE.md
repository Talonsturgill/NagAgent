# NagAgent MVP - iOS App Technical Implementation Guide

## MVP Scope (2-3 Week Sprint)

### What We're Building
An iOS app that:
1. Onboards users with personality quiz
2. Allows users to set daily goals/tasks
3. Sends push notifications with personality-based nags
4. Tracks task completion
5. Generates shareable daily reports
6. Creates screenshot-worthy roasts

### MVP Features
- 4 AI personalities
- Daily goal setting (up to 5 goals)
- Push notifications (morning, afternoon, evening)
- Excuse detection and roasting
- Daily accountability report
- Screenshot sharing functionality
- Basic free tier / premium upgrade

## Tech Stack

### Frontend (iOS)
- **Language**: Swift 5.0+ / SwiftUI
- **Minimum iOS Version**: iOS 15.0
- **Architecture**: MVVM (Model-View-ViewModel)
- **Dependencies**:
  - Alamofire (networking)
  - KeychainSwift (secure storage)
  - RevenueCat (subscriptions)
  - Firebase (analytics, crashlytics, push notifications)

### Backend
- **API**: FastAPI (Python) or Node.js/Express
- **Database**: PostgreSQL with Supabase
- **AI**: OpenAI GPT-4 API
- **Push Notifications**: Firebase Cloud Messaging (FCM)
- **Hosting**: Railway/Render/Vercel
- **Authentication**: Supabase Auth or Firebase Auth

## iOS App Structure

```
NagAgent/
├── NagAgent.xcodeproj
├── NagAgent/
│   ├── App/
│   │   ├── NagAgentApp.swift          # Main app entry
│   │   └── AppDelegate.swift          # App lifecycle
│   ├── Models/
│   │   ├── User.swift
│   │   ├── Goal.swift
│   │   ├── DailyTask.swift
│   │   ├── Personality.swift
│   │   └── Roast.swift
│   ├── Views/
│   │   ├── Onboarding/
│   │   │   ├── WelcomeView.swift
│   │   │   ├── PersonalityQuizView.swift
│   │   │   └── GoalSettingView.swift
│   │   ├── Main/
│   │   │   ├── HomeView.swift
│   │   │   ├── TaskListView.swift
│   │   │   ├── DailyReportView.swift
│   │   │   └── SettingsView.swift
│   │   ├── Components/
│   │   │   ├── RoastBubbleView.swift
│   │   │   ├── TaskRowView.swift
│   │   │   ├── PersonalityCardView.swift
│   │   │   └── ShareableRoastView.swift
│   ├── ViewModels/
│   │   ├── OnboardingViewModel.swift
│   │   ├── TaskViewModel.swift
│   │   ├── PersonalityViewModel.swift
│   │   └── SettingsViewModel.swift
│   ├── Services/
│   │   ├── APIService.swift
│   │   ├── NotificationService.swift
│   │   ├── PersonalityService.swift
│   │   └── AnalyticsService.swift
│   ├── Utils/
│   │   ├── Constants.swift
│   │   ├── Extensions.swift
│   │   └── Helpers.swift
│   └── Resources/
│       ├── Assets.xcassets
│       ├── Localizable.strings
│       └── Info.plist
```

## Core iOS Implementation

### Models/Personality.swift
```swift
import Foundation

enum PersonalityType: String, CaseIterable, Codable {
    case sergeant = "sergeant"
    case sassy = "sassy"
    case passive = "passive"
    case brutal = "brutal"
    
    var displayName: String {
        switch self {
        case .sergeant: return "Sergeant Slacker"
        case .sassy: return "Sassy Susan"
        case .passive: return "Passive-Aggressive Pat"
        case .brutal: return "Brutal Brandon"
        }
    }
    
    var emoji: String {
        switch self {
        case .sergeant: return "🔥"
        case .sassy: return "😈"
        case .passive: return "🤖"
        case .brutal: return "👹"
        }
    }
    
    var description: String {
        switch self {
        case .sergeant: 
            return "Military drill instructor who's disappointed in you"
        case .sassy: 
            return "Your toxic bestie who secretly wants you to succeed"
        case .passive: 
            return "Corporate middle manager energy"
        case .brutal: 
            return "Zero filter, just truth bombs"
        }
    }
}

struct Personality: Codable {
    let type: PersonalityType
    let selectedAt: Date
    var currentMood: String?
}
```

### Views/Main/HomeView.swift
```swift
import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = TaskViewModel()
    @State private var showingAddTask = false
    @State private var currentRoast: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [.black, .purple.opacity(0.3)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Personality greeting
                        PersonalityHeaderView(
                            personality: viewModel.currentPersonality,
                            roast: currentRoast
                        )
                        .padding(.horizontal)
                        
                        // Today's tasks
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Today's Delusions")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button(action: { showingAddTask = true }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.purple)
                                }
                            }
                            .padding(.horizontal)
                            
                            if viewModel.tasks.isEmpty {
                                EmptyTasksView()
                                    .padding()
                            } else {
                                ForEach(viewModel.tasks) { task in
                                    TaskRowView(
                                        task: task,
                                        onComplete: { 
                                            viewModel.completeTask(task)
                                            currentRoast = viewModel.getCompletionRoast()
                                        },
                                        onExcuse: { excuse in
                                            currentRoast = viewModel.getExcuseRoast(excuse)
                                        }
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Daily stats
                        DailyStatsCard(stats: viewModel.dailyStats)
                            .padding()
                        
                        // Share button
                        if let roast = currentRoast {
                            ShareableRoastView(
                                roast: roast,
                                personality: viewModel.currentPersonality
                            )
                            .padding()
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.loadTasks()
            currentRoast = viewModel.getMorningRoast()
        }
    }
}
```

### Services/NotificationService.swift
```swift
import UserNotifications
import Foundation

class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            if granted {
                self.scheduleDailyNags()
            }
        }
    }
    
    func scheduleDailyNags() {
        scheduleNag(
            hour: 9, 
            minute: 0, 
            identifier: "morning_nag",
            title: "Wake up, disappointment!",
            body: getMorningNagBody()
        )
        
        scheduleNag(
            hour: 14,
            minute: 0,
            identifier: "afternoon_checkup",
            title: "Productivity check",
            body: getAfternoonNagBody()
        )
        
        scheduleNag(
            hour: 20,
            minute: 0,
            identifier: "evening_report",
            title: "Daily reality check",
            body: getEveningNagBody()
        )
    }
    
    private func scheduleNag(hour: Int, minute: Int, identifier: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func getMorningNagBody() -> String {
        let personality = UserDefaults.standard.string(forKey: "personality") ?? "sassy"
        
        switch personality {
        case "sergeant":
            return "RISE AND SHINE MAGGOT! Time to disappoint me again!"
        case "sassy":
            return "Morning bestie! Ready to procrastinate? 💅"
        case "passive":
            return "Good morning! Another day of... potential."
        case "brutal":
            return "Your dreams are dying. Just thought you should know."
        default:
            return "Time to check your tasks!"
        }
    }
    
    private func getAfternoonNagBody() -> String {
        // Similar implementation
        return "Still haven't done anything? Shocking."
    }
    
    private func getEveningNagBody() -> String {
        // Similar implementation  
        return "Time to face your daily failure report!"
    }
}
```

### Views/Components/ShareableRoastView.swift
```swift
import SwiftUI

struct ShareableRoastView: View {
    let roast: String
    let personality: PersonalityType
    @State private var isSharing = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Roast card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(personality.emoji)
                        .font(.largeTitle)
                    Text(personality.displayName)
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Image("NagAgentLogo")
                        .resizable()
                        .frame(width: 30, height: 30)
                }
                
                Text(roast)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.purple.opacity(0.3))
                    )
                
                Text("@NagAgent")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
            )
            
            // Share button
            Button(action: shareRoast) {
                Label("Share this roast", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.purple)
                    )
            }
        }
        .padding()
    }
    
    private func shareRoast() {
        let image = generateShareableImage()
        let activityVC = UIActivityViewController(
            activityItems: [image, "My NagAgent just destroyed me 💀"],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    private func generateShareableImage() -> UIImage {
        // Convert SwiftUI view to UIImage for sharing
        let controller = UIHostingController(
            rootView: self.background(Color.black)
        )
        let view = controller.view!
        
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        return renderer.image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
    }
}
```

### Services/APIService.swift
```swift
import Foundation
import Combine

class APIService {
    static let shared = APIService()
    private let baseURL = "https://api.nagagent.ai/v1"
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    func getRoast(
        personality: PersonalityType,
        context: RoastContext,
        userHistory: UserHistory
    ) -> AnyPublisher<String, Error> {
        let endpoint = "\(baseURL)/roast"
        
        let body = RoastRequest(
            personality: personality.rawValue,
            context: context,
            userHistory: userHistory
        )
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: RoastResponse.self, decoder: JSONDecoder())
            .map(\.roast)
            .eraseToAnyPublisher()
    }
    
    func getDailyReport(userId: String) -> AnyPublisher<DailyReport, Error> {
        let endpoint = "\(baseURL)/users/\(userId)/daily-report"
        
        return URLSession.shared.dataTaskPublisher(
            for: URL(string: endpoint)!
        )
        .map(\.data)
        .decode(type: DailyReport.self, decoder: JSONDecoder())
        .eraseToAnyPublisher()
    }
    
    func completeTask(taskId: String) -> AnyPublisher<TaskResponse, Error> {
        // Implementation
        fatalError("Implement task completion")
    }
    
    func submitExcuse(taskId: String, excuse: String) -> AnyPublisher<RoastResponse, Error> {
        // Implementation
        fatalError("Implement excuse submission")
    }
}

struct RoastRequest: Codable {
    let personality: String
    let context: RoastContext
    let userHistory: UserHistory
}

struct RoastContext: Codable {
    let type: String // "morning", "excuse", "completion", "evening"
    let excuse: String?
    let completionRate: Double?
    let tasks: [String]?
}

struct UserHistory: Codable {
    let totalTasks: Int
    let completedTasks: Int
    let commonExcuses: [String]
    let currentStreak: Int
}

struct RoastResponse: Codable {
    let roast: String
    let personality: String
    let shareable: Bool
}
```

## Backend API (FastAPI)

### Updated main.py for iOS app
```python
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import os
from datetime import datetime

app = FastAPI(title="NagAgent API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Models
class User(BaseModel):
    id: str
    personality: str
    created_at: datetime
    subscription_tier: str = "free"

class Task(BaseModel):
    id: str
    user_id: str
    text: str
    completed: bool = False
    created_at: datetime
    completed_at: Optional[datetime] = None

class RoastRequest(BaseModel):
    personality: str
    context: dict
    user_history: dict

class RoastResponse(BaseModel):
    roast: str
    personality: str
    shareable: bool = True

# Endpoints
@app.post("/v1/roast", response_model=RoastResponse)
async def generate_roast(request: RoastRequest):
    """Generate a personality-based roast"""
    # Get roast from personality service
    roast = get_personality_roast(
        request.personality,
        request.context,
        request.user_history
    )
    
    return RoastResponse(
        roast=roast,
        personality=request.personality,
        shareable=True
    )

@app.get("/v1/users/{user_id}/daily-report")
async def get_daily_report(user_id: str):
    """Get user's daily accountability report"""
    # Fetch user stats from database
    stats = calculate_daily_stats(user_id)
    
    return {
        "date": datetime.now().date(),
        "tasks_completed": stats["completed"],
        "tasks_total": stats["total"],
        "completion_rate": stats["rate"],
        "excuses_made": stats["excuses"],
        "current_streak": stats["streak"],
        "ranking": stats["ranking"],
        "roast": generate_report_roast(stats)
    }

@app.post("/v1/tasks/{task_id}/complete")
async def complete_task(task_id: str):
    """Mark a task as complete"""
    # Update task in database
    # Generate completion response
    pass

@app.post("/v1/tasks/{task_id}/excuse")
async def submit_excuse(task_id: str, excuse: str):
    """Submit an excuse for not completing a task"""
    # Save excuse to database
    # Generate roast response
    pass

def get_personality_roast(personality: str, context: dict, history: dict) -> str:
    """Generate roast based on personality"""
    from app.services.personality_service import PersonalityService
    ps = PersonalityService()
    
    context_type = context.get("type", "general")
    
    if context_type == "morning":
        return ps.get_morning_nag(personality, context.get("tasks", []))
    elif context_type == "excuse":
        return ps.get_excuse_response(
            personality, 
            context.get("excuse", ""),
            context.get("task", "your task")
        )
    elif context_type == "completion":
        return ps.get_completion_response(
            personality,
            context.get("completion_rate", 0)
        )
    else:
        return ps.get_daily_report(personality, history)
```

## App Store Optimization

### App Store Listing

**App Name**: NagAgent - Sassy AI Coach

**Subtitle**: Roasts You Into Productivity

**Keywords**: 
productivity, accountability, motivation, AI coach, habit tracker, goal setting, funny, sassy, tough love, procrastination

**Description**:
```
Tired of gentle reminder apps you just ignore? 

NagAgent uses humor, sass, and tough love to actually get you moving. Choose from 4 distinct AI personalities that roast your excuses and celebrate your wins (sarcastically).

CHOOSE YOUR NAGGER:
🔥 Sergeant Slacker - Military disappointment energy
😈 Sassy Susan - Your toxic bestie who wants you to succeed  
🤖 Passive Pat - Corporate passive-aggression at its finest
👹 Brutal Brandon - Zero filter, just truth bombs

FEATURES THAT ACTUALLY WORK:
• Personality-based motivation that's actually entertaining
• Screenshot-worthy roasts you'll want to share
• Daily accountability reports that call you out
• Excuse tracking (we see your patterns)
• Streaks, scores, and shameful rankings
• Voice messages from your chosen personality (Premium)

PRICING:
• Free: 1 personality, 3 daily nags
• Pro ($6.99/mo): All personalities, unlimited roasts
• Elite ($12.99/mo): Custom personalities, public shame mode

Join thousands who've turned procrastination into productivity through the power of being roasted by AI.

"My NagAgent is meaner than my inner critic but somehow more effective" - Sarah, 5 stars

"I actually look forward to being insulted by Sassy Susan" - Mike, 5 stars

"This app bullied me into the best shape of my life" - Jessica, 5 stars

Download now and choose your accountability style. Your future self will thank you (but NagAgent won't).
```

### Screenshots (6 Required)
1. Personality selection screen
2. Daily task list with roast bubble
3. Excuse being destroyed by chosen personality
4. Daily accountability report
5. Shareable roast card
6. Success celebration (sarcastic)

## Monetization Strategy

### Free Tier (User Acquisition)
- 1 personality (Sassy Susan)
- 3 nags per day
- Basic daily report
- Limited excuse responses

### Pro Tier - $6.99/month (Core Monetization)
- All 4 personalities
- Unlimited nags
- Voice messages
- Full excuse roasting
- Priority savage responses
- No ads

### Elite Tier - $12.99/month (Power Users)
- Everything in Pro
- Mix personalities
- Custom wake-up calls
- Public shame mode (Twitter integration)
- Money stakes features
- Beta features early access

### Revenue Projections
- Month 1: 1,000 downloads, 5% paid = $350 MRR
- Month 3: 10,000 downloads, 10% paid = $7K MRR  
- Month 6: 50,000 downloads, 15% paid = $52K MRR
- Year 1: 250,000 downloads, 20% paid = $350K MRR

## Development Timeline

### Week 1: Core iOS App
- [ ] Set up Xcode project
- [ ] Implement onboarding flow
- [ ] Create personality quiz
- [ ] Build main task interface
- [ ] Implement local notifications

### Week 2: Backend & AI Integration
- [ ] Deploy FastAPI backend
- [ ] Integrate OpenAI for roast generation
- [ ] Connect iOS app to API
- [ ] Implement user authentication
- [ ] Test push notifications

### Week 3: Polish & Launch Prep
- [ ] Add sharing functionality
- [ ] Implement in-app purchases
- [ ] Create App Store assets
- [ ] Beta test with TestFlight
- [ ] Fix critical bugs

### Launch Week
- [ ] Submit to App Store
- [ ] Prepare marketing materials
- [ ] Line up press coverage
- [ ] Create launch content
- [ ] Go live!

---

*"An iOS app? Finally showing some ambition. Now actually build it instead of reading docs."*
- Brutal Brandon