import Foundation
import Combine
import SwiftUI
import UserNotifications
// import FirebaseCore
// import FirebaseMessaging

// MARK: - Firebase Configuration Service

class FirebaseConfiguration {
    static let shared = FirebaseConfiguration()
    
    private init() {}
    
    func configure() {
        // Configure Firebase
        // FirebaseApp.configure()
        
        // Configure Firebase Messaging
        // Messaging.messaging().delegate = self
        
        #if DEBUG
        // Enable debug logging in debug builds
        // Messaging.messaging().isAutoInitEnabled = true
        #endif
    }
    
    // Firebase configuration file paths
    var configurationFilePath: String {
        #if DEBUG
        return Bundle.main.path(forResource: "GoogleService-Info-Debug", ofType: "plist") ?? ""
        #else
        return Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") ?? ""
        #endif
    }
}

// MARK: - Push Notification Service

@MainActor
class PushNotificationService: NSObject, ObservableObject {
    static let shared = PushNotificationService()
    
    // MARK: - Published Properties
    @Published var isAuthorized = false
    @Published var fcmToken: String?
    @Published var apnsToken: String?
    @Published var isConfigured = false
    @Published var lastNotificationReceived: Date?
    
    // MARK: - Private Properties
    private let userNotificationCenter = UNUserNotificationCenter.current()
    private var cancellables = Set<AnyCancellable>()
    
    // Notification categories
    private let taskReminderCategory = "TASK_REMINDER"
    private let dailyReportCategory = "DAILY_REPORT"
    private let roastDeliveryCategory = "ROAST_DELIVERY"
    
    override init() {
        super.init()
        setupNotificationCenter()
    }
    
    // MARK: - Configuration
    
    func configure() async {
        // Configure Firebase
        FirebaseConfiguration.shared.configure()
        
        // Set notification delegate
        userNotificationCenter.delegate = self
        
        // Register notification categories
        registerNotificationCategories()
        
        // Check current authorization status
        await checkAuthorizationStatus()
        
        // Set up Firebase Messaging delegate (when Firebase is integrated)
        // Messaging.messaging().delegate = self
        
        isConfigured = true
    }
    
    private func setupNotificationCenter() {
        userNotificationCenter.delegate = self
    }
    
    // MARK: - Permission Management
    
    func requestNotificationPermissions() async -> Bool {
        do {
            let granted = try await userNotificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound, .criticalAlert]
            )
            
            await MainActor.run {
                self.isAuthorized = granted
            }
            
            if granted {
                await registerForPushNotifications()
                await updateNotificationSettings()
            }
            
            return granted
            
        } catch {
            print("Failed to request notification permissions: \(error)")
            return false
        }
    }
    
    func checkAuthorizationStatus() async {
        let settings = await userNotificationCenter.notificationSettings()
        
        await MainActor.run {
            self.isAuthorized = settings.authorizationStatus == .authorized
        }
    }
    
    private func registerForPushNotifications() async {
        await UIApplication.shared.registerForRemoteNotifications()
    }
    
    // MARK: - Token Management
    
    func updateAPNSToken(_ tokenData: Data) {
        let tokenString = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        apnsToken = tokenString
        
        // Set APNS token in Firebase Messaging (when integrated)
        // Messaging.messaging().apnsToken = tokenData
        
        // Send token to backend
        Task {
            await sendTokenToBackend()
        }
    }
    
    func updateFCMToken(_ token: String) {
        fcmToken = token
        
        // Send token to backend
        Task {
            await sendTokenToBackend()
        }
    }
    
    private func sendTokenToBackend() async {
        guard let fcmToken = fcmToken else { return }
        
        let request = TokenUpdateRequest(
            fcmToken: fcmToken,
            apnsToken: apnsToken,
            platform: "ios",
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        )
        
        do {
            let _: MessageResponse = try await APIClient.shared.post(
                "/notifications/token",
                body: request,
                responseType: MessageResponse.self
            )
        } catch {
            print("Failed to update FCM token on backend: \(error)")
        }
    }
    
    // MARK: - Notification Categories
    
    private func registerNotificationCategories() {
        let taskReminderActions = [
            UNNotificationAction(
                identifier: "COMPLETE_TASK",
                title: "Mark Complete",
                options: [.foreground]
            ),
            UNNotificationAction(
                identifier: "MAKE_EXCUSE",
                title: "Make Excuse",
                options: [.foreground]
            ),
            UNNotificationAction(
                identifier: "SNOOZE",
                title: "Remind Later",
                options: []
            )
        ]
        
        let dailyReportActions = [
            UNNotificationAction(
                identifier: "VIEW_REPORT",
                title: "View Report",
                options: [.foreground]
            ),
            UNNotificationAction(
                identifier: "SHARE_REPORT",
                title: "Share",
                options: [.foreground]
            )
        ]
        
        let roastDeliveryActions = [
            UNNotificationAction(
                identifier: "REPLY_ROAST",
                title: "Reply",
                options: [.foreground]
            ),
            UNNotificationAction(
                identifier: "SHARE_ROAST",
                title: "Share",
                options: [.foreground]
            )
        ]
        
        let categories = [
            UNNotificationCategory(
                identifier: taskReminderCategory,
                actions: taskReminderActions,
                intentIdentifiers: []
            ),
            UNNotificationCategory(
                identifier: dailyReportCategory,
                actions: dailyReportActions,
                intentIdentifiers: []
            ),
            UNNotificationCategory(
                identifier: roastDeliveryCategory,
                actions: roastDeliveryActions,
                intentIdentifiers: []
            )
        ]
        
        userNotificationCenter.setNotificationCategories(Set(categories))
    }
    
    // MARK: - Local Notifications
    
    func scheduleTaskReminder(for task: String, at date: Date, taskId: Int) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = "Don't forget: \(task)"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = taskReminderCategory
        content.userInfo = [
            "type": "task_reminder",
            "task_id": taskId,
            "task_text": task
        ]
        
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "task_reminder_\(taskId)_\(Int(date.timeIntervalSince1970))",
            content: content,
            trigger: trigger
        )
        
        do {
            try await userNotificationCenter.add(request)
        } catch {
            print("Failed to schedule task reminder: \(error)")
        }
    }
    
    func scheduleDailyReportNotification(at time: DateComponents) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Daily Report Ready"
        content.body = "Your accountability report is ready. Time to face the truth!"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = dailyReportCategory
        content.userInfo = [
            "type": "daily_report"
        ]
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_report",
            content: content,
            trigger: trigger
        )
        
        do {
            try await userNotificationCenter.add(request)
        } catch {
            print("Failed to schedule daily report notification: \(error)")
        }
    }
    
    func scheduleRoastNotification(roast: String, personality: String) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "\(personality) has something to say..."
        content.body = roast
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = roastDeliveryCategory
        content.userInfo = [
            "type": "roast_delivery",
            "roast": roast,
            "personality": personality
        ]
        
        // Schedule to be delivered immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "roast_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await userNotificationCenter.add(request)
        } catch {
            print("Failed to schedule roast notification: \(error)")
        }
    }
    
    // MARK: - Notification Management
    
    func cancelTaskReminders(for taskId: Int) async {
        let identifiers = await userNotificationCenter.pendingNotificationRequests()
            .filter { $0.identifier.contains("task_reminder_\(taskId)") }
            .map { $0.identifier }
        
        userNotificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func cancelAllNotifications() async {
        userNotificationCenter.removeAllPendingNotificationRequests()
    }
    
    func getBadgeCount() async -> Int {
        return await UIApplication.shared.applicationIconBadgeNumber
    }
    
    func setBadgeCount(_ count: Int) async {
        await UIApplication.shared.applicationIconBadgeNumber = count
    }
    
    func clearBadge() async {
        await setBadgeCount(0)
    }
    
    // MARK: - Settings Management
    
    private func updateNotificationSettings() async {
        let settings = await userNotificationCenter.notificationSettings()
        
        let request = NotificationSettingsRequest(
            isAuthorized: settings.authorizationStatus == .authorized,
            alertSetting: settings.alertSetting == .enabled,
            badgeSetting: settings.badgeSetting == .enabled,
            soundSetting: settings.soundSetting == .enabled,
            criticalAlertSetting: settings.criticalAlertSetting == .enabled,
            timeSensitiveSetting: settings.timeSensitiveSetting == .enabled
        )
        
        do {
            let _: MessageResponse = try await APIClient.shared.post(
                "/notifications/settings",
                body: request,
                responseType: MessageResponse.self
            )
        } catch {
            print("Failed to update notification settings on backend: \(error)")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Handle notification when app is in foreground
        let userInfo = notification.request.content.userInfo
        
        Task { @MainActor in
            self.lastNotificationReceived = Date()
        }
        
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        Task { @MainActor in
            await self.handleNotificationAction(actionIdentifier: actionIdentifier, userInfo: userInfo)
        }
        
        completionHandler()
    }
    
    private func handleNotificationAction(actionIdentifier: String, userInfo: [AnyHashable: Any]) async {
        switch actionIdentifier {
        case "COMPLETE_TASK":
            if let taskId = userInfo["task_id"] as? Int {
                await handleTaskCompletion(taskId: taskId)
            }
            
        case "MAKE_EXCUSE":
            if let taskId = userInfo["task_id"] as? Int {
                await handleMakeExcuse(taskId: taskId)
            }
            
        case "SNOOZE":
            if let taskId = userInfo["task_id"] as? Int,
               let taskText = userInfo["task_text"] as? String {
                await handleSnoozeTask(taskId: taskId, taskText: taskText)
            }
            
        case "VIEW_REPORT":
            await handleViewReport()
            
        case "SHARE_REPORT":
            await handleShareReport()
            
        case "REPLY_ROAST":
            await handleReplyToRoast(userInfo: userInfo)
            
        case "SHARE_ROAST":
            await handleShareRoast(userInfo: userInfo)
            
        case UNNotificationDefaultActionIdentifier:
            // Handle tap on notification body
            await handleNotificationTap(userInfo: userInfo)
            
        default:
            break
        }
    }
    
    // MARK: - Action Handlers
    
    private func handleTaskCompletion(taskId: Int) async {
        // Mark task as completed
        // This would integrate with TaskViewModel
        NotificationCenter.default.post(
            name: .completeTaskFromNotification,
            object: taskId
        )
    }
    
    private func handleMakeExcuse(taskId: Int) async {
        // Open excuse entry screen
        NotificationCenter.default.post(
            name: .makeExcuseFromNotification,
            object: taskId
        )
    }
    
    private func handleSnoozeTask(taskId: Int, taskText: String) async {
        // Schedule reminder for 1 hour later
        let snoozeDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        await scheduleTaskReminder(for: taskText, at: snoozeDate, taskId: taskId)
    }
    
    private func handleViewReport() async {
        // Open daily report screen
        NotificationCenter.default.post(name: .viewDailyReport, object: nil)
    }
    
    private func handleShareReport() async {
        // Open share report screen
        NotificationCenter.default.post(name: .shareDailyReport, object: nil)
    }
    
    private func handleReplyToRoast(userInfo: [AnyHashable: Any]) async {
        // Open roast reply screen
        NotificationCenter.default.post(
            name: .replyToRoast,
            object: userInfo
        )
    }
    
    private func handleShareRoast(userInfo: [AnyHashable: Any]) async {
        // Share roast
        if let roast = userInfo["roast"] as? String {
            NotificationCenter.default.post(
                name: .shareRoast,
                object: roast
            )
        }
    }
    
    private func handleNotificationTap(userInfo: [AnyHashable: Any]) async {
        guard let type = userInfo["type"] as? String else { return }
        
        switch type {
        case "task_reminder":
            if let taskId = userInfo["task_id"] as? Int {
                NotificationCenter.default.post(
                    name: .openTaskDetails,
                    object: taskId
                )
            }
            
        case "daily_report":
            NotificationCenter.default.post(name: .viewDailyReport, object: nil)
            
        case "roast_delivery":
            NotificationCenter.default.post(
                name: .viewRoast,
                object: userInfo
            )
            
        default:
            break
        }
    }
}

// MARK: - Firebase Messaging Delegate (When Firebase is integrated)

/*
extension PushNotificationService: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        
        Task { @MainActor in
            self.updateFCMToken(fcmToken)
        }
    }
}
*/

// MARK: - Notification Models

struct TokenUpdateRequest: Codable {
    let fcmToken: String
    let apnsToken: String?
    let platform: String
    let appVersion: String
    
    enum CodingKeys: String, CodingKey {
        case fcmToken = "fcm_token"
        case apnsToken = "apns_token"
        case platform
        case appVersion = "app_version"
    }
}

struct NotificationSettingsRequest: Codable {
    let isAuthorized: Bool
    let alertSetting: Bool
    let badgeSetting: Bool
    let soundSetting: Bool
    let criticalAlertSetting: Bool
    let timeSensitiveSetting: Bool
    
    enum CodingKeys: String, CodingKey {
        case isAuthorized = "is_authorized"
        case alertSetting = "alert_setting"
        case badgeSetting = "badge_setting"
        case soundSetting = "sound_setting"
        case criticalAlertSetting = "critical_alert_setting"
        case timeSensitiveSetting = "time_sensitive_setting"
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let completeTaskFromNotification = Notification.Name("completeTaskFromNotification")
    static let makeExcuseFromNotification = Notification.Name("makeExcuseFromNotification")
    static let viewDailyReport = Notification.Name("viewDailyReport")
    static let shareDailyReport = Notification.Name("shareDailyReport")
    static let replyToRoast = Notification.Name("replyToRoast")
    static let shareRoast = Notification.Name("shareRoast")
    static let openTaskDetails = Notification.Name("openTaskDetails")
    static let viewRoast = Notification.Name("viewRoast")
}

// MARK: - Notification Permission Helper

struct NotificationPermissionView: View {
    @StateObject private var pushService = PushNotificationService.shared
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 20) {
            if !pushService.isAuthorized {
                VStack(spacing: 16) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("Enable Notifications")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Get personalized roasts, task reminders, and daily reports delivered right to your phone.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    Button("Enable Notifications") {
                        Task {
                            let granted = await pushService.requestNotificationPermissions()
                            if !granted {
                                showingSettings = true
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Not Now") {
                        // Handle dismiss
                    }
                    .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .alert("Notifications Disabled", isPresented: $showingSettings) {
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To receive notifications, please enable them in Settings > Notifications > NagAgent")
        }
    }
}