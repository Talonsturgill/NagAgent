import Foundation
import Combine
import SwiftUI

// MARK: - Task ViewModel

@MainActor
class TaskViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var goals: [Goal] = []
    @Published var todaysTasks: [DailyTask] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var lastSyncDate: Date?
    
    // Task creation
    @Published var newGoalText = ""
    @Published var isNewGoalRecurring = true
    
    // Statistics
    @Published var completionRate: Double = 0.0
    @Published var currentStreak: Int = 0
    @Published var totalCompletedTasks: Int = 0
    
    // MARK: - Private Properties
    private let apiClient = APIClient.shared
    private let errorHandler = ErrorHandler.shared
    private var cancellables = Set<AnyCancellable>()
    private var syncTimer: Timer?
    
    // MARK: - Initialization
    init() {
        setupAutoSync()
        calculateStatistics()
    }
    
    // MARK: - Public Methods
    
    func loadTasks() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.fetchGoals()
            }
            
            group.addTask {
                await self.fetchTodaysTasks()
            }
            
            group.addTask {
                await self.fetchUserStatistics()
            }
        }
        
        calculateStatistics()
        lastSyncDate = Date()
        isLoading = false
    }
    
    func refreshTasks() async {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        await loadTasks()
        isRefreshing = false
    }
    
    func createGoal() async {
        guard !newGoalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let trimmedText = newGoalText.trimmingCharacters(in: .whitespacesAndNewlines)
        let request = CreateGoalRequest(goalText: trimmedText, isRecurring: isNewGoalRecurring)
        
        do {
            let newGoal: Goal = try await performRequest(
                endpoint: "/goals",
                method: .POST,
                body: request
            )
            
            goals.append(newGoal)
            newGoalText = ""
            
            // Refresh today's tasks to include the new goal
            await fetchTodaysTasks()
            
        } catch {
            handleError(error)
        }
    }
    
    func updateGoal(_ goal: Goal, text: String) async {
        let request = UpdateGoalRequest(goalText: text, isRecurring: goal.isRecurring)
        
        do {
            let updatedGoal: Goal = try await performRequest(
                endpoint: "/goals/\(goal.id)",
                method: .PUT,
                body: request
            )
            
            if let index = goals.firstIndex(where: { $0.id == goal.id }) {
                goals[index] = updatedGoal
            }
            
        } catch {
            handleError(error)
        }
    }
    
    func deleteGoal(_ goal: Goal) async {
        do {
            let _: MessageResponse = try await performRequest(
                endpoint: "/goals/\(goal.id)",
                method: .DELETE
            )
            
            goals.removeAll { $0.id == goal.id }
            todaysTasks.removeAll { $0.goalId == goal.id }
            calculateStatistics()
            
        } catch {
            handleError(error)
        }
    }
    
    func archiveGoal(_ goal: Goal) async {
        do {
            let archivedGoal: Goal = try await performRequest(
                endpoint: "/goals/\(goal.id)/archive",
                method: .POST
            )
            
            if let index = goals.firstIndex(where: { $0.id == goal.id }) {
                goals[index] = archivedGoal
            }
            
            // Remove from today's tasks
            todaysTasks.removeAll { $0.goalId == goal.id }
            calculateStatistics()
            
        } catch {
            handleError(error)
        }
    }
    
    func completeTask(_ task: DailyTask) async {
        let request = UpdateTaskRequest(completed: true, excuseGiven: nil)
        
        do {
            let updatedTask: DailyTask = try await performRequest(
                endpoint: "/tasks/\(task.id)",
                method: .PUT,
                body: request
            )
            
            updateTaskInList(updatedTask)
            calculateStatistics()
            
        } catch {
            handleError(error)
        }
    }
    
    func uncompleteTask(_ task: DailyTask) async {
        let request = UpdateTaskRequest(completed: false, excuseGiven: nil)
        
        do {
            let updatedTask: DailyTask = try await performRequest(
                endpoint: "/tasks/\(task.id)",
                method: .PUT,
                body: request
            )
            
            updateTaskInList(updatedTask)
            calculateStatistics()
            
        } catch {
            handleError(error)
        }
    }
    
    func submitExcuse(for task: DailyTask, excuse: String) async {
        let request = UpdateTaskRequest(completed: false, excuseGiven: excuse.trimmingCharacters(in: .whitespacesAndNewlines))
        
        do {
            let updatedTask: DailyTask = try await performRequest(
                endpoint: "/tasks/\(task.id)",
                method: .PUT,
                body: request
            )
            
            updateTaskInList(updatedTask)
            
            // Request a roast for the excuse
            await requestExcuseRoast(for: task, excuse: excuse)
            
        } catch {
            handleError(error)
        }
    }
    
    func requestMorningRoast() async -> String? {
        let context = RoastContext(
            taskCount: todaysTasks.count,
            completedCount: todaysTasks.filter { $0.completed }.count,
            currentStreak: currentStreak,
            timeOfDay: "morning"
        )
        
        do {
            let roastResponse: RoastResponse = try await performRequest(
                endpoint: "/roasts/morning",
                method: .POST,
                body: context
            )
            
            return roastResponse.roast
            
        } catch {
            handleError(error)
            return nil
        }
    }
    
    func requestCompletionRoast() async -> String? {
        let context = RoastContext(
            taskCount: todaysTasks.count,
            completedCount: todaysTasks.filter { $0.completed }.count,
            currentStreak: currentStreak,
            timeOfDay: "completion"
        )
        
        do {
            let roastResponse: RoastResponse = try await performRequest(
                endpoint: "/roasts/completion",
                method: .POST,
                body: context
            )
            
            return roastResponse.roast
            
        } catch {
            handleError(error)
            return nil
        }
    }
    
    func generateTasksForDate(_ date: Date) async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        do {
            let tasks: [DailyTask] = try await performRequest(
                endpoint: "/tasks/generate/\(dateString)",
                method: .POST
            )
            
            // Update today's tasks if generating for today
            if Calendar.current.isDate(date, inSameDayAs: Date()) {
                todaysTasks = tasks
                calculateStatistics()
            }
            
        } catch {
            handleError(error)
        }
    }
    
    func getTaskHistory(days: Int = 30) async -> [DailyTask] {
        do {
            let historyResponse: TaskHistoryResponse = try await performRequest(
                endpoint: "/tasks/history",
                method: .GET,
                parameters: ["days": days]
            )
            
            return historyResponse.tasks
            
        } catch {
            handleError(error)
            return []
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    
    private func fetchGoals() async {
        do {
            let goalsResponse: GoalsResponse = try await performRequest(
                endpoint: "/goals",
                method: .GET
            )
            
            goals = goalsResponse.goals.filter { $0.archivedAt == nil }
            
        } catch {
            handleError(error)
        }
    }
    
    private func fetchTodaysTasks() async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        
        do {
            let tasksResponse: TasksResponse = try await performRequest(
                endpoint: "/tasks",
                method: .GET,
                parameters: ["date": today]
            )
            
            todaysTasks = tasksResponse.tasks
            
        } catch {
            handleError(error)
        }
    }
    
    private func fetchUserStatistics() async {
        do {
            let stats: UserStatistics = try await performRequest(
                endpoint: "/users/stats",
                method: .GET
            )
            
            currentStreak = stats.currentStreak
            totalCompletedTasks = stats.totalCompletedTasks
            
        } catch {
            handleError(error)
        }
    }
    
    private func requestExcuseRoast(for task: DailyTask, excuse: String) async {
        guard let goal = goals.first(where: { $0.id == task.goalId }) else { return }
        
        let context = ExcuseRoastContext(
            excuse: excuse,
            taskText: goal.goalText,
            currentStreak: currentStreak
        )
        
        do {
            let roastResponse: RoastResponse = try await performRequest(
                endpoint: "/roasts/excuse",
                method: .POST,
                body: context
            )
            
            // Could emit the roast through a notification or delegate
            NotificationCenter.default.post(
                name: .newRoastReceived,
                object: roastResponse.roast
            )
            
        } catch {
            // Don't show error for roast requests
            print("Failed to get excuse roast: \(error)")
        }
    }
    
    private func updateTaskInList(_ updatedTask: DailyTask) {
        if let index = todaysTasks.firstIndex(where: { $0.id == updatedTask.id }) {
            todaysTasks[index] = updatedTask
        }
    }
    
    private func calculateStatistics() {
        let completedCount = todaysTasks.filter { $0.completed }.count
        let totalCount = todaysTasks.count
        
        if totalCount > 0 {
            completionRate = Double(completedCount) / Double(totalCount)
        } else {
            completionRate = 0.0
        }
    }
    
    private func setupAutoSync() {
        // Sync every 5 minutes when app is active
        syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                if let self = self, !self.isLoading {
                    await self.refreshTasks()
                }
            }
        }
        
        // Sync when app becomes active
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.refreshTasks()
                }
            }
            .store(in: &cancellables)
    }
    
    private func performRequest<T: Codable, U: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: T? = nil,
        parameters: [String: Any]? = nil
    ) async throws -> U {
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = TaskAPIRequest<T, U>(
                endpoint: endpoint,
                method: method,
                body: body,
                parameters: parameters
            )
            
            apiClient.requestWithAuth(request)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { response in
                        continuation.resume(returning: response)
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    private func performRequest<U: Codable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: [String: Any]? = nil
    ) async throws -> U {
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = SimpleTaskAPIRequest<U>(
                endpoint: endpoint,
                method: method,
                parameters: parameters
            )
            
            apiClient.requestWithAuth(request)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { response in
                        continuation.resume(returning: response)
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    private func handleError(_ error: Error) {
        if let apiError = error as? APIError {
            switch apiError {
            case .networkError:
                errorMessage = "Please check your internet connection"
            case .unauthorized:
                errorMessage = "Session expired. Please log in again"
                AuthenticationStateManager.shared.logout()
            case .serverError(let code, let message):
                errorMessage = message ?? "Server error occurred (Code: \(code))"
            case .rateLimited:
                errorMessage = "Too many requests. Please try again later"
            default:
                errorMessage = error.localizedDescription
            }
        } else {
            errorMessage = error.localizedDescription
        }
        
        errorHandler.handle(error)
    }
    
    deinit {
        syncTimer?.invalidate()
    }
}

// MARK: - API Request Models

private struct TaskAPIRequest<T: Codable, U: Codable>: APIRequest {
    typealias Response = U
    
    let endpoint: String
    let method: HTTPMethod
    let body: Data?
    let parameters: [String: Any]?
    let requiresAuth = true
    
    init(endpoint: String, method: HTTPMethod, body: T?, parameters: [String: Any]? = nil) {
        self.endpoint = endpoint
        self.method = method
        self.parameters = parameters
        
        if let body = body {
            do {
                self.body = try JSONEncoder().encode(body)
            } catch {
                self.body = nil
                print("Failed to encode request body: \(error)")
            }
        } else {
            self.body = nil
        }
    }
}

private struct SimpleTaskAPIRequest<U: Codable>: APIRequest {
    typealias Response = U
    
    let endpoint: String
    let method: HTTPMethod
    let parameters: [String: Any]?
    let body: Data? = nil
    let requiresAuth = true
}

// MARK: - Request/Response Models

struct CreateGoalRequest: Codable {
    let goalText: String
    let isRecurring: Bool
    
    enum CodingKeys: String, CodingKey {
        case goalText = "goal_text"
        case isRecurring = "is_recurring"
    }
}

struct UpdateGoalRequest: Codable {
    let goalText: String
    let isRecurring: Bool
    
    enum CodingKeys: String, CodingKey {
        case goalText = "goal_text"
        case isRecurring = "is_recurring"
    }
}

struct UpdateTaskRequest: Codable {
    let completed: Bool
    let excuseGiven: String?
    
    enum CodingKeys: String, CodingKey {
        case completed
        case excuseGiven = "excuse_given"
    }
}

struct GoalsResponse: Codable {
    let goals: [Goal]
}

struct TasksResponse: Codable {
    let tasks: [DailyTask]
}

struct TaskHistoryResponse: Codable {
    let tasks: [DailyTask]
}

struct UserStatistics: Codable {
    let currentStreak: Int
    let totalCompletedTasks: Int
    let averageCompletionRate: Double
    let totalGoals: Int
    
    enum CodingKeys: String, CodingKey {
        case currentStreak = "current_streak"
        case totalCompletedTasks = "total_completed_tasks"
        case averageCompletionRate = "average_completion_rate"
        case totalGoals = "total_goals"
    }
}

struct RoastContext: Codable {
    let taskCount: Int
    let completedCount: Int
    let currentStreak: Int
    let timeOfDay: String
    
    enum CodingKeys: String, CodingKey {
        case taskCount = "task_count"
        case completedCount = "completed_count"
        case currentStreak = "current_streak"
        case timeOfDay = "time_of_day"
    }
}

struct ExcuseRoastContext: Codable {
    let excuse: String
    let taskText: String
    let currentStreak: Int
    
    enum CodingKeys: String, CodingKey {
        case excuse
        case taskText = "task_text"
        case currentStreak = "current_streak"
    }
}

struct RoastResponse: Codable {
    let roast: String
    let personality: String
    let shareable: Bool
}

// MARK: - Notification Names

extension Notification.Name {
    static let newRoastReceived = Notification.Name("newRoastReceived")
}

// MARK: - Convenience Extensions

extension TaskViewModel {
    var completedTasks: [DailyTask] {
        todaysTasks.filter { $0.completed }
    }
    
    var incompleteTasks: [DailyTask] {
        todaysTasks.filter { !$0.completed }
    }
    
    var tasksWithExcuses: [DailyTask] {
        todaysTasks.filter { $0.excuseGiven != nil }
    }
    
    func getGoal(for task: DailyTask) -> Goal? {
        goals.first { $0.id == task.goalId }
    }
    
    func getTasksForGoal(_ goal: Goal) -> [DailyTask] {
        todaysTasks.filter { $0.goalId == goal.id }
    }
}