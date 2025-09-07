import Foundation
import Combine
import Network
import SwiftUI

// MARK: - Offline Manager

@MainActor
class OfflineManager: ObservableObject {
    static let shared = OfflineManager()
    
    // MARK: - Published Properties
    @Published var isOnline = true
    @Published var connectionType: ConnectionType = .wifi
    @Published var isSyncing = false
    @Published var pendingChanges = 0
    @Published var lastSyncDate: Date?
    @Published var syncProgress: SyncProgress = SyncProgress()
    @Published var showOfflineBanner = false
    
    // MARK: - Private Properties
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "NetworkMonitor")
    private let dataService = LocalDataService.shared
    private var cancellables = Set<AnyCancellable>()
    private var syncTimer: Timer?
    
    // Sync settings
    private let autoSyncInterval: TimeInterval = 300 // 5 minutes
    private let retryInterval: TimeInterval = 30 // 30 seconds
    private let maxRetryAttempts = 3
    
    // MARK: - Initialization
    
    private init() {
        startNetworkMonitoring()
        setupAutoSync()
        observeDataChanges()
        loadLastSyncDate()
    }
    
    // MARK: - Network Monitoring
    
    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateConnectionStatus(path)
            }
        }
        
        networkMonitor.start(queue: networkQueue)
    }
    
    private func updateConnectionStatus(_ path: NWPath) {
        let wasOnline = isOnline
        isOnline = path.status == .satisfied
        
        // Determine connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else {
            connectionType = .unknown
        }
        
        // Show/hide offline banner
        showOfflineBanner = !isOnline
        
        // If we just came online, trigger sync
        if !wasOnline && isOnline {
            Task {
                await performSync()
            }
        }
        
        print("Network status changed: \(isOnline ? "Online" : "Offline") (\(connectionType))")
    }
    
    // MARK: - Auto Sync
    
    private func setupAutoSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: autoSyncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performAutoSync()
            }
        }
    }
    
    private func performAutoSync() async {
        guard isOnline && !isSyncing else { return }
        
        // Only sync if we have pending changes or haven't synced recently
        let shouldSync = pendingChanges > 0 || shouldPerformPeriodicSync()
        
        if shouldSync {
            await performSync()
        }
    }
    
    private func shouldPerformPeriodicSync() -> Bool {
        guard let lastSync = lastSyncDate else { return true }
        let timeSinceLastSync = Date().timeIntervalSince(lastSync)
        return timeSinceLastSync > autoSyncInterval
    }
    
    // MARK: - Sync Operations
    
    func performSync(forced: Bool = false) async {
        guard isOnline || forced else {
            print("Cannot sync: offline")
            return
        }
        
        guard !isSyncing else {
            print("Sync already in progress")
            return
        }
        
        isSyncing = true
        syncProgress = SyncProgress()
        
        defer {
            isSyncing = false
        }
        
        do {
            // Start sync process
            syncProgress.currentOperation = "Starting sync..."
            syncProgress.progress = 0.1
            
            await dataService.syncWithRemote()
            
            // Update sync status
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: "lastSyncDate")
            
            syncProgress.currentOperation = "Sync completed"
            syncProgress.progress = 1.0
            syncProgress.isCompleted = true
            
            // Update pending changes count
            updatePendingChangesCount()
            
            print("Sync completed successfully")
            
        } catch {
            syncProgress.error = error
            syncProgress.currentOperation = "Sync failed"
            print("Sync failed: \(error)")
            
            // Schedule retry if appropriate
            if shouldRetrySync(error: error) {
                scheduleRetrySync()
            }
        }
        
        // Clear progress after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if self.syncProgress.isCompleted || self.syncProgress.error != nil {
                self.syncProgress = SyncProgress()
            }
        }
    }
    
    private func shouldRetrySync(error: Error) -> Bool {
        // Don't retry for authentication errors or client errors
        if let apiError = error as? APIError {
            switch apiError {
            case .unauthorized, .forbidden:
                return false
            case .networkError, .serverError, .rateLimited:
                return true
            default:
                return true
            }
        }
        return true
    }
    
    private func scheduleRetrySync() {
        DispatchQueue.main.asyncAfter(deadline: .now() + retryInterval) {
            Task {
                await self.performSync()
            }
        }
    }
    
    // MARK: - Data Management
    
    private func observeDataChanges() {
        dataService.$goals
            .combineLatest(dataService.$todaysTasks)
            .sink { [weak self] _, _ in
                self?.updatePendingChangesCount()
            }
            .store(in: &cancellables)
    }
    
    private func updatePendingChangesCount() {
        pendingChanges = dataService.getUnsyncedChangesCount()
    }
    
    private func loadLastSyncDate() {
        lastSyncDate = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
        updatePendingChangesCount()
    }
    
    // MARK: - Offline Operations
    
    func canPerformOperation() -> Bool {
        // Most operations can be performed offline and synced later
        return true
    }
    
    func requiresOnlineConnection() -> Bool {
        // Some operations require online connection
        return false
    }
    
    func getOfflineCapabilities() -> OfflineCapabilities {
        return OfflineCapabilities(
            canCreateGoals: true,
            canUpdateTasks: true,
            canViewReports: true,
            canAccessSettings: true,
            canGenerateRoasts: false, // Requires API
            canSyncData: false // Obviously requires connection
        )
    }
    
    // MARK: - Conflict Resolution
    
    func resolveConflicts() async {
        // Implementation for conflict resolution
        // This would be called when sync detects conflicts
        print("Resolving data conflicts...")
        
        // For now, we'll use "last write wins" strategy
        // In a more sophisticated implementation, we'd present conflicts to the user
    }
    
    // MARK: - Cache Management
    
    func clearCache() async {
        // Clear cached data that can be re-fetched
        print("Clearing offline cache...")
        
        // This would remove non-essential cached data
        // while preserving user-created content
    }
    
    func getCacheSize() -> Int64 {
        // Calculate size of cached data
        return 0 // Placeholder implementation
    }
    
    // MARK: - Cleanup
    
    deinit {
        syncTimer?.invalidate()
        networkMonitor.cancel()
    }
}

// MARK: - Supporting Types

enum ConnectionType {
    case wifi
    case cellular
    case unknown
    
    var displayName: String {
        switch self {
        case .wifi: return "Wi-Fi"
        case .cellular: return "Cellular"
        case .unknown: return "Unknown"
        }
    }
    
    var icon: String {
        switch self {
        case .wifi: return "wifi"
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .unknown: return "network"
        }
    }
}

struct SyncProgress {
    var progress: Double = 0.0
    var currentOperation: String = ""
    var isCompleted: Bool = false
    var error: Error?
    
    var displayProgress: String {
        if isCompleted {
            return "✅ Completed"
        } else if error != nil {
            return "❌ Failed"
        } else {
            return currentOperation
        }
    }
}

struct OfflineCapabilities {
    let canCreateGoals: Bool
    let canUpdateTasks: Bool
    let canViewReports: Bool
    let canAccessSettings: Bool
    let canGenerateRoasts: Bool
    let canSyncData: Bool
}

// MARK: - Offline Data Queue

class OfflineDataQueue: ObservableObject {
    static let shared = OfflineDataQueue()
    
    @Published var queuedOperations: [QueuedOperation] = []
    @Published var isProcessingQueue = false
    
    private init() {
        loadQueuedOperations()
    }
    
    func queueOperation(_ operation: QueuedOperation) {
        queuedOperations.append(operation)
        saveQueuedOperations()
    }
    
    func processQueue() async {
        guard !isProcessingQueue else { return }
        
        isProcessingQueue = true
        defer { isProcessingQueue = false }
        
        let operationsToProcess = queuedOperations
        
        for operation in operationsToProcess {
            do {
                try await processOperation(operation)
                removeOperation(operation)
            } catch {
                operation.failureCount += 1
                operation.lastAttempt = Date()
                
                if operation.failureCount >= 3 {
                    // Remove operation after 3 failed attempts
                    removeOperation(operation)
                }
                
                print("Failed to process operation \(operation.id): \(error)")
            }
        }
        
        saveQueuedOperations()
    }
    
    private func processOperation(_ operation: QueuedOperation) async throws {
        switch operation.type {
        case .createGoal:
            // Process goal creation
            break
        case .updateTask:
            // Process task update
            break
        case .deleteGoal:
            // Process goal deletion
            break
        }
    }
    
    private func removeOperation(_ operation: QueuedOperation) {
        queuedOperations.removeAll { $0.id == operation.id }
    }
    
    private func saveQueuedOperations() {
        // Save to UserDefaults or Core Data
        do {
            let data = try JSONEncoder().encode(queuedOperations)
            UserDefaults.standard.set(data, forKey: "queuedOperations")
        } catch {
            print("Failed to save queued operations: \(error)")
        }
    }
    
    private func loadQueuedOperations() {
        guard let data = UserDefaults.standard.data(forKey: "queuedOperations") else { return }
        
        do {
            queuedOperations = try JSONDecoder().decode([QueuedOperation].self, from: data)
        } catch {
            print("Failed to load queued operations: \(error)")
        }
    }
}

struct QueuedOperation: Codable, Identifiable {
    let id = UUID()
    let type: OperationType
    let data: Data
    let timestamp: Date
    var failureCount: Int = 0
    var lastAttempt: Date?
    
    enum OperationType: String, Codable {
        case createGoal
        case updateTask
        case deleteGoal
    }
}

// MARK: - Offline Banner View

struct OfflineBannerView: View {
    @StateObject private var offlineManager = OfflineManager.shared
    @State private var showingDetails = false
    
    var body: some View {
        if offlineManager.showOfflineBanner {
            HStack {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("You're offline")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    if offlineManager.pendingChanges > 0 {
                        Text("\(offlineManager.pendingChanges) changes pending sync")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer()
                
                if offlineManager.pendingChanges > 0 {
                    Button("Details") {
                        showingDetails = true
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.orange)
            .transition(.move(edge: .top))
        }
    }
}

// MARK: - Sync Status View

struct SyncStatusView: View {
    @StateObject private var offlineManager = OfflineManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Connection Status
            HStack {
                Image(systemName: offlineManager.isOnline ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(offlineManager.isOnline ? .green : .red)
                
                VStack(alignment: .leading) {
                    Text(offlineManager.isOnline ? "Online" : "Offline")
                        .font(.headline)
                    
                    if offlineManager.isOnline {
                        Text("Connected via \(offlineManager.connectionType.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Last Sync
            if let lastSync = offlineManager.lastSyncDate {
                HStack {
                    Image(systemName: "arrow.clockwise.circle")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text("Last Sync")
                            .font(.headline)
                        
                        Text(RelativeDateTimeFormatter().localizedString(for: lastSync, relativeTo: Date()))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            
            // Pending Changes
            if offlineManager.pendingChanges > 0 {
                HStack {
                    Image(systemName: "clock.circle")
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading) {
                        Text("Pending Changes")
                            .font(.headline)
                        
                        Text("\(offlineManager.pendingChanges) changes waiting to sync")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            
            // Sync Progress
            if offlineManager.isSyncing {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        
                        Text("Syncing...")
                            .font(.headline)
                        
                        Spacer()
                    }
                    
                    Text(offlineManager.syncProgress.currentOperation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: offlineManager.syncProgress.progress)
                }
            }
            
            // Manual Sync Button
            if offlineManager.isOnline && !offlineManager.isSyncing {
                Button(action: {
                    Task {
                        await offlineManager.performSync(forced: true)
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Sync Now")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
    }
}

// MARK: - Offline Indicator View

struct OfflineIndicatorView: View {
    @StateObject private var offlineManager = OfflineManager.shared
    
    var body: some View {
        Group {
            if !offlineManager.isOnline {
                HStack(spacing: 4) {
                    Image(systemName: "wifi.slash")
                        .font(.caption2)
                    Text("Offline")
                        .font(.caption2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(4)
            } else if offlineManager.pendingChanges > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("\(offlineManager.pendingChanges)")
                        .font(.caption2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(4)
            }
        }
    }
}

// MARK: - Network Dependent View Modifier

struct NetworkDependentModifier: ViewModifier {
    @StateObject private var offlineManager = OfflineManager.shared
    let requiresNetwork: Bool
    
    func body(content: Content) -> some View {
        content
            .disabled(requiresNetwork && !offlineManager.isOnline)
            .opacity(requiresNetwork && !offlineManager.isOnline ? 0.5 : 1.0)
    }
}

extension View {
    func networkDependent(_ requiresNetwork: Bool = true) -> some View {
        self.modifier(NetworkDependentModifier(requiresNetwork: requiresNetwork))
    }
}