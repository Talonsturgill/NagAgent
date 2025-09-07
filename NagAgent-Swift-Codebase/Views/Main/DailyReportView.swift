import SwiftUI

struct DailyReportView: View {
    let personality: PersonalityType
    let tasks: [Task]
    let completionRate: Double
    
    @Environment(\.dismiss) private var dismiss
    @State private var animateReport = false
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark gradient background
                LinearGradient(
                    gradient: Gradient(colors: [.black, .purple.opacity(0.3), .black]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Text(personality.emoji)
                                .font(.system(size: 60))
                                .scaleEffect(animateReport ? 1.0 : 0.5)
                                .animation(.spring(response: 0.8), value: animateReport)
                            
                            Text("Daily Reality Check")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .opacity(animateReport ? 1.0 : 0.0)
                                .animation(.easeIn(duration: 0.8).delay(0.3), value: animateReport)
                            
                            Text(getCurrentDateString())
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .opacity(animateReport ? 1.0 : 0.0)
                                .animation(.easeIn(duration: 0.8).delay(0.5), value: animateReport)
                        }
                        .padding()
                        
                        // Performance Metrics Card
                        PerformanceMetricsCard(
                            completedTasks: completedTasks,
                            totalTasks: tasks.count,
                            completionRate: completionRate,
                            excuseCount: excuseCount,
                            currentStreak: currentStreak
                        )
                        .opacity(animateReport ? 1.0 : 0.0)
                        .offset(y: animateReport ? 0 : 50)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.7), value: animateReport)
                        
                        // Task Breakdown
                        TaskBreakdownCard(tasks: tasks)
                            .opacity(animateReport ? 1.0 : 0.0)
                            .offset(y: animateReport ? 0 : 50)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.9), value: animateReport)
                        
                        // Personality Report
                        PersonalityReportCard(
                            personality: personality,
                            completionRate: completionRate,
                            tasks: tasks
                        ) {
                            showShareSheet = true
                        }
                        .opacity(animateReport ? 1.0 : 0.0)
                        .offset(y: animateReport ? 0 : 50)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(1.1), value: animateReport)
                        
                        // Grade Section
                        GradeCard(
                            completionRate: completionRate,
                            personality: personality
                        )
                        .opacity(animateReport ? 1.0 : 0.0)
                        .offset(y: animateReport ? 0 : 50)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(1.3), value: animateReport)
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Daily Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.white)
                    }
                }
            }
            .onAppear {
                animateReport = true
            }
            .sheet(isPresented: $showShareSheet) {
                ShareReportView(
                    personality: personality,
                    completionRate: completionRate,
                    completedTasks: completedTasks,
                    totalTasks: tasks.count
                )
            }
        }
    }
    
    private var completedTasks: Int {
        tasks.filter { $0.isCompleted }.count
    }
    
    private var excuseCount: Int {
        // Simulate excuse count - in real app this would come from data
        Int.random(in: 0...5)
    }
    
    private var currentStreak: Int {
        // Simulate streak - in real app this would be calculated
        Int.random(in: 0...7)
    }
    
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: Date())
    }
}

struct PerformanceMetricsCard: View {
    let completedTasks: Int
    let totalTasks: Int
    let completionRate: Double
    let excuseCount: Int
    let currentStreak: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Metrics")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                MetricRow(
                    icon: "checkmark.circle",
                    title: "Tasks Completed",
                    value: "\(completedTasks)/\(totalTasks)",
                    color: .green
                )
                
                MetricRow(
                    icon: "percent",
                    title: "Success Rate",
                    value: "\(Int(completionRate * 100))%",
                    color: completionRate >= 0.8 ? .green : completionRate >= 0.5 ? .orange : .red
                )
                
                MetricRow(
                    icon: "exclamationmark.triangle",
                    title: "Excuses Made",
                    value: "\(excuseCount)",
                    color: excuseCount <= 2 ? .green : excuseCount <= 4 ? .orange : .red
                )
                
                MetricRow(
                    icon: "flame",
                    title: "Current Streak",
                    value: "\(currentStreak) days",
                    color: currentStreak >= 7 ? .green : currentStreak >= 3 ? .orange : .red
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct MetricRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct TaskBreakdownCard: View {
    let tasks: [Task]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Task Breakdown")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if tasks.isEmpty {
                Text("No tasks set for today")
                    .font(.body)
                    .foregroundColor(.gray)
                    .italic()
            } else {
                VStack(spacing: 8) {
                    ForEach(tasks) { task in
                        HStack {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.isCompleted ? .green : .gray)
                            
                            Text(task.text)
                                .font(.body)
                                .foregroundColor(task.isCompleted ? .gray : .white)
                                .strikethrough(task.isCompleted)
                            
                            Spacer()
                            
                            if task.isCompleted {
                                Text("✓")
                                    .foregroundColor(.green)
                                    .fontWeight(.bold)
                            } else {
                                Text("✗")
                                    .foregroundColor(.red)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct PersonalityReportCard: View {
    let personality: PersonalityType
    let completionRate: Double
    let tasks: [Task]
    let onShare: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("\(personality.displayName) Says:")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.purple)
                }
            }
            
            Text(getPersonalityReport())
                .font(.body)
                .foregroundColor(.white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(personalityColor.opacity(0.2))
                        .stroke(personalityColor.opacity(0.5), lineWidth: 1)
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var personalityColor: Color {
        switch personality {
        case .sergeant: return .red
        case .sassy: return .purple
        case .passive: return .blue
        case .brutal: return .black
        }
    }
    
    private func getPersonalityReport() -> String {
        let completedCount = tasks.filter { $0.isCompleted }.count
        let totalCount = tasks.count
        
        switch personality {
        case .sergeant:
            if completionRate == 0 {
                return "ZERO COMPLETION RATE! The consistency is APPALLING! At least you're predictably TERRIBLE!"
            } else if completionRate < 0.5 {
                return "ONLY \(Int(completionRate * 100))%? The bar was on the ground and you brought a SHOVEL!"
            } else if completionRate < 1.0 {
                return "SO CLOSE to being ADEQUATE! But close only counts in HORSESHOES!"
            } else {
                return "IMPOSSIBLE! You actually completed EVERYTHING! I'm... wait... AM I PROUD?"
            }
            
        case .sassy:
            if completionRate == 0 {
                return "Zero tasks completed? The consistency is admirable. Consistently terrible, but admirable. 💀"
            } else if completionRate < 0.5 {
                return "Only \(Int(completionRate * 100))%? This is giving participation trophy energy."
            } else if completionRate < 1.0 {
                return "Almost there! By 'there' I mean the bare minimum but progress!"
            } else {
                return "WAIT. You actually did everything?! I'm shook. Literally clutching my pearls rn."
            }
            
        case .passive:
            if completionRate == 0 {
                return "Zero percent! Well, consistency is a virtue. Consistently disappointing, but still consistent."
            } else if completionRate < 0.5 {
                return "\(Int(completionRate * 100))%? Well, it's... something. I suppose we should celebrate small victories."
            } else if completionRate < 1.0 {
                return "Almost there! 'Almost' being the operative word, as usual."
            } else {
                return "100%?! Well! This is... unexpected. I'll need to update my expectations."
            }
            
        case .brutal:
            if completionRate == 0 {
                return "Zero. Absolute zero. Your consistency in failure is almost impressive."
            } else if completionRate < 0.5 {
                return "\(Int(completionRate * 100))%? Below average, as usual. Mediocrity would be an improvement."
            } else if completionRate < 1.0 {
                return "Nearly perfect is perfectly imperfect. Your specialty."
            } else {
                return "Perfect completion? You've broken the pattern. Don't let it go to your head."
            }
        }
    }
}

struct GradeCard: View {
    let completionRate: Double
    let personality: PersonalityType
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Today's Grade")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Large grade display
            VStack(spacing: 8) {
                Text(grade)
                    .font(.system(size: 80, weight: .bold))
                    .foregroundColor(gradeColor)
                
                Text(gradeMessage)
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
                .stroke(gradeColor.opacity(0.3), lineWidth: 2)
        )
    }
    
    private var grade: String {
        switch completionRate {
        case 0: return "F"
        case 0..<0.3: return "D-"
        case 0.3..<0.5: return "D"
        case 0.5..<0.7: return "C"
        case 0.7..<0.9: return "B"
        case 0.9..<1.0: return "A-"
        default: return "A+"
        }
    }
    
    private var gradeColor: Color {
        switch completionRate {
        case 0..<0.5: return .red
        case 0.5..<0.7: return .orange
        case 0.7..<0.9: return .yellow
        default: return .green
        }
    }
    
    private var gradeMessage: String {
        switch personality {
        case .sergeant:
            switch completionRate {
            case 0: return "COMPLETE MISSION FAILURE"
            case 0..<0.5: return "BARELY BREATHING"
            case 0.5..<0.9: return "ALMOST HUMAN"
            default: return "ACCEPTABLE (for once)"
            }
        case .sassy:
            switch completionRate {
            case 0: return "Flop era continues 💀"
            case 0..<0.5: return "Giving bare minimum"
            case 0.5..<0.9: return "Almost iconic"
            default: return "SLAY ERA ACTIVATED ✨"
            }
        case .passive:
            switch completionRate {
            case 0: return "As expected"
            case 0..<0.5: return "Meeting low expectations"
            case 0.5..<0.9: return "Surprisingly adequate"
            default: return "Exceeding expectations (shocking)"
            }
        case .brutal:
            switch completionRate {
            case 0: return "Predictably disappointing"
            case 0..<0.5: return "Below your already low standards"
            case 0.5..<0.9: return "Mediocre with potential"
            default: return "Shocking competence detected"
            }
        }
    }
}

struct ShareReportView: View {
    let personality: PersonalityType
    let completionRate: Double
    let completedTasks: Int
    let totalTasks: Int
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Share Your Shame")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Shareable card preview
                    ShareableReportCard(
                        personality: personality,
                        completionRate: completionRate,
                        completedTasks: completedTasks,
                        totalTasks: totalTasks
                    )
                    
                    Button(action: {
                        // Share functionality would go here
                        print("Sharing report...")
                        dismiss()
                    }) {
                        Text("Share to Social Media")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.purple, .pink]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Share Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct ShareableReportCard: View {
    let personality: PersonalityType
    let completionRate: Double
    let completedTasks: Int
    let totalTasks: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text(personality.emoji)
                    .font(.title)
                
                VStack(alignment: .leading) {
                    Text("NagAgent Report")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(personality.displayName)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text("📱")
                    .font(.title)
            }
            
            // Stats
            HStack(spacing: 20) {
                VStack {
                    Text("\(completedTasks)/\(totalTasks)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Tasks")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack {
                    Text("\(Int(completionRate * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(completionRate >= 0.8 ? .green : .red)
                    Text("Success")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack {
                    Text(grade)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(gradeColor)
                    Text("Grade")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Watermark
            Text("@NagAgent - Get roasted into productivity")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.1))
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var grade: String {
        switch completionRate {
        case 0: return "F"
        case 0..<0.3: return "D-"
        case 0.3..<0.5: return "D"
        case 0.5..<0.7: return "C"
        case 0.7..<0.9: return "B"
        case 0.9..<1.0: return "A-"
        default: return "A+"
        }
    }
    
    private var gradeColor: Color {
        switch completionRate {
        case 0..<0.5: return .red
        case 0.5..<0.7: return .orange
        case 0.7..<0.9: return .yellow
        default: return .green
        }
    }
}

#Preview {
    DailyReportView(
        personality: .sassy,
        tasks: [
            Task(text: "Go to gym", isCompleted: true),
            Task(text: "Read 20 pages", isCompleted: false),
            Task(text: "Finish project", isCompleted: true)
        ],
        completionRate: 0.67
    )
}