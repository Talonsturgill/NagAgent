import Foundation
import CoreData

// MARK: - Core Data Model Extensions

// MARK: - CDGoal (Goal Entity)

@objc(CDGoal)
public class CDGoal: NSManagedObject {
    
    @NSManaged public var id: Int32
    @NSManaged public var userId: Int32
    @NSManaged public var goalText: String?
    @NSManaged public var isRecurring: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var archivedAt: Date?
    @NSManaged public var needsSync: Bool
    @NSManaged public var lastModified: Date?
    
    // Relationships
    @NSManaged public var dailyTasks: NSSet?
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        createdAt = Date()
        lastModified = Date()
        needsSync = true
    }
    
    public override func willSave() {
        super.willSave()
        if isUpdated {
            lastModified = Date()
            needsSync = true
        }
    }
}

extension CDGoal {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDGoal> {
        return NSFetchRequest<CDGoal>(entityName: "CDGoal")
    }
    
    public var dailyTasksArray: [CDDailyTask] {
        let set = dailyTasks as? Set<CDDailyTask> ?? []
        return set.sorted {
            $0.date ?? Date.distantPast < $1.date ?? Date.distantPast
        }
    }
    
    public var isArchived: Bool {
        return archivedAt != nil
    }
    
    public var displayText: String {
        return goalText ?? "Untitled Goal"
    }
}

// MARK: - CDDailyTask (DailyTask Entity)

@objc(CDDailyTask)
public class CDDailyTask: NSManagedObject {
    
    @NSManaged public var id: Int32
    @NSManaged public var userId: Int32
    @NSManaged public var goalId: Int32
    @NSManaged public var date: Date?
    @NSManaged public var completed: Bool
    @NSManaged public var excuseGiven: String?
    @NSManaged public var completedAt: Date?
    @NSManaged public var createdAt: Date?
    @NSManaged public var needsSync: Bool
    @NSManaged public var lastModified: Date?
    
    // Relationships
    @NSManaged public var goal: CDGoal?
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        createdAt = Date()
        lastModified = Date()
        needsSync = true
        completed = false
        if date == nil {
            date = Date()
        }
    }
    
    public override func willSave() {
        super.willSave()
        if isUpdated {
            lastModified = Date()
            needsSync = true
        }
    }
}

extension CDDailyTask {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDDailyTask> {
        return NSFetchRequest<CDDailyTask>(entityName: "CDDailyTask")
    }
    
    public var displayDate: String {
        guard let date = date else { return "No Date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    public var hasExcuse: Bool {
        return excuseGiven != nil && !(excuseGiven?.isEmpty ?? true)
    }
    
    public var status: TaskStatus {
        if completed {
            return .completed
        } else if hasExcuse {
            return .excused
        } else {
            return .pending
        }
    }
    
    public enum TaskStatus {
        case pending
        case completed
        case excused
        
        var displayName: String {
            switch self {
            case .pending: return "Pending"
            case .completed: return "Completed"
            case .excused: return "Excused"
            }
        }
        
        var iconName: String {
            switch self {
            case .pending: return "circle"
            case .completed: return "checkmark.circle.fill"
            case .excused: return "exclamationmark.triangle.fill"
            }
        }
    }
}

// MARK: - CDDailyReport (DailyReport Entity)

@objc(CDDailyReport)
public class CDDailyReport: NSManagedObject {
    
    @NSManaged public var date: Date?
    @NSManaged public var tasksCompleted: Int16
    @NSManaged public var tasksTotal: Int16
    @NSManaged public var completionRate: Double
    @NSManaged public var excusesMade: Int16
    @NSManaged public var currentStreak: Int16
    @NSManaged public var ranking: Int16
    @NSManaged public var roast: String?
    @NSManaged public var personality: String?
    @NSManaged public var createdAt: Date?
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        createdAt = Date()
        if date == nil {
            date = Date()
        }
    }
}

extension CDDailyReport {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDDailyReport> {
        return NSFetchRequest<CDDailyReport>(entityName: "CDDailyReport")
    }
    
    public var displayDate: String {
        guard let date = date else { return "No Date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    public var completionPercentage: Int {
        return Int(completionRate * 100)
    }
    
    public var performanceGrade: String {
        switch completionRate {
        case 0.9...:
            return "A"
        case 0.8..<0.9:
            return "B"
        case 0.7..<0.8:
            return "C"
        case 0.6..<0.7:
            return "D"
        default:
            return "F"
        }
    }
    
    public var hasRanking: Bool {
        return ranking >= 0
    }
    
    public var displayRoast: String {
        return roast ?? "No roast available"
    }
    
    public var personalityDisplayName: String {
        guard let personality = personality else { return "Unknown" }
        return PersonalityType(rawValue: personality)?.displayName ?? personality
    }
}

// MARK: - CDUserProfile (UserProfile Entity)

@objc(CDUserProfile)
public class CDUserProfile: NSManagedObject {
    
    @NSManaged public var id: Int32
    @NSManaged public var email: String?
    @NSManaged public var name: String?
    @NSManaged public var personality: String?
    @NSManaged public var timezone: String?
    @NSManaged public var notificationTimes: Data?
    @NSManaged public var subscriptionTier: String?
    @NSManaged public var isActive: Bool
    @NSManaged public var isVerified: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var lastActive: Date?
    @NSManaged public var phoneNumber: String?
    @NSManaged public var totalGoals: Int32
    @NSManaged public var totalCompletedTasks: Int32
    @NSManaged public var currentStreak: Int32
    @NSManaged public var lastSynced: Date?
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        isActive = true
        isVerified = false
        totalGoals = 0
        totalCompletedTasks = 0
        currentStreak = 0
        lastSynced = Date()
    }
}

extension CDUserProfile {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDUserProfile> {
        return NSFetchRequest<CDUserProfile>(entityName: "CDUserProfile")
    }
    
    public var displayName: String {
        return name ?? email ?? "Unknown User"
    }
    
    public var personalityType: PersonalityType? {
        guard let personality = personality else { return nil }
        return PersonalityType(rawValue: personality)
    }
    
    public var notificationTimesArray: [String] {
        guard let data = notificationTimes else { return [] }
        do {
            return try JSONDecoder().decode([String].self, from: data)
        } catch {
            print("Failed to decode notification times: \(error)")
            return []
        }
    }
    
    public func setNotificationTimes(_ times: [String]) {
        do {
            notificationTimes = try JSONEncoder().encode(times)
        } catch {
            print("Failed to encode notification times: \(error)")
        }
    }
    
    public var isPremium: Bool {
        return subscriptionTier == "premium"
    }
}

// MARK: - CDRoast (Roast Entity)

@objc(CDRoast)
public class CDRoast: NSManagedObject {
    
    @NSManaged public var id: String?
    @NSManaged public var personality: String?
    @NSManaged public var triggerText: String?
    @NSManaged public var responseText: String?
    @NSManaged public var isShareable: Bool
    @NSManaged public var shareCount: Int32
    @NSManaged public var createdAt: Date?
    @NSManaged public var isFavorite: Bool
    @NSManaged public var lastUsed: Date?
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID().uuidString
        createdAt = Date()
        isShareable = true
        shareCount = 0
        isFavorite = false
    }
}

extension CDRoast {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDRoast> {
        return NSFetchRequest<CDRoast>(entityName: "CDRoast")
    }
    
    public var displayText: String {
        return responseText ?? "No roast available"
    }
    
    public var personalityType: PersonalityType? {
        guard let personality = personality else { return nil }
        return PersonalityType(rawValue: personality)
    }
    
    public var personalityDisplayName: String {
        return personalityType?.displayName ?? "Unknown"
    }
    
    public var createdDateString: String {
        guard let createdAt = createdAt else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}

// MARK: - CDSyncRecord (Sync Tracking Entity)

@objc(CDSyncRecord)
public class CDSyncRecord: NSManagedObject {
    
    @NSManaged public var entityName: String?
    @NSManaged public var entityId: String?
    @NSManaged public var lastSyncDate: Date?
    @NSManaged public var syncStatus: String?
    @NSManaged public var errorMessage: String?
    @NSManaged public var retryCount: Int32
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        lastSyncDate = Date()
        syncStatus = SyncStatus.pending.rawValue
        retryCount = 0
    }
}

extension CDSyncRecord {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDSyncRecord> {
        return NSFetchRequest<CDSyncRecord>(entityName: "CDSyncRecord")
    }
    
    public enum SyncStatus: String, CaseIterable {
        case pending = "pending"
        case syncing = "syncing"
        case success = "success"
        case failed = "failed"
        case conflict = "conflict"
    }
    
    public var status: SyncStatus {
        get {
            return SyncStatus(rawValue: syncStatus ?? "") ?? .pending
        }
        set {
            syncStatus = newValue.rawValue
        }
    }
    
    public var shouldRetry: Bool {
        return status == .failed && retryCount < 3
    }
}

// MARK: - Core Data Model Creation Helper

class CoreDataModelCreator {
    static func createDataModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // Create entities
        let goalEntity = createGoalEntity()
        let taskEntity = createTaskEntity()
        let reportEntity = createReportEntity()
        let userEntity = createUserEntity()
        let roastEntity = createRoastEntity()
        let syncEntity = createSyncEntity()
        
        // Set up relationships
        setupRelationships(goalEntity: goalEntity, taskEntity: taskEntity)
        
        model.entities = [goalEntity, taskEntity, reportEntity, userEntity, roastEntity, syncEntity]
        
        return model
    }
    
    private static func createGoalEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDGoal"
        entity.managedObjectClassName = "CDGoal"
        
        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .integer32AttributeType
        idAttribute.isOptional = false
        
        let userIdAttribute = NSAttributeDescription()
        userIdAttribute.name = "userId"
        userIdAttribute.attributeType = .integer32AttributeType
        userIdAttribute.isOptional = false
        
        let goalTextAttribute = NSAttributeDescription()
        goalTextAttribute.name = "goalText"
        goalTextAttribute.attributeType = .stringAttributeType
        goalTextAttribute.isOptional = true
        
        let isRecurringAttribute = NSAttributeDescription()
        isRecurringAttribute.name = "isRecurring"
        isRecurringAttribute.attributeType = .booleanAttributeType
        isRecurringAttribute.defaultValue = true
        
        let createdAtAttribute = NSAttributeDescription()
        createdAtAttribute.name = "createdAt"
        createdAtAttribute.attributeType = .dateAttributeType
        createdAtAttribute.isOptional = true
        
        let archivedAtAttribute = NSAttributeDescription()
        archivedAtAttribute.name = "archivedAt"
        archivedAtAttribute.attributeType = .dateAttributeType
        archivedAtAttribute.isOptional = true
        
        let needsSyncAttribute = NSAttributeDescription()
        needsSyncAttribute.name = "needsSync"
        needsSyncAttribute.attributeType = .booleanAttributeType
        needsSyncAttribute.defaultValue = false
        
        let lastModifiedAttribute = NSAttributeDescription()
        lastModifiedAttribute.name = "lastModified"
        lastModifiedAttribute.attributeType = .dateAttributeType
        lastModifiedAttribute.isOptional = true
        
        entity.properties = [
            idAttribute, userIdAttribute, goalTextAttribute, isRecurringAttribute,
            createdAtAttribute, archivedAtAttribute, needsSyncAttribute, lastModifiedAttribute
        ]
        
        return entity
    }
    
    private static func createTaskEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDDailyTask"
        entity.managedObjectClassName = "CDDailyTask"
        
        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .integer32AttributeType
        idAttribute.isOptional = false
        
        let userIdAttribute = NSAttributeDescription()
        userIdAttribute.name = "userId"
        userIdAttribute.attributeType = .integer32AttributeType
        userIdAttribute.isOptional = false
        
        let goalIdAttribute = NSAttributeDescription()
        goalIdAttribute.name = "goalId"
        goalIdAttribute.attributeType = .integer32AttributeType
        goalIdAttribute.isOptional = false
        
        let dateAttribute = NSAttributeDescription()
        dateAttribute.name = "date"
        dateAttribute.attributeType = .dateAttributeType
        dateAttribute.isOptional = true
        
        let completedAttribute = NSAttributeDescription()
        completedAttribute.name = "completed"
        completedAttribute.attributeType = .booleanAttributeType
        completedAttribute.defaultValue = false
        
        let excuseGivenAttribute = NSAttributeDescription()
        excuseGivenAttribute.name = "excuseGiven"
        excuseGivenAttribute.attributeType = .stringAttributeType
        excuseGivenAttribute.isOptional = true
        
        let completedAtAttribute = NSAttributeDescription()
        completedAtAttribute.name = "completedAt"
        completedAtAttribute.attributeType = .dateAttributeType
        completedAtAttribute.isOptional = true
        
        let createdAtAttribute = NSAttributeDescription()
        createdAtAttribute.name = "createdAt"
        createdAtAttribute.attributeType = .dateAttributeType
        createdAtAttribute.isOptional = true
        
        let needsSyncAttribute = NSAttributeDescription()
        needsSyncAttribute.name = "needsSync"
        needsSyncAttribute.attributeType = .booleanAttributeType
        needsSyncAttribute.defaultValue = false
        
        let lastModifiedAttribute = NSAttributeDescription()
        lastModifiedAttribute.name = "lastModified"
        lastModifiedAttribute.attributeType = .dateAttributeType
        lastModifiedAttribute.isOptional = true
        
        entity.properties = [
            idAttribute, userIdAttribute, goalIdAttribute, dateAttribute,
            completedAttribute, excuseGivenAttribute, completedAtAttribute,
            createdAtAttribute, needsSyncAttribute, lastModifiedAttribute
        ]
        
        return entity
    }
    
    private static func createReportEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDDailyReport"
        entity.managedObjectClassName = "CDDailyReport"
        
        // Add attributes for report entity
        // Implementation would continue with all report attributes...
        
        return entity
    }
    
    private static func createUserEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDUserProfile"
        entity.managedObjectClassName = "CDUserProfile"
        
        // Add attributes for user entity
        // Implementation would continue with all user attributes...
        
        return entity
    }
    
    private static func createRoastEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDRoast"
        entity.managedObjectClassName = "CDRoast"
        
        // Add attributes for roast entity
        // Implementation would continue with all roast attributes...
        
        return entity
    }
    
    private static func createSyncEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDSyncRecord"
        entity.managedObjectClassName = "CDSyncRecord"
        
        // Add attributes for sync entity
        // Implementation would continue with all sync attributes...
        
        return entity
    }
    
    private static func setupRelationships(goalEntity: NSEntityDescription, taskEntity: NSEntityDescription) {
        // Goal -> DailyTasks relationship
        let goalTasksRelationship = NSRelationshipDescription()
        goalTasksRelationship.name = "dailyTasks"
        goalTasksRelationship.destinationEntity = taskEntity
        goalTasksRelationship.minCount = 0
        goalTasksRelationship.maxCount = 0 // To-many
        goalTasksRelationship.deleteRule = .cascadeDeleteRule
        
        // DailyTask -> Goal relationship
        let taskGoalRelationship = NSRelationshipDescription()
        taskGoalRelationship.name = "goal"
        taskGoalRelationship.destinationEntity = goalEntity
        taskGoalRelationship.minCount = 0
        taskGoalRelationship.maxCount = 1 // To-one
        taskGoalRelationship.deleteRule = .nullifyDeleteRule
        
        // Set inverse relationships
        goalTasksRelationship.inverseRelationship = taskGoalRelationship
        taskGoalRelationship.inverseRelationship = goalTasksRelationship
        
        // Add relationships to entities
        goalEntity.properties.append(goalTasksRelationship)
        taskEntity.properties.append(taskGoalRelationship)
    }
}