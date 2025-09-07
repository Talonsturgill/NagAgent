import Foundation
import CoreData
import SwiftUI
import Combine

// MARK: - Core Data Stack

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    
    @Published var hasChanges = false
    
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "NagAgent")
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Enable remote change notifications
        container.viewContext.transactionAuthor = "app"
        
        // Observe context changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextDidChange),
            name: .NSManagedObjectContextDidSave,
            object: container.viewContext
        )
        
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    private init() {}
    
    @objc private func contextDidChange() {
        DispatchQueue.main.async {
            self.hasChanges = true
        }
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                hasChanges = false
            } catch {
                print("Failed to save Core Data context: \(error)")
                // Handle the error appropriately
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            container.performBackgroundTask { context in
                do {
                    let result = try block(context)
                    try context.save()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Data Service Protocol

protocol DataServiceProtocol {
    func fetchGoals() throws -> [CDGoal]
    func fetchTasks(for date: Date) throws -> [CDDailyTask]
    func saveGoal(_ goal: Goal) throws -> CDGoal
    func saveTask(_ task: DailyTask) throws -> CDDailyTask
    func deleteGoal(_ goal: CDGoal) throws
    func deleteTask(_ task: CDDailyTask) throws
    func syncWithRemote() async throws
}

// MARK: - Local Data Service

@MainActor
class LocalDataService: ObservableObject, DataServiceProtocol {
    static let shared = LocalDataService()
    
    @Published var goals: [CDGoal] = []
    @Published var todaysTasks: [CDDailyTask] = []
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    
    private let persistenceController = PersistenceController.shared
    private let apiClient = APIClient.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadInitialData()
        observeChanges()
    }
    
    var viewContext: NSManagedObjectContext {
        persistenceController.viewContext
    }
    
    // MARK: - Data Loading
    
    private func loadInitialData() {
        do {
            goals = try fetchGoals()
            todaysTasks = try fetchTasks(for: Date())
        } catch {
            print("Failed to load initial data: \(error)")
        }
    }
    
    private func observeChanges() {
        persistenceController.$hasChanges
            .sink { [weak self] hasChanges in
                if hasChanges {
                    self?.refreshData()
                }
            }
            .store(in: &cancellables)
    }
    
    private func refreshData() {
        do {
            goals = try fetchGoals()
            todaysTasks = try fetchTasks(for: Date())
        } catch {
            print("Failed to refresh data: \(error)")
        }
    }
    
    // MARK: - Goal Management
    
    func fetchGoals() throws -> [CDGoal] {
        let request: NSFetchRequest<CDGoal> = CDGoal.fetchRequest()
        request.predicate = NSPredicate(format: "archivedAt == nil")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDGoal.createdAt, ascending: false)]
        
        return try viewContext.fetch(request)
    }
    
    func saveGoal(_ goal: Goal) throws -> CDGoal {
        // Check if goal already exists
        if let existingGoal = try findGoal(byID: goal.id) {
            updateGoal(existingGoal, with: goal)
            try viewContext.save()
            return existingGoal
        }
        
        // Create new goal
        let cdGoal = CDGoal(context: viewContext)
        cdGoal.id = Int32(goal.id)
        cdGoal.userId = Int32(goal.userId)
        cdGoal.goalText = goal.goalText
        cdGoal.isRecurring = goal.isRecurring
        cdGoal.createdAt = goal.createdAt
        cdGoal.archivedAt = goal.archivedAt
        cdGoal.needsSync = false // Assuming it's from server
        
        try viewContext.save()
        return cdGoal
    }
    
    func deleteGoal(_ goal: CDGoal) throws {
        viewContext.delete(goal)
        try viewContext.save()
    }
    
    func archiveGoal(_ goal: CDGoal) throws {
        goal.archivedAt = Date()
        goal.needsSync = true
        try viewContext.save()
    }
    
    private func findGoal(byID id: Int) throws -> CDGoal? {
        let request: NSFetchRequest<CDGoal> = CDGoal.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        request.fetchLimit = 1
        
        return try viewContext.fetch(request).first
    }
    
    private func updateGoal(_ cdGoal: CDGoal, with goal: Goal) {
        cdGoal.goalText = goal.goalText
        cdGoal.isRecurring = goal.isRecurring
        cdGoal.archivedAt = goal.archivedAt
        cdGoal.needsSync = false
    }
    
    // MARK: - Task Management
    
    func fetchTasks(for date: Date) throws -> [CDDailyTask] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<CDDailyTask> = CDDailyTask.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDDailyTask.createdAt, ascending: true)]
        
        return try viewContext.fetch(request)
    }
    
    func saveTask(_ task: DailyTask) throws -> CDDailyTask {
        // Check if task already exists
        if let existingTask = try findTask(byID: task.id) {
            updateTask(existingTask, with: task)
            try viewContext.save()
            return existingTask
        }
        
        // Create new task
        let cdTask = CDDailyTask(context: viewContext)
        cdTask.id = Int32(task.id)
        cdTask.userId = Int32(task.userId)
        cdTask.goalId = Int32(task.goalId)
        cdTask.date = task.date
        cdTask.completed = task.completed
        cdTask.excuseGiven = task.excuseGiven
        cdTask.completedAt = task.completedAt
        cdTask.createdAt = task.createdAt
        cdTask.needsSync = false
        
        try viewContext.save()
        return cdTask
    }
    
    func updateTask(_ task: CDDailyTask, completed: Bool, excuseGiven: String?) throws {
        task.completed = completed
        task.excuseGiven = excuseGiven
        task.completedAt = completed ? Date() : nil
        task.needsSync = true
        task.lastModified = Date()
        
        try viewContext.save()
    }
    
    func deleteTask(_ task: CDDailyTask) throws {
        viewContext.delete(task)
        try viewContext.save()
    }
    
    private func findTask(byID id: Int) throws -> CDDailyTask? {
        let request: NSFetchRequest<CDDailyTask> = CDDailyTask.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        request.fetchLimit = 1
        
        return try viewContext.fetch(request).first
    }
    
    private func updateTask(_ cdTask: CDDailyTask, with task: DailyTask) {
        cdTask.completed = task.completed
        cdTask.excuseGiven = task.excuseGiven
        cdTask.completedAt = task.completedAt
        cdTask.needsSync = false
    }
    
    // MARK: - Report Management
    
    func saveReport(_ report: DailyReport) throws -> CDDailyReport {
        // Check if report already exists
        if let existingReport = try findReport(for: report.date) {
            updateReport(existingReport, with: report)
            try viewContext.save()
            return existingReport
        }
        
        // Create new report
        let cdReport = CDDailyReport(context: viewContext)
        cdReport.date = report.date
        cdReport.tasksCompleted = Int16(report.tasksCompleted)
        cdReport.tasksTotal = Int16(report.tasksTotal)
        cdReport.completionRate = report.completionRate
        cdReport.excusesMade = Int16(report.excusesMade)
        cdReport.currentStreak = Int16(report.currentStreak)
        cdReport.roast = report.roast
        cdReport.personality = report.personality
        cdReport.ranking = report.ranking != nil ? Int16(report.ranking!) : -1
        cdReport.createdAt = Date()
        
        try viewContext.save()
        return cdReport
    }
    
    private func findReport(for date: Date) throws -> CDDailyReport? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<CDDailyReport> = CDDailyReport.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.fetchLimit = 1
        
        return try viewContext.fetch(request).first
    }
    
    private func updateReport(_ cdReport: CDDailyReport, with report: DailyReport) {
        cdReport.tasksCompleted = Int16(report.tasksCompleted)
        cdReport.tasksTotal = Int16(report.tasksTotal)
        cdReport.completionRate = report.completionRate
        cdReport.excusesMade = Int16(report.excusesMade)
        cdReport.currentStreak = Int16(report.currentStreak)
        cdReport.roast = report.roast
        cdReport.personality = report.personality
        cdReport.ranking = report.ranking != nil ? Int16(report.ranking!) : -1
    }
    
    // MARK: - Sync Management
    
    func syncWithRemote() async throws {
        guard !isSyncing else { return }
        
        await MainActor.run {
            self.isSyncing = true
        }
        
        defer {
            Task { @MainActor in
                self.isSyncing = false
                self.lastSyncDate = Date()
            }
        }
        
        // Sync in background context
        try await persistenceController.performBackgroundTask { context in
            try await self.syncGoals(context: context)
            try await self.syncTasks(context: context)
            try await self.syncReports(context: context)
        }
        
        // Refresh local data
        await MainActor.run {
            self.refreshData()
        }
    }
    
    private func syncGoals(context: NSManagedObjectContext) async throws {
        // Fetch goals that need sync
        let request: NSFetchRequest<CDGoal> = CDGoal.fetchRequest()
        request.predicate = NSPredicate(format: "needsSync == YES")
        
        let goalsToSync = try context.fetch(request)
        
        // Sync each goal
        for cdGoal in goalsToSync {
            do {
                if cdGoal.id > 0 {
                    // Update existing goal
                    let goal = Goal.from(cdGoal)
                    let _: Goal = try await apiClient.put(
                        "/goals/\(cdGoal.id)",
                        body: goal,
                        responseType: Goal.self
                    )
                } else {
                    // Create new goal
                    let goal = Goal.from(cdGoal)
                    let createdGoal: Goal = try await apiClient.post(
                        "/goals",
                        body: goal,
                        responseType: Goal.self
                    )
                    cdGoal.id = Int32(createdGoal.id)
                }
                
                cdGoal.needsSync = false
            } catch {
                print("Failed to sync goal \(cdGoal.id): \(error)")
                // Continue with other goals
            }
        }
        
        // Fetch remote goals
        let remoteGoals: [Goal] = try await apiClient.get("/goals", type: [Goal].self)
        
        // Update local goals with remote data
        for remoteGoal in remoteGoals {
            if let localGoal = try findGoal(byID: remoteGoal.id, context: context) {
                updateGoal(localGoal, with: remoteGoal)
            } else {
                let newGoal = CDGoal(context: context)
                updateGoal(newGoal, with: remoteGoal)
                newGoal.id = Int32(remoteGoal.id)
                newGoal.userId = Int32(remoteGoal.userId)
                newGoal.createdAt = remoteGoal.createdAt
                newGoal.needsSync = false
            }
        }
    }
    
    private func syncTasks(context: NSManagedObjectContext) async throws {
        // Fetch tasks that need sync
        let request: NSFetchRequest<CDDailyTask> = CDDailyTask.fetchRequest()
        request.predicate = NSPredicate(format: "needsSync == YES")
        
        let tasksToSync = try context.fetch(request)
        
        // Sync each task
        for cdTask in tasksToSync {
            do {
                let task = DailyTask.from(cdTask)
                let _: DailyTask = try await apiClient.put(
                    "/tasks/\(cdTask.id)",
                    body: task,
                    responseType: DailyTask.self
                )
                
                cdTask.needsSync = false
            } catch {
                print("Failed to sync task \(cdTask.id): \(error)")
            }
        }
        
        // Fetch today's remote tasks
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: Date())
        
        let remoteTasks: [DailyTask] = try await apiClient.get(
            "/tasks?date=\(todayString)",
            type: [DailyTask].self
        )
        
        // Update local tasks with remote data
        for remoteTask in remoteTasks {
            if let localTask = try findTask(byID: remoteTask.id, context: context) {
                updateTask(localTask, with: remoteTask)
            } else {
                let newTask = CDDailyTask(context: context)
                updateTask(newTask, with: remoteTask)
                newTask.id = Int32(remoteTask.id)
                newTask.userId = Int32(remoteTask.userId)
                newTask.goalId = Int32(remoteTask.goalId)
                newTask.createdAt = remoteTask.createdAt
                newTask.needsSync = false
            }
        }
    }
    
    private func syncReports(context: NSManagedObjectContext) async throws {
        // Fetch recent reports from server
        let reports: [DailyReport] = try await apiClient.get(
            "/reports/history?days=7",
            type: [DailyReport].self
        )
        
        // Update local reports
        for report in reports {
            if let localReport = try findReport(for: report.date, context: context) {
                updateReport(localReport, with: report)
            } else {
                let newReport = CDDailyReport(context: context)
                newReport.date = report.date
                updateReport(newReport, with: report)
                newReport.createdAt = Date()
            }
        }
    }
    
    private func findGoal(byID id: Int, context: NSManagedObjectContext) throws -> CDGoal? {
        let request: NSFetchRequest<CDGoal> = CDGoal.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        request.fetchLimit = 1
        
        return try context.fetch(request).first
    }
    
    private func findTask(byID id: Int, context: NSManagedObjectContext) throws -> CDDailyTask? {
        let request: NSFetchRequest<CDDailyTask> = CDDailyTask.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        request.fetchLimit = 1
        
        return try context.fetch(request).first
    }
    
    private func findReport(for date: Date, context: NSManagedObjectContext) throws -> CDDailyReport? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<CDDailyReport> = CDDailyReport.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.fetchLimit = 1
        
        return try context.fetch(request).first
    }
    
    // MARK: - Offline Support
    
    func getUnsyncedChangesCount() -> Int {
        do {
            let goalRequest: NSFetchRequest<CDGoal> = CDGoal.fetchRequest()
            goalRequest.predicate = NSPredicate(format: "needsSync == YES")
            let unsyncedGoals = try viewContext.count(for: goalRequest)
            
            let taskRequest: NSFetchRequest<CDDailyTask> = CDDailyTask.fetchRequest()
            taskRequest.predicate = NSPredicate(format: "needsSync == YES")
            let unsyncedTasks = try viewContext.count(for: taskRequest)
            
            return unsyncedGoals + unsyncedTasks
        } catch {
            print("Failed to count unsynced changes: \(error)")
            return 0
        }
    }
    
    var hasUnsyncedChanges: Bool {
        return getUnsyncedChangesCount() > 0
    }
}

// MARK: - Core Data Extensions

extension Goal {
    static func from(_ cdGoal: CDGoal) -> Goal {
        return Goal(
            id: Int(cdGoal.id),
            userId: Int(cdGoal.userId),
            goalText: cdGoal.goalText ?? "",
            isRecurring: cdGoal.isRecurring,
            createdAt: cdGoal.createdAt ?? Date(),
            archivedAt: cdGoal.archivedAt,
            dailyTasks: []
        )
    }
}

extension DailyTask {
    static func from(_ cdTask: CDDailyTask) -> DailyTask {
        return DailyTask(
            id: Int(cdTask.id),
            userId: Int(cdTask.userId),
            goalId: Int(cdTask.goalId),
            date: cdTask.date ?? Date(),
            completed: cdTask.completed,
            excuseGiven: cdTask.excuseGiven,
            completedAt: cdTask.completedAt,
            createdAt: cdTask.createdAt ?? Date()
        )
    }
}

extension DailyReport {
    static func from(_ cdReport: CDDailyReport) -> DailyReport {
        return DailyReport(
            date: cdReport.date ?? Date(),
            tasksCompleted: Int(cdReport.tasksCompleted),
            tasksTotal: Int(cdReport.tasksTotal),
            completionRate: cdReport.completionRate,
            excusesMade: Int(cdReport.excusesMade),
            currentStreak: Int(cdReport.currentStreak),
            ranking: cdReport.ranking >= 0 ? Int(cdReport.ranking) : nil,
            roast: cdReport.roast ?? "",
            personality: cdReport.personality ?? "",
            goals: []
        )
    }
}

// MARK: - Data Migration Helper

class DataMigrationHelper {
    static func performMigrationIfNeeded() {
        // Check if migration is needed and perform it
        let userDefaults = UserDefaults.standard
        let currentVersion = 1
        let lastMigrationVersion = userDefaults.integer(forKey: "lastDataMigrationVersion")
        
        if lastMigrationVersion < currentVersion {
            print("Performing data migration from version \(lastMigrationVersion) to \(currentVersion)")
            
            // Perform migration steps here
            // ...
            
            userDefaults.set(currentVersion, forKey: "lastDataMigrationVersion")
        }
    }
}