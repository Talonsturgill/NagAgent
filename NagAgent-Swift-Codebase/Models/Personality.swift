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
    
    var primaryColor: String {
        switch self {
        case .sergeant: return "red"
        case .sassy: return "purple"
        case .passive: return "blue"
        case .brutal: return "black"
        }
    }
    
    var sampleRoast: String {
        switch self {
        case .sergeant:
            return "WAKE UP SOLDIER! Time to disappoint me again!"
        case .sassy:
            return "Morning bestie! Ready to procrastinate? The drama... 💅"
        case .passive:
            return "Good morning! Another day of... potential. How nice."
        case .brutal:
            return "Your dreams called. They're filing a missing person report."
        }
    }
}

struct Personality: Codable, Identifiable {
    let id = UUID()
    let type: PersonalityType
    var isSelected: Bool = false
    
    var name: String { type.displayName }
    var emoji: String { type.emoji }
    var description: String { type.description }
    var sampleRoast: String { type.sampleRoast }
}

struct Task: Identifiable, Codable {
    let id = UUID()
    var text: String
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var completedAt: Date?
    
    mutating func toggle() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
    }
}