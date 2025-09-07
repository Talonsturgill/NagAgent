import SwiftUI

struct HomeView: View {
    let personality: PersonalityType
    let initialGoals: [String]
    
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
                        // Personality Header
                        PersonalityHeaderView(
                            personality: personality,
                            completionRate: completionRate
                        )
                        .scaleEffect(animateHeader ? 1.0 : 0.9)
                        .opacity(animateHeader ? 1.0 : 0.0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: animateHeader)
                        
                        // Current Roast Bubble
                        if let roast = currentRoast {
                            RoastBubbleView(
                                roast: roast,
                                personality: personality
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
                                    Text("Today's Delusions")
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
                                EmptyTasksView(personality: personality) {
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
                                personality: personality
                            )
                            .padding(.horizontal)
                        }
                        
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
                DailyReportView(
                    personality: personality,
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
        let roasts = getMorningRoasts(for: personality, taskCount: initialGoals.count)
        currentRoast = roasts.randomElement()
    }
    
    private func handleTaskCompletion(_ task: Task) {
        withAnimation(.spring()) {
            let completionRoasts = getCompletionRoasts(for: personality, completionRate: completionRate)
            currentRoast = completionRoasts.randomElement()
        }
    }
    
    private func handleExcuse(_ excuse: String, for taskText: String) {
        withAnimation(.spring()) {
            let excuseRoasts = getExcuseRoasts(for: personality, excuse: excuse, task: taskText)
            currentRoast = excuseRoasts.randomElement()
        }
    }
    
    private func shareRoast(_ roast: String) {
        // Share functionality would go here
        print("Sharing roast: \(roast)")
    }
}

// MARK: - Supporting Views

struct PersonalityHeaderView: View {
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

struct EmptyTasksView: View {
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
            return "No mission objectives? Outstanding! Can't fail if you don't try, right?"
        case .sassy:
            return "Oh bestie, you haven't even set goals? The bar is underground and you're still not reaching it."
        case .passive:
            return "No goals set? That's... fine. I guess we're going with the 'wing it' approach."
        case .brutal:
            return "No goals? Smart. Can't disappoint if you don't try. Except you're already disappointing."
        }
    }
}

struct QuickStatsView: View {
    let completedTasks: Int
    let totalTasks: Int
    let personality: PersonalityType
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Quick Stats")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                StatItem(
                    title: "Completed",
                    value: "\(completedTasks)",
                    color: .green
                )
                
                StatItem(
                    title: "Remaining",
                    value: "\(totalTasks - completedTasks)",
                    color: .orange
                )
                
                StatItem(
                    title: "Success Rate",
                    value: "\(Int(Double(completedTasks) / Double(totalTasks) * 100))%",
                    color: .purple
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct AddTaskSheet: View {
    let onAdd: (String) -> Void
    
    @State private var taskText = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Add New Goal")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    TextField("Enter your goal...", text: $taskText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            addTask()
                        }
                    
                    Button(action: addTask) {
                        Text("Add Goal")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.purple)
                            )
                    }
                    .disabled(taskText.trimmingCharacters(in: .whitespaces).isEmpty)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("New Goal")
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
    
    private func addTask() {
        let trimmed = taskText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            onAdd(trimmed)
            dismiss()
        }
    }
}

// MARK: - Roast Generation Functions

private func getMorningRoasts(for personality: PersonalityType, taskCount: Int) -> [String] {
    switch personality {
    case .sergeant:
        return [
            "RISE AND SHINE, MAGGOT! Time to disappoint me again!",
            "WAKE UP SOLDIER! Your excuses are already locked and loaded!",
            "Another day, another opportunity to fail spectacularly!"
        ]
    case .sassy:
        return [
            "Morning bestie! Ready to procrastinate? The drama when you don't do it... 💅",
            "Oh look who's up! Your bed must be devastated.",
            "Rise and grind? More like snooze and lose, but go off I guess."
        ]
    case .passive:
        return [
            "Good morning! Another day of... potential. How refreshing.",
            "Hope this message finds you well! Unlike your goals.",
            "Ready to continue your impressive streak of mediocrity?"
        ]
    case .brutal:
        return [
            "Your potential called. It's filing a missing person report.",
            "Another day of pretending you'll change. Admirable consistency.",
            "Morning! Time to disappoint everyone who believes in you."
        ]
    }
}

private func getCompletionRoasts(for personality: PersonalityType, completionRate: Double) -> [String] {
    switch personality {
    case .sergeant:
        if completionRate == 1.0 {
            return ["IMPOSSIBLE! You actually did everything! I'm... mildly less disappointed."]
        } else {
            return ["Some progress! Don't let it go to your head, SOLDIER!"]
        }
    case .sassy:
        if completionRate == 1.0 {
            return ["WAIT. You actually did everything?! Who are you and what did you do with my lazy bestie?"]
        } else {
            return ["You did something! Your trophy is in the mail. JK it's not."]
        }
    case .passive:
        if completionRate == 1.0 {
            return ["100%? Well! This is... unexpected. I'll need to update my expectations."]
        } else {
            return ["Some progress! More than I expected, honestly."]
        }
    case .brutal:
        if completionRate == 1.0 {
            return ["Perfect completion? You've broken the pattern. Don't let it go to your head."]
        } else {
            return ["Partial success is still mostly failure. Math is brutal."]
        }
    }
}

private func getExcuseRoasts(for personality: PersonalityType, excuse: String, task: String) -> [String] {
    switch personality {
    case .sergeant:
        return [
            "PATHETIC EXCUSE, SOLDIER! '\(excuse)' won't complete '\(task)'!",
            "I've heard better excuses from DEAD FISH!"
        ]
    case .sassy:
        return [
            "'\(excuse)'? That's creative! Still not doing '\(task)' though.",
            "New excuse just dropped! Unfortunately '\(task)' still needs doing."
        ]
    case .passive:
        return [
            "'\(excuse)' - interesting take! '\(task)' still needs doing, but okay.",
            "I'll file '\(excuse)' under 'Classic Excuses, Volume 12.'"
        ]
    case .brutal:
        return [
            "'\(excuse)' - the creativity you waste on avoidance could fuel actual achievement.",
            "New excuse, same result. The only consistent thing is inconsistency."
        ]
    }
}

#Preview {
    HomeView(
        personality: .sassy,
        initialGoals: ["Go to gym", "Read 20 pages", "Finish project"]
    )
}