import Foundation
import Combine
import SwiftUI

// MARK: - Report ViewModel

@MainActor
class ReportViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var dailyReports: [DailyReport] = []
    @Published var currentReport: DailyReport?
    @Published var weeklyStats: WeeklyStatistics?
    @Published var monthlyStats: MonthlyStatistics?
    @Published var isLoading = false
    @Published var isGeneratingReport = false
    @Published var errorMessage: String?
    
    // Report filters
    @Published var selectedDateRange: DateRange = .week
    @Published var selectedDate = Date()
    
    // Report sharing
    @Published var shareableReport: ShareableReport?
    @Published var isShowingShareSheet = false
    
    // MARK: - Private Properties
    private let apiClient = APIClient.shared
    private let errorHandler = ErrorHandler.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        loadTodaysReport()
    }
    
    // MARK: - Public Methods
    
    func loadTodaysReport() async {
        await loadDailyReport(for: Date())
    }
    
    func loadDailyReport(for date: Date) async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        do {
            let report: DailyReport = try await performRequest(
                endpoint: "/reports/daily/\(dateString)",
                method: .GET
            )
            
            currentReport = report
            
            // Add to dailyReports if not already present
            if !dailyReports.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                dailyReports.append(report)
            }
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func generateDailyReport() async -> DailyReport? {
        guard !isGeneratingReport else { return nil }
        
        isGeneratingReport = true
        errorMessage = nil
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())
        
        do {
            let report: DailyReport = try await performRequest(
                endpoint: "/reports/daily/\(dateString)/generate",
                method: .POST
            )
            
            currentReport = report
            
            // Update or add to dailyReports
            if let index = dailyReports.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: Date()) }) {
                dailyReports[index] = report
            } else {
                dailyReports.append(report)
            }
            
            isGeneratingReport = false
            return report
            
        } catch {
            handleError(error)
            isGeneratingReport = false
            return nil
        }
    }
    
    func loadWeeklyStats() async {
        guard !isLoading else { return }
        
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let startDateString = formatter.string(from: startOfWeek)
        
        do {
            let stats: WeeklyStatistics = try await performRequest(
                endpoint: "/reports/weekly",
                method: .GET,
                parameters: ["start_date": startDateString]
            )
            
            weeklyStats = stats
            
        } catch {
            handleError(error)
        }
    }
    
    func loadMonthlyStats() async {
        guard !isLoading else { return }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: selectedDate)
        let firstDayOfMonth = calendar.date(from: components) ?? selectedDate
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let startDateString = formatter.string(from: firstDayOfMonth)
        
        do {
            let stats: MonthlyStatistics = try await performRequest(
                endpoint: "/reports/monthly",
                method: .GET,
                parameters: ["start_date": startDateString]
            )
            
            monthlyStats = stats
            
        } catch {
            handleError(error)
        }
    }
    
    func loadReportHistory(days: Int = 30) async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let historyResponse: ReportHistoryResponse = try await performRequest(
                endpoint: "/reports/history",
                method: .GET,
                parameters: ["days": days]
            )
            
            dailyReports = historyResponse.reports.sorted { $0.date > $1.date }
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func shareReport(_ report: DailyReport) {
        let shareable = ShareableReport(
            date: report.date,
            completionRate: report.completionRate,
            tasksCompleted: report.tasksCompleted,
            tasksTotal: report.tasksTotal,
            excusesMade: report.excusesMade,
            currentStreak: report.currentStreak,
            roast: report.roast,
            personality: report.personality
        )
        
        shareableReport = shareable
        isShowingShareSheet = true
    }
    
    func getInsights(for report: DailyReport) -> [ReportInsight] {
        var insights: [ReportInsight] = []
        
        // Completion rate insights
        if report.completionRate >= 0.8 {
            insights.append(.init(
                type: .achievement,
                title: "Excellent Performance!",
                description: "You completed \(Int(report.completionRate * 100))% of your tasks",
                icon: "star.fill"
            ))
        } else if report.completionRate >= 0.5 {
            insights.append(.init(
                type: .improvement,
                title: "Good Progress",
                description: "You're \(Int((0.8 - report.completionRate) * 100))% away from excellent performance",
                icon: "arrow.up.circle"
            ))
        } else {
            insights.append(.init(
                type: .warning,
                title: "Room for Improvement",
                description: "Focus on completing more tasks tomorrow",
                icon: "exclamationmark.triangle"
            ))
        }
        
        // Streak insights
        if report.currentStreak >= 7 {
            insights.append(.init(
                type: .achievement,
                title: "Week-Long Streak!",
                description: "\(report.currentStreak) days of consistent progress",
                icon: "flame.fill"
            ))
        } else if report.currentStreak >= 3 {
            insights.append(.init(
                type: .encouragement,
                title: "Building Momentum",
                description: "\(report.currentStreak) day streak - keep it going!",
                icon: "chart.line.uptrend.xyaxis"
            ))
        }
        
        // Excuse insights
        if report.excusesMade > report.tasksCompleted {
            insights.append(.init(
                type: .warning,
                title: "Too Many Excuses",
                description: "More excuses than completed tasks - time to focus!",
                icon: "text.bubble"
            ))
        } else if report.excusesMade == 0 && report.tasksTotal > 0 {
            insights.append(.init(
                type: .achievement,
                title: "No Excuses!",
                description: "You stayed focused without making excuses",
                icon: "shield.checkered"
            ))
        }
        
        return insights
    }
    
    func getWeeklyTrend() -> TrendDirection {
        guard dailyReports.count >= 7 else { return .stable }
        
        let recentReports = Array(dailyReports.prefix(7))
        let firstHalf = Array(recentReports.suffix(4).prefix(3))
        let secondHalf = Array(recentReports.prefix(3))
        
        let firstHalfAvg = firstHalf.map { $0.completionRate }.reduce(0, +) / Double(firstHalf.count)
        let secondHalfAvg = secondHalf.map { $0.completionRate }.reduce(0, +) / Double(secondHalf.count)
        
        let difference = secondHalfAvg - firstHalfAvg
        
        if difference > 0.1 {
            return .improving
        } else if difference < -0.1 {
            return .declining
        } else {
            return .stable
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    
    private func performRequest<T: Codable, U: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: T? = nil,
        parameters: [String: Any]? = nil
    ) async throws -> U {
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = ReportAPIRequest<T, U>(
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
            let request = SimpleReportAPIRequest<U>(
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
            case .notFound:
                errorMessage = "Report not found for this date"
            case .serverError(let code, let message):
                errorMessage = message ?? "Server error occurred (Code: \(code))"
            default:
                errorMessage = error.localizedDescription
            }
        } else {
            errorMessage = error.localizedDescription
        }
        
        errorHandler.handle(error)
    }
}

// MARK: - API Request Models

private struct ReportAPIRequest<T: Codable, U: Codable>: APIRequest {
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

private struct SimpleReportAPIRequest<U: Codable>: APIRequest {
    typealias Response = U
    
    let endpoint: String
    let method: HTTPMethod
    let parameters: [String: Any]?
    let body: Data? = nil
    let requiresAuth = true
}

// MARK: - Data Models

struct DailyReport: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let tasksCompleted: Int
    let tasksTotal: Int
    let completionRate: Double
    let excusesMade: Int
    let currentStreak: Int
    let ranking: Int?
    let roast: String
    let personality: String
    let goals: [GoalReport]
    
    enum CodingKeys: String, CodingKey {
        case date
        case tasksCompleted = "tasks_completed"
        case tasksTotal = "tasks_total"
        case completionRate = "completion_rate"
        case excusesMade = "excuses_made"
        case currentStreak = "current_streak"
        case ranking, roast, personality, goals
    }
}

struct GoalReport: Codable, Identifiable {
    let id: Int
    let goalText: String
    let completed: Bool
    let excuseGiven: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case goalText = "goal_text"
        case completed
        case excuseGiven = "excuse_given"
    }
}

struct WeeklyStatistics: Codable {
    let weekStart: Date
    let weekEnd: Date
    let averageCompletionRate: Double
    let totalTasksCompleted: Int
    let totalTasksAssigned: Int
    let bestDay: Date
    let worstDay: Date
    let totalExcuses: Int
    let dailyBreakdown: [DailyBreakdown]
    
    enum CodingKeys: String, CodingKey {
        case weekStart = "week_start"
        case weekEnd = "week_end"
        case averageCompletionRate = "average_completion_rate"
        case totalTasksCompleted = "total_tasks_completed"
        case totalTasksAssigned = "total_tasks_assigned"
        case bestDay = "best_day"
        case worstDay = "worst_day"
        case totalExcuses = "total_excuses"
        case dailyBreakdown = "daily_breakdown"
    }
}

struct MonthlyStatistics: Codable {
    let monthStart: Date
    let monthEnd: Date
    let averageCompletionRate: Double
    let totalTasksCompleted: Int
    let totalTasksAssigned: Int
    let bestWeek: DateInterval
    let worstWeek: DateInterval
    let totalExcuses: Int
    let weeklyBreakdown: [WeeklyBreakdown]
    let topGoals: [GoalPerformance]
    
    enum CodingKeys: String, CodingKey {
        case monthStart = "month_start"
        case monthEnd = "month_end"
        case averageCompletionRate = "average_completion_rate"
        case totalTasksCompleted = "total_tasks_completed"
        case totalTasksAssigned = "total_tasks_assigned"
        case bestWeek = "best_week"
        case worstWeek = "worst_week"
        case totalExcuses = "total_excuses"
        case weeklyBreakdown = "weekly_breakdown"
        case topGoals = "top_goals"
    }
}

struct DailyBreakdown: Codable {
    let date: Date
    let completionRate: Double
    let tasksCompleted: Int
    let tasksTotal: Int
    
    enum CodingKeys: String, CodingKey {
        case date
        case completionRate = "completion_rate"
        case tasksCompleted = "tasks_completed"
        case tasksTotal = "tasks_total"
    }
}

struct WeeklyBreakdown: Codable {
    let weekStart: Date
    let weekEnd: Date
    let completionRate: Double
    let tasksCompleted: Int
    let tasksTotal: Int
    
    enum CodingKeys: String, CodingKey {
        case weekStart = "week_start"
        case weekEnd = "week_end"
        case completionRate = "completion_rate"
        case tasksCompleted = "tasks_completed"
        case tasksTotal = "tasks_total"
    }
}

struct GoalPerformance: Codable, Identifiable {
    let id: Int
    let goalText: String
    let completionRate: Double
    let totalTasks: Int
    let completedTasks: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case goalText = "goal_text"
        case completionRate = "completion_rate"
        case totalTasks = "total_tasks"
        case completedTasks = "completed_tasks"
    }
}

struct ReportHistoryResponse: Codable {
    let reports: [DailyReport]
}

struct ShareableReport: Identifiable {
    let id = UUID()
    let date: Date
    let completionRate: Double
    let tasksCompleted: Int
    let tasksTotal: Int
    let excusesMade: Int
    let currentStreak: Int
    let roast: String
    let personality: String
    
    var shareText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateString = formatter.string(from: date)
        
        let percentComplete = Int(completionRate * 100)
        
        return """
        📊 My NagAgent Report for \(dateString)
        
        ✅ Completed: \(tasksCompleted)/\(tasksTotal) tasks (\(percentComplete)%)
        🔥 Current streak: \(currentStreak) days
        💬 Excuses made: \(excusesMade)
        
        Today's roast from my \(personality) coach:
        "\(roast)"
        
        #NagAgent #Productivity #Accountability
        """
    }
}

struct ReportInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let description: String
    let icon: String
}

enum InsightType {
    case achievement
    case improvement
    case warning
    case encouragement
    
    var color: Color {
        switch self {
        case .achievement: return .green
        case .improvement: return .blue
        case .warning: return .orange
        case .encouragement: return .purple
        }
    }
}

enum DateRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case threeMonths = "3 Months"
    case year = "Year"
    
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .year: return 365
        }
    }
}

enum TrendDirection {
    case improving
    case declining
    case stable
    
    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .declining: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }
    
    var color: Color {
        switch self {
        case .improving: return .green
        case .declining: return .red
        case .stable: return .gray
        }
    }
    
    var description: String {
        switch self {
        case .improving: return "Improving"
        case .declining: return "Needs attention"
        case .stable: return "Stable"
        }
    }
}