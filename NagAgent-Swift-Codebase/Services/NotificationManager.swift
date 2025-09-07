import Foundation
import Combine
import SwiftUI
import UserNotifications

// MARK: - Notification Manager

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    // MARK: - Published Properties
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isProcessingPermissionRequest = false
    @Published var hasRequestedPermissions = false
    @Published var notificationSettings: UNNotificationSettings?
    @Published var scheduledNotifications: [ScheduledNotification] = []
    
    // MARK: - Private Properties
    private let pushService = PushNotificationService.shared
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    // Keys for UserDefaults
    private let hasRequestedPermissionsKey = "hasRequestedNotificationPermissions"
    private let lastPermissionRequestDateKey = "lastNotificationPermissionRequestDate"
    
    // MARK: - Initialization
    
    private init() {
        loadStoredSettings()
        observeAppLifecycle()
        observeAuthChanges()
    }
    
    // MARK: - Permission Management
    
    func checkAndRequestPermissions() async {
        await updateAuthorizationStatus()
        
        switch authorizationStatus {
        case .notDetermined:
            await requestPermissions()
        case .denied:
            // Don't automatically request again if denied
            break
        case .authorized, .provisional, .ephemeral:
            // Already authorized
            break
        @unknown default:
            break
        }
    }
    
    func requestPermissions() async {
        guard !isProcessingPermissionRequest else { return }
        
        isProcessingPermissionRequest = true
        hasRequestedPermissions = true
        
        // Store that we've requested permissions
        userDefaults.set(true, forKey: hasRequestedPermissionsKey)
        userDefaults.set(Date(), forKey: lastPermissionRequestDateKey)
        
        let granted = await pushService.requestNotificationPermissions()
        
        await updateAuthorizationStatus()
        await loadNotificationSettings()
        
        if granted {
            await configureNotificationSchedule()
        }
        
        isProcessingPermissionRequest = false
    }
    
    func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsUrl)
    }
    
    func updateAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
        notificationSettings = settings
    }
    
    private func loadNotificationSettings() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationSettings = settings
    }
    
    // MARK: - Notification Scheduling
    
    func configureNotificationSchedule() async {
        guard authorizationStatus == .authorized else { return }
        
        // Cancel existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.scheduleDailyReminders()
            }
            
            group.addTask {
                await self.scheduleWeeklyReports()
            }
            
            group.addTask {
                await self.scheduleMotivationalMessages()
            }
        }
        
        await loadScheduledNotifications()
    }
    
    private func scheduleDailyReminders() async {
        // Schedule daily task reminders
        let reminderTimes = getUserNotificationTimes()
        
        for time in reminderTimes {
            var dateComponents = DateComponents()
            dateComponents.hour = time.hour
            dateComponents.minute = time.minute
            
            await scheduleRepeatingNotification(
                identifier: "daily_reminder_\(time.hour)_\(time.minute)",
                title: "Time to Check Your Goals!",
                body: "Your accountability coach is waiting. Don't disappoint them (more than usual).",
                dateComponents: dateComponents,
                categoryIdentifier: "daily_reminder"
            )
        }
    }
    
    private func scheduleWeeklyReports() async {
        // Schedule weekly summary every Sunday at 8 PM
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        await scheduleRepeatingNotification(
            identifier: "weekly_report",
            title: "Weekly Reality Check",
            body: "Your weekly performance report is ready. Prepare for judgment.",
            dateComponents: dateComponents,
            categoryIdentifier: "weekly_report"
        )
    }
    
    private func scheduleMotivationalMessages() async {
        // Schedule motivational (roasting) messages
        let motivationTimes = [
            (hour: 7, minute: 0, message: "Rise and shine! Time to disappoint your goals again."),
            (hour: 12, minute: 0, message: "Lunch break procrastination level: Expert."),
            (hour: 18, minute: 0, message: "End of day check-in. How many excuses did you make?"),
            (hour: 21, minute: 0, message: "Evening reflection time. Today's failure rate: TBD.")
        ]
        
        for (index, time) in motivationTimes.enumerated() {
            var dateComponents = DateComponents()
            dateComponents.hour = time.hour
            dateComponents.minute = time.minute
            
            await scheduleRepeatingNotification(
                identifier: "motivation_\(index)",
                title: "Motivation Check",
                body: time.message,
                dateComponents: dateComponents,
                categoryIdentifier: "motivation"
            )
        }
    }
    
    private func scheduleRepeatingNotification(
        identifier: String,
        title: String,
        body: String,
        dateComponents: DateComponents,
        categoryIdentifier: String
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule notification \(identifier): \(error)")
        }
    }
    
    // MARK: - Task-Specific Notifications
    
    func scheduleTaskDeadlineReminder(taskId: Int, taskText: String, deadline: Date) async {
        guard authorizationStatus == .authorized else { return }
        
        // Schedule notification 1 hour before deadline
        let reminderDate = Calendar.current.date(byAdding: .hour, value: -1, to: deadline) ?? deadline
        
        guard reminderDate > Date() else { return } // Don't schedule past notifications
        
        let content = UNMutableNotificationContent()
        content.title = "Task Deadline Approaching"
        content.body = "⚠️ '\(taskText)' is due in 1 hour. Time to panic!"
        content.sound = .default
        content.categoryIdentifier = "task_deadline"
        content.userInfo = [
            "task_id": taskId,
            "task_text": taskText,
            "deadline": deadline.timeIntervalSince1970
        ]
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "task_deadline_\(taskId)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule task deadline reminder: \(error)")
        }
    }
    
    func cancelTaskNotifications(taskId: Int) {
        let identifiers = [
            "task_deadline_\(taskId)",
            "task_reminder_\(taskId)"
        ]
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    // MARK: - Excuse-Based Notifications
    
    func scheduleExcusePenaltyNotification(excuse: String, taskText: String) async {
        guard authorizationStatus == .authorized else { return }
        
        // Schedule a "penalty" notification for 30 minutes later
        let penaltyDate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        
        let roastMessages = [
            "Still thinking about that excuse for '\(taskText)'? Time for round 2!",
            "Your excuse '\(excuse)' doesn't excuse you from judgment.",
            "Excuses: 1, Progress: 0. The scoreboard speaks.",
            "That excuse aged like milk. How's the task coming along?"
        ]
        
        let content = UNMutableNotificationContent()
        content.title = "Excuse Follow-up"
        content.body = roastMessages.randomElement() ?? "Time to actually do the thing."
        content.sound = .default
        content.categoryIdentifier = "excuse_penalty"
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: penaltyDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "excuse_penalty_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule excuse penalty notification: \(error)")
        }
    }
    
    // MARK: - Achievement Notifications
    
    func scheduleAchievementNotification(achievement: Achievement) async {
        guard authorizationStatus == .authorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Achievement Unlocked! 🏆"
        content.body = achievement.description
        content.sound = .default
        content.categoryIdentifier = "achievement"
        content.userInfo = [
            "achievement_id": achievement.id,
            "achievement_type": achievement.type.rawValue
        ]
        
        // Deliver immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "achievement_\(achievement.id)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule achievement notification: \(error)")
        }
    }
    
    // MARK: - Streak Notifications
    
    func scheduleStreakNotification(streakDays: Int) async {
        guard authorizationStatus == .authorized, streakDays > 0 else { return }
        
        let streakMessages: [String] = {
            switch streakDays {
            case 1:
                return ["One day down! Don't get cocky.", "Day 1: The beginning of something... maybe."]
            case 2...6:
                return ["\(streakDays) days! You're on a roll (a small one).", "\(streakDays)-day streak! Don't mess this up."]
            case 7:
                return ["One week streak! 🔥 Now you're just showing off.", "7 days strong! Your consistency is... suspicious."]
            case 14:
                return ["Two weeks! 💪 Are you even human?", "14-day streak! The impossible has happened."]
            case 30:
                return ["30-day streak! 🏆 Legend status achieved.", "One month! Your excuses must be so lonely."]
            default:
                return ["\(streakDays)-day streak! You're unstoppable! 🚀", "Day \(streakDays)! Your consistency is frightening."]
            }
        }()
        
        let content = UNMutableNotificationContent()
        content.title = "Streak Alert! 🔥"
        content.body = streakMessages.randomElement() ?? "Streak milestone reached!"
        content.sound = .default
        content.categoryIdentifier = "streak"
        content.userInfo = ["streak_days": streakDays]
        
        // Deliver immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "streak_\(streakDays)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule streak notification: \(error)")
        }
    }
    
    // MARK: - Utility Methods
    
    func loadScheduledNotifications() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        
        scheduledNotifications = requests.compactMap { request in
            guard let trigger = request.trigger as? UNCalendarNotificationTrigger else { return nil }
            
            return ScheduledNotification(
                identifier: request.identifier,
                title: request.content.title,
                body: request.content.body,
                categoryIdentifier: request.content.categoryIdentifier,
                nextTriggerDate: trigger.nextTriggerDate()
            )
        }.sorted { ($0.nextTriggerDate ?? Date.distantFuture) < ($1.nextTriggerDate ?? Date.distantFuture) }
    }
    
    private func getUserNotificationTimes() -> [(hour: Int, minute: Int)] {
        // Get user's preferred notification times from settings
        // For now, return default times
        return [
            (hour: 9, minute: 0),   // 9 AM
            (hour: 14, minute: 0),  // 2 PM
            (hour: 19, minute: 0)   // 7 PM
        ]
    }
    
    private func loadStoredSettings() {
        hasRequestedPermissions = userDefaults.bool(forKey: hasRequestedPermissionsKey)
    }
    
    // MARK: - App Lifecycle Observers
    
    private func observeAppLifecycle() {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.updateAuthorizationStatus()
                    await self?.loadScheduledNotifications()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.pushService.clearBadge()
                }
            }
            .store(in: &cancellables)
    }
    
    private func observeAuthChanges() {
        AuthenticationStateManager.shared.$isAuthenticated
            .dropFirst()
            .sink { [weak self] isAuthenticated in
                Task { @MainActor in
                    if isAuthenticated {
                        await self?.configureNotificationSchedule()
                    } else {
                        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Permission Helper Methods
    
    var shouldShowPermissionPrompt: Bool {
        authorizationStatus == .notDetermined && !hasRequestedPermissions
    }
    
    var shouldShowSettingsPrompt: Bool {
        authorizationStatus == .denied && hasRequestedPermissions
    }
    
    var canScheduleNotifications: Bool {
        authorizationStatus == .authorized
    }
    
    var permissionStatusMessage: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Notifications not configured"
        case .denied:
            return "Notifications disabled"
        case .authorized:
            return "Notifications enabled"
        case .provisional:
            return "Quiet notifications enabled"
        case .ephemeral:
            return "Temporary notifications enabled"
        @unknown default:
            return "Unknown notification status"
        }
    }
}

// MARK: - Supporting Models

struct ScheduledNotification: Identifiable {
    let id = UUID()
    let identifier: String
    let title: String
    let body: String
    let categoryIdentifier: String
    let nextTriggerDate: Date?
}

struct Achievement {
    let id: String
    let type: AchievementType
    let title: String
    let description: String
    let iconName: String
    let isUnlocked: Bool
    let unlockedDate: Date?
    
    enum AchievementType: String, CaseIterable {
        case firstTask = "first_task"
        case firstWeek = "first_week"
        case perfectDay = "perfect_day"
        case weekStreak = "week_streak"
        case monthStreak = "month_streak"
        case noExcuses = "no_excuses"
        case earlyBird = "early_bird"
        case nightOwl = "night_owl"
    }
}

// MARK: - Notification Permission Flow View

struct NotificationPermissionFlowView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "bell.badge")
                        .font(.system(size: 80))
                        .foregroundColor(.purple)
                    
                    Text("Stay Accountable")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Get personalized reminders, roasts, and progress updates to keep you on track.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                
                // Features
                VStack(alignment: .leading, spacing: 20) {
                    PermissionFeatureRow(
                        icon: "alarm",
                        title: "Smart Reminders",
                        description: "Never miss a deadline with timely nudges"
                    )
                    
                    PermissionFeatureRow(
                        icon: "chart.bar",
                        title: "Progress Updates",
                        description: "Daily and weekly performance reports"
                    )
                    
                    PermissionFeatureRow(
                        icon: "message",
                        title: "Personalized Roasts",
                        description: "Motivational messages tailored to your personality"
                    )
                    
                    PermissionFeatureRow(
                        icon: "trophy",
                        title: "Achievement Alerts",
                        description: "Celebrate your wins (when you actually win)"
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await notificationManager.requestPermissions()
                            if notificationManager.authorizationStatus == .authorized {
                                dismiss()
                            }
                        }
                    }) {
                        Text("Enable Notifications")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(12)
                    }
                    .disabled(notificationManager.isProcessingPermissionRequest)
                    
                    Button("Maybe Later") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

struct PermissionFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.purple)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}