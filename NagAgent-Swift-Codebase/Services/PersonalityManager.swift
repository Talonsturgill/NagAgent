import Foundation
import SwiftUI

class PersonalityManager: ObservableObject {
    static let shared = PersonalityManager()
    
    @Published var selectedPersonality: PersonalityType {
        didSet {
            // Save to UserDefaults whenever it changes
            UserDefaults.standard.set(selectedPersonality.rawValue, forKey: "selectedPersonality")
            print("✅ Personality changed to: \(selectedPersonality.displayName)")
        }
    }
    
    private init() {
        // Load saved personality or default to sassy
        let savedPersonality = UserDefaults.standard.string(forKey: "selectedPersonality") ?? "sassy"
        self.selectedPersonality = PersonalityType(rawValue: savedPersonality) ?? .sassy
        print("🔥 Loaded personality: \(selectedPersonality.displayName)")
    }
    
    func setPersonality(_ type: PersonalityType) {
        selectedPersonality = type
    }
    
    func getCurrentPersonality() -> PersonalityType {
        return selectedPersonality
    }
    
    func getRoastForContext(_ context: RoastContext) -> String {
        switch context {
        case .morning(let taskCount):
            return getMorningRoast(taskCount: taskCount)
        case .excuse(let excuse, let task):
            return getExcuseRoast(excuse: excuse, task: task)
        case .completion(let rate):
            return getCompletionRoast(rate: rate)
        case .daily(let completed, let total):
            return getDailyRoast(completed: completed, total: total)
        }
    }
    
    private func getMorningRoast(taskCount: Int) -> String {
        switch selectedPersonality {
        case .sergeant:
            if taskCount == 0 {
                return "NO MISSION OBJECTIVES? PATHETIC! Can't fail if you don't try, right SOLDIER?"
            }
            return "RISE AND SHINE, MAGGOT! \(taskCount) objectives to disappoint me with today!"
            
        case .sassy:
            if taskCount == 0 {
                return "Oh bestie, no goals? The bar is underground and you're still not reaching it. 💅"
            }
            return "Morning bestie! \(taskCount) delusions of productivity lined up? Can't wait to see which one you blame Mercury retrograde for! 💀"
            
        case .passive:
            if taskCount == 0 {
                return "No goals set? That's... fine. I guess we're going with the 'wing it' approach."
            }
            return "Good morning! \(taskCount) opportunities for... potential. How refreshing."
            
        case .brutal:
            if taskCount == 0 {
                return "No goals? Smart. Can't disappoint if you don't try. Except you're already disappointing."
            }
            return "Your potential called. It's filing a missing person report. \(taskCount) more ways to fail today."
        }
    }
    
    private func getExcuseRoast(excuse: String, task: String) -> String {
        switch selectedPersonality {
        case .sergeant:
            return "'\(excuse)'? PATHETIC EXCUSE, SOLDIER! '\(task)' won't complete itself! DROP AND GIVE ME TWENTY!"
            
        case .sassy:
            return "'\(excuse)'? That's creative bestie! Still not doing '\(task)' though. The commitment to mediocrity... 💅"
            
        case .passive:
            return "'\(excuse)' - interesting approach to '\(task)'. I'll add it to your file under 'Classic Avoidance, Volume 12'."
            
        case .brutal:
            return "'\(excuse)' - the creativity you waste on avoiding '\(task)' could fuel actual achievement. But here we are."
        }
    }
    
    private func getCompletionRoast(rate: Double) -> String {
        let percentage = Int(rate * 100)
        
        switch selectedPersonality {
        case .sergeant:
            if rate == 0 {
                return "ZERO PERCENT?! The consistency is APPALLING! At least you're predictably TERRIBLE!"
            } else if rate < 0.5 {
                return "ONLY \(percentage)%? The bar was underground and you brought a SHOVEL!"
            } else if rate < 1.0 {
                return "\(percentage)%! SO CLOSE to being ADEQUATE! Keep pushing, SOLDIER!"
            } else {
                return "100%?! IMPOSSIBLE! I'm... actually PROUD! Don't let it go to your head, MAGGOT!"
            }
            
        case .sassy:
            if rate == 0 {
                return "Zero tasks? The consistency is admirable. Consistently terrible, but admirable. 💀"
            } else if rate < 0.5 {
                return "Only \(percentage)%? This is giving participation trophy energy."
            } else if rate < 1.0 {
                return "\(percentage)%! Almost iconic! By 'iconic' I mean bare minimum but progress!"
            } else {
                return "WAIT. 100%?! I'm shook. Literally clutching my pearls rn. Who are you?!"
            }
            
        case .passive:
            if rate == 0 {
                return "Zero percent. Well, consistency is a virtue. Consistently disappointing, but still."
            } else if rate < 0.5 {
                return "\(percentage)%? It's... something. I suppose we should celebrate small victories."
            } else if rate < 1.0 {
                return "\(percentage)%. Almost there. 'Almost' being the operative word, as usual."
            } else {
                return "100%? This is... unexpected. I'll need to update my expectations."
            }
            
        case .brutal:
            if rate == 0 {
                return "Zero. Absolute zero. Your consistency in failure is almost impressive."
            } else if rate < 0.5 {
                return "\(percentage)%? Below average, as usual. Mediocrity would be an improvement."
            } else if rate < 1.0 {
                return "\(percentage)%. Nearly perfect is perfectly imperfect. Your specialty."
            } else {
                return "Perfect completion? You've broken the pattern. Don't let it go to your head."
            }
        }
    }
    
    private func getDailyRoast(completed: Int, total: Int) -> String {
        let rate = total > 0 ? Double(completed) / Double(total) : 0
        let percentage = Int(rate * 100)
        
        switch selectedPersonality {
        case .sergeant:
            return """
            DAILY DEBRIEF: \(completed)/\(total) missions completed (\(percentage)%)
            
            \(getCompletionRoast(rate: rate))
            
            REPORT TO BASE AT 0600 TOMORROW. DON'T BE LATE!
            """
            
        case .sassy:
            return """
            Daily tea ☕️: You did \(completed)/\(total) things (\(percentage)%)
            
            \(getCompletionRoast(rate: rate))
            
            See you tomorrow bestie... if you show up 💅
            """
            
        case .passive:
            return """
            Daily Summary: \(completed)/\(total) tasks completed (\(percentage)%)
            
            \(getCompletionRoast(rate: rate))
            
            Looking forward to tomorrow's... efforts.
            """
            
        case .brutal:
            return """
            Reality Check: \(completed)/\(total) done (\(percentage)%)
            
            \(getCompletionRoast(rate: rate))
            
            Your future self is taking notes. They're not happy.
            """
        }
    }
}

// MARK: - Roast Context Enum
enum RoastContext {
    case morning(taskCount: Int)
    case excuse(excuse: String, task: String)
    case completion(rate: Double)
    case daily(completed: Int, total: Int)
}