import SwiftUI

struct HomeViewFixed: View {
    let personality: PersonalityType
    let initialGoals: [String]
    
    @StateObject private var personalityManager = PersonalityManager.shared
    @State private var tasks: [Task] = []
    @State private var currentRoast: String?
    @State private var showingAddTask = false
    @State private var showingDailyReport = false
    @State private var showingSettings = false
    @State private var animateHeader = false
    
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
                    VStack(spacing: 20) {
                        // Personality Header - USES ACTUAL SELECTED PERSONALITY
                        PersonalityHeaderViewFixed(
                            personality: personalityManager.selectedPersonality,
                            completionRate: completionRate
                        )
                        .scaleEffect(animateHeader ? 1.0 : 0.9)
                        .opacity(animateHeader ? 1.0 : 0.0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: animateHeader)
                        
                        // Current Roast Bubble - USES CORRECT PERSONALITY
                        if let roast = currentRoast {
                            RoastBubbleView(
                                roast: roast,
                                personality: personalityManager.selectedPersonality
                            ) {
                                shareRoast(roast)
                            }
                            .padding(.horizontal)
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        }
                        
                        // Today's Tasks Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(getTasksTitle())
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Text("\(completedTasks)/\(tasks.count) completed")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    showingAddTask = true
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.purple)
                                }
                            }
                            .padding(.horizontal)
                            
                            if tasks.isEmpty {
                                EmptyTasksViewFixed(personality: personalityManager.selectedPersonality) {
                                    showingAddTask = true
                                }
                            } else {
                                ForEach($tasks) { $task in
                                    TaskRowView(
                                        task: $task,
                                        onComplete: {
                                            handleTaskCompletion(task)
                                        },
                                        onExcuse: { excuse in
                                            handleExcuse(excuse, for: task.text)
                                        }
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Quick Stats
                        if !tasks.isEmpty {
                            QuickStatsView(
                                completedTasks: completedTasks,
                                totalTasks: tasks.count,
                                personality: personalityManager.selectedPersonality
                            )
                            .padding(.horizontal)
                        }
                        
                        // Debug Info (remove in production)
                        #if DEBUG
                        VStack {
                            Text("Current Personality: \(personalityManager.selectedPersonality.displayName)")
                                .foregroundColor(.green)
                            Text("Tasks: \(tasks.count)")
                                .foregroundColor(.yellow)
                        }
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                        .padding()
                        #endif
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                setupInitialTasks()
                generateMorningRoast()
                animateHeader = true
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskSheet { newTaskText in
                    addTask(newTaskText)
                }
            }
            .sheet(isPresented: $showingDailyReport) {
                DailyReportViewFixed(
                    personality: personalityManager.selectedPersonality,
                    tasks: tasks,
                    completionRate: completionRate
                )
            }
            .overlay(alignment: .bottomTrailing) {
                // Floating Action Buttons
                VStack(spacing: 12) {
                    // Daily Report Button
                    Button(action: {
                        showingDailyReport = true
                    }) {
                        Image(systemName: "chart.bar.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(Color.purple)
                            )
                    }
                    
                    // Settings Button
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(Color.gray)
                            )
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var completedTasks: Int {
        tasks.filter { $0.isCompleted }.count
    }
    
    private var completionRate: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedTasks) / Double(tasks.count)
    }
    
    // MARK: - Methods
    
    private func setupInitialTasks() {
        tasks = initialGoals.map { Task(text: $0) }
    }
    
    private func addTask(_ text: String) {
        let newTask = Task(text: text)
        withAnimation(.spring()) {
            tasks.append(newTask)
        }
    }
    
    private func generateMorningRoast() {
        // Use PersonalityManager to get correct personality roast
        currentRoast = personalityManager.getRoastForContext(.morning(taskCount: tasks.count))
    }
    
    private func handleTaskCompletion(_ task: Task) {
        withAnimation(.spring()) {
            // Use PersonalityManager for completion roast
            currentRoast = personalityManager.getRoastForContext(.completion(rate: completionRate))
        }
    }
    
    private func handleExcuse(_ excuse: String, for taskText: String) {
        withAnimation(.spring()) {
            // Use PersonalityManager for excuse roast
            currentRoast = personalityManager.getRoastForContext(.excuse(excuse: excuse, task: taskText))
        }
    }
    
    private func shareRoast(_ roast: String) {
        // Share functionality would go here
        print("Sharing roast: \(roast)")
    }
    
    private func getTasksTitle() -> String {
        switch personalityManager.selectedPersonality {
        case .sergeant:
            return "Today's Missions"
        case .sassy:
            return "Today's Delusions"
        case .passive:
            return "Today's Agenda"
        case .brutal:
            return "Today's Failures"
        }
    }
}

// MARK: - Supporting Views

struct PersonalityHeaderViewFixed: View {
    let personality: PersonalityType
    let completionRate: Double
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(personality.emoji)
                        .font(.title)
                    
                    VStack(alignment: .leading) {
                        Text(personality.displayName)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Your Accountability Coach")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                // Progress bar
                HStack {
                    Text("Today's Progress:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("\(Int(completionRate * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(progressColor)
                }
                
                ProgressView(value: completionRate)
                    .progressViewStyle(LinearProgressViewStyle())
                    .accentColor(progressColor)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    private var progressColor: Color {
        switch completionRate {
        case 0..<0.3: return .red
        case 0.3..<0.7: return .orange
        case 0.7..<1.0: return .yellow
        default: return .green
        }
    }
}

struct EmptyTasksViewFixed: View {
    let personality: PersonalityType
    let onAddTask: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("🤷‍♂️")
                .font(.system(size: 60))
            
            Text("No goals set?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(emptyStateMessage)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: onAddTask) {
                Text("Set Some Goals")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.purple)
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
        )
        .padding(.horizontal)
    }
    
    private var emptyStateMessage: String {
        switch personality {
        case .sergeant:
            return "NO MISSION OBJECTIVES? UNACCEPTABLE, SOLDIER!"
        case .sassy:
            return "Oh bestie, you haven't even set goals? The bar is underground and you're still not reaching it."
        case .passive:
            return "No goals set? That's... fine. I guess we're going with the 'wing it' approach."
        case .brutal:
            return "No goals? Smart. Can't fail if you don't try. Except you're already failing."
        }
    }
}

struct DailyReportViewFixed: View {
    let personality: PersonalityType
    let tasks: [Task]
    let completionRate: Double
    
    @StateObject private var personalityManager = PersonalityManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Personality-specific report header
                        Text(personalityManager.selectedPersonality.emoji)
                            .font(.system(size: 60))
                        
                        Text("\(personalityManager.selectedPersonality.displayName)'s Report")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        // Report content with correct personality roast
                        Text(personalityManager.getRoastForContext(
                            .daily(
                                completed: tasks.filter { $0.isCompleted }.count,
                                total: tasks.count
                            )
                        ))
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.purple.opacity(0.2))
                        )
                        .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationTitle("Daily Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}