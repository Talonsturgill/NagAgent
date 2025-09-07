import SwiftUI
import UserNotifications

@main
struct NagAgentApp: App {
    // Core Data persistence controller
    let persistenceController = PersistenceController.shared
    
    // Authentication state manager
    @StateObject private var authManager = AuthenticationStateManager.shared
    
    // Services
    @StateObject private var pushService = PushNotificationService.shared
    @StateObject private var offlineManager = OfflineManager.shared
    
    // App state
    @State private var isInitialized = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isInitialized {
                    if authManager.isAuthenticated {
                        MainAppView()
                            .environment(\.managedObjectContext, persistenceController.viewContext)
                    } else {
                        AuthenticationFlowView()
                    }
                } else {
                    SplashScreenView()
                        .onAppear {
                            initializeApp()
                        }
                }
            }
            .overlay(
                // Offline banner
                OfflineBannerView(),
                alignment: .top
            )
            .overlay(
                // Error alert
                ErrorAlertView()
            )
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                handleAppBecameActive()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                handleAppWillResignActive()
            }
        }
    }
    
    // MARK: - App Initialization
    
    private func initializeApp() {
        Task {
            await performInitialization()
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isInitialized = true
                }
            }
        }
    }
    
    private func performInitialization() async {
        // Initialize services in parallel
        await withTaskGroup(of: Void.self) { group in
            // Configure push notifications
            group.addTask {
                await pushService.configure()
            }
            
            // Configure RevenueCat
            group.addTask {
                await RevenueCatService.shared.configure()
            }
            
            // Configure Firebase
            group.addTask {
                FirebaseConfiguration.shared.configure()
            }
            
            // Perform data migration if needed
            group.addTask {
                DataMigrationHelper.performMigrationIfNeeded()
            }
            
            // Check authentication status
            group.addTask {
                authManager.checkAuthenticationStatus()
            }
        }
        
        // Perform initial sync if authenticated
        if authManager.isAuthenticated {
            await offlineManager.performSync()
        }
        
        print("App initialization completed")
    }
    
    // MARK: - App Lifecycle Handlers
    
    private func handleAppBecameActive() {
        Task {
            // Refresh authentication status
            authManager.checkAuthenticationStatus()
            
            // Sync data if authenticated and online
            if authManager.isAuthenticated {
                await offlineManager.performSync()
            }
            
            // Clear badge count
            await pushService.clearBadge()
        }
    }
    
    private func handleAppWillResignActive() {
        // Save any pending changes
        persistenceController.save()
    }
}

// MARK: - Splash Screen View

struct SplashScreenView: View {
    @State private var animateIcon = false
    @State private var animateText = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [.black, .purple.opacity(0.3), .black]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // App icon or logo
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.purple)
                    .scaleEffect(animateIcon ? 1.0 : 0.8)
                    .opacity(animateIcon ? 1.0 : 0.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animateIcon)
                
                // App name
                VStack(spacing: 8) {
                    Text("NagAgent")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(animateText ? 1.0 : 0.0)
                        .offset(y: animateText ? 0 : 20)
                    
                    Text("Your Brutally Honest Accountability Coach")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .opacity(animateText ? 1.0 : 0.0)
                        .offset(y: animateText ? 0 : 20)
                }
                .animation(.easeOut(duration: 0.8).delay(0.3), value: animateText)
                
                // Loading indicator
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .opacity(animateText ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.5).delay(0.6), value: animateText)
            }
        }
        .onAppear {
            animateIcon = true
            animateText = true
        }
    }
}

// MARK: - Authentication Flow View

struct AuthenticationFlowView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var currentStep: AuthStep = .welcome
    
    enum AuthStep {
        case welcome
        case login
        case register
        case onboarding
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [.black, .purple.opacity(0.2), .black]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Content
                Group {
                    switch currentStep {
                    case .welcome:
                        WelcomeView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .move(edge: .leading)
                            ))
                    
                    case .login:
                        LoginView()
                            .environmentObject(authViewModel)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .move(edge: .leading)
                            ))
                    
                    case .register:
                        RegisterView()
                            .environmentObject(authViewModel)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .move(edge: .leading)
                            ))
                    
                    case .onboarding:
                        OnboardingFlowView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .move(edge: .leading)
                            ))
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onReceive(authViewModel.$isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                // Authentication successful, main app will take over
            }
        }
    }
}

// MARK: - Main App View

struct MainAppView: View {
    @StateObject private var taskViewModel = TaskViewModel()
    @StateObject private var reportViewModel = ReportViewModel()
    @StateObject private var subscriptionViewModel = SubscriptionViewModel()
    @State private var selectedTab = 0
    @State private var showingSettings = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home/Tasks Tab
            NavigationView {
                HomeView(
                    personality: .sassy, // This should come from user preferences
                    initialGoals: taskViewModel.goals.map { $0.goalText }
                )
                .environmentObject(taskViewModel)
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            .tag(0)
            
            // Reports Tab
            NavigationView {
                ReportsView()
                    .environmentObject(reportViewModel)
            }
            .tabItem {
                Image(systemName: "chart.bar.fill")
                Text("Reports")
            }
            .tag(1)
            
            // Goals Tab
            NavigationView {
                GoalsView()
                    .environmentObject(taskViewModel)
            }
            .tabItem {
                Image(systemName: "target")
                Text("Goals")
            }
            .tag(2)
            
            // Premium Tab
            NavigationView {
                PremiumView()
                    .environmentObject(subscriptionViewModel)
            }
            .tabItem {
                Image(systemName: "star.fill")
                Text("Premium")
            }
            .tag(3)
            
            // Profile Tab
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Image(systemName: "person.fill")
                Text("Profile")
            }
            .tag(4)
        }
        .accentColor(.purple)
        .onAppear {
            setupMainApp()
        }
    }
    
    private func setupMainApp() {
        Task {
            // Load initial data
            await taskViewModel.loadTasks()
            await reportViewModel.loadTodaysReport()
            await subscriptionViewModel.loadSubscriptionStatus()
        }
    }
}

// MARK: - Onboarding Flow View

struct OnboardingFlowView: View {
    @State private var currentPage = 0
    @State private var showingPersonalityQuiz = false
    @State private var showingNotificationPermission = false
    
    var body: some View {
        VStack {
            if showingNotificationPermission {
                NotificationPermissionFlowView()
            } else if showingPersonalityQuiz {
                PersonalityQuizView()
            } else {
                // Welcome onboarding pages
                TabView(selection: $currentPage) {
                    OnboardingPageView(
                        title: "Meet Your Accountability Coach",
                        subtitle: "Get brutally honest feedback and stay motivated",
                        image: "figure.mind.and.body",
                        color: .purple
                    )
                    .tag(0)
                    
                    OnboardingPageView(
                        title: "Set Your Goals",
                        subtitle: "Track daily tasks and build consistent habits",
                        image: "target",
                        color: .blue
                    )
                    .tag(1)
                    
                    OnboardingPageView(
                        title: "Get Roasted",
                        subtitle: "Receive personalized motivation (or harsh truths)",
                        image: "bubble.left.and.bubble.right",
                        color: .orange
                    )
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                Button("Get Started") {
                    showingPersonalityQuiz = true
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
    }
}

struct OnboardingPageView: View {
    let title: String
    let subtitle: String
    let image: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: image)
                .font(.system(size: 100))
                .foregroundColor(color)
            
            VStack(spacing: 16) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding(.top, 100)
    }
}

// MARK: - Placeholder Views (These would be implemented separately)

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack {
            Text("Login View")
                .foregroundColor(.white)
            // Login form implementation would go here
        }
    }
}

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack {
            Text("Register View")
                .foregroundColor(.white)
            // Registration form implementation would go here
        }
    }
}

struct ReportsView: View {
    @EnvironmentObject var reportViewModel: ReportViewModel
    
    var body: some View {
        VStack {
            Text("Reports View")
                .foregroundColor(.white)
            // Reports implementation would go here
        }
    }
}

struct GoalsView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    
    var body: some View {
        VStack {
            Text("Goals View")
                .foregroundColor(.white)
            // Goals management implementation would go here
        }
    }
}

struct PremiumView: View {
    @EnvironmentObject var subscriptionViewModel: SubscriptionViewModel
    
    var body: some View {
        VStack {
            Text("Premium View")
                .foregroundColor(.white)
            // Premium/subscription implementation would go here
        }
    }
}

struct ProfileView: View {
    var body: some View {
        VStack {
            Text("Profile View")
                .foregroundColor(.white)
            // Profile implementation would go here
        }
    }
}