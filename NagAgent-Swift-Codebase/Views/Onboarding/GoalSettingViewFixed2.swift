import SwiftUI

struct GoalSettingViewFixed2: View {
    let selectedPersonality: PersonalityType
    @StateObject private var personalityManager = PersonalityManager.shared
    
    @State private var goalText = ""
    @State private var goals: [String] = []
    @State private var showHome = false
    @State private var animateContent = false
    
    var body: some View {
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
                    // Header with personality
                    VStack(spacing: 16) {
                        HStack {
                            Text(personalityManager.selectedPersonality.emoji)
                                .font(.system(size: 40))
                            
                            VStack(alignment: .leading) {
                                Text(personalityManager.selectedPersonality.displayName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("is ready to coach you")
                                    .font(.body)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.1))
                        )
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(.easeIn(duration: 0.6), value: animateContent)
                        
                        Text("Set Your Daily Goals")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .animation(.easeIn(duration: 0.6).delay(0.2), value: animateContent)
                        
                        Text(getPersonalityMessage())
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .animation(.easeIn(duration: 0.6).delay(0.4), value: animateContent)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal)
                    
                    // Goal Input - FIXED VERSION
                    VStack(spacing: 16) {
                        HStack {
                            TextField("Enter a goal...", text: $goalText)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                                .onSubmit {
                                    addGoal()
                                }
                            
                            // FIXED: Button now properly adds goals
                            Button(action: {
                                print("🎯 Add button tapped with text: '\(goalText)'")
                                addGoal()
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(goalText.isEmpty ? .gray : .purple)
                            }
                            .disabled(goalText.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .padding(.horizontal)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(.easeIn(duration: 0.6).delay(0.6), value: animateContent)
                        
                        // Debug info
                        #if DEBUG
                        Text("Goal text: '\(goalText)' | Count: \(goals.count)")
                            .font(.caption)
                            .foregroundColor(.yellow)
                            .padding(.horizontal)
                        #endif
                        
                        // Sample goals - These also work as buttons
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Examples (tap to use):")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(sampleGoals, id: \.self) { goal in
                                    Button(action: {
                                        print("📝 Sample goal tapped: \(goal)")
                                        goalText = goal
                                        // Optionally auto-add sample goals
                                        // addGoal()
                                    }) {
                                        Text(goal)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.gray.opacity(0.2))
                                            )
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(.easeIn(duration: 0.6).delay(0.8), value: animateContent)
                    }
                    
                    // Current Goals List
                    if !goals.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Today's Goals:")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("\(goals.count) goals")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal)
                            
                            ForEach(Array(goals.enumerated()), id: \.offset) { index, goal in
                                HStack {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundColor(.green)
                                    
                                    Text(goal)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        withAnimation(.spring()) {
                                            print("🗑️ Removing goal at index \(index): \(goal)")
                                            goals.remove(at: index)
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.1))
                                )
                                .transition(.asymmetric(
                                    insertion: .slide.combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                            }
                            .padding(.horizontal)
                        }
                        .animation(.spring(), value: goals)
                    } else {
                        // Empty state
                        VStack {
                            Text("💭")
                                .font(.system(size: 40))
                            Text("No goals yet")
                                .foregroundColor(.gray)
                            Text("Add some goals above to get started!")
                                .font(.caption)
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.bottom, 100)
            }
            
            // Continue Button (fixed at bottom)
            VStack {
                Spacer()
                
                if !goals.isEmpty {
                    VStack(spacing: 10) {
                        Text("\(goals.count) goal\(goals.count == 1 ? "" : "s") ready")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            print("🚀 Starting with \(goals.count) goals")
                            showHome = true
                        }) {
                            Text(getStartButtonText())
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
                        }
                    }
                    .padding(.horizontal, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(), value: goals.count)
                }
            }
        }
        .onAppear {
            animateContent = true
            personalityManager.setPersonality(selectedPersonality)
            print("📱 GoalSettingView appeared with personality: \(selectedPersonality.displayName)")
        }
        .fullScreenCover(isPresented: $showHome) {
            HomeViewFixed(personality: personalityManager.selectedPersonality, initialGoals: goals)
        }
    }
    
    // FIXED: Add goal function with better error handling
    private func addGoal() {
        let trimmedGoal = goalText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("➕ Attempting to add goal: '\(trimmedGoal)'")
        
        guard !trimmedGoal.isEmpty else {
            print("❌ Goal is empty, not adding")
            return
        }
        
        guard !goals.contains(trimmedGoal) else {
            print("⚠️ Goal already exists: '\(trimmedGoal)'")
            // Optionally show an alert here
            return
        }
        
        withAnimation(.spring()) {
            goals.append(trimmedGoal)
            print("✅ Goal added successfully: '\(trimmedGoal)'. Total goals: \(goals.count)")
            goalText = "" // Clear the text field
        }
    }
    
    private func getPersonalityMessage() -> String {
        switch personalityManager.selectedPersonality {
        case .sergeant:
            return "WHAT ARE YOUR MISSION OBJECTIVES, SOLDIER? Make them clear and measurable!"
        case .sassy:
            return "What do you want to accomplish today? Your nagger is watching... 👀"
        case .passive:
            return "Please enter your goals for today. I'm sure you'll... try your best."
        case .brutal:
            return "List your delusions of productivity. I'll be here to watch you fail."
        }
    }
    
    private func getStartButtonText() -> String {
        switch personalityManager.selectedPersonality {
        case .sergeant:
            return "BEGIN TRAINING!"
        case .sassy:
            return "Start Getting Roasted"
        case .passive:
            return "Proceed to Accountability"
        case .brutal:
            return "Begin the Suffering"
        }
    }
    
    private var sampleGoals: [String] {
        [
            "Go to gym",
            "Read 20 pages",
            "Finish project",
            "Meditate 10 min",
            "Call mom",
            "Drink 8 glasses",
            "No social media",
            "Cook dinner"
        ]
    }
}

// SwiftUI Preview
#Preview {
    GoalSettingViewFixed2(selectedPersonality: .sassy)
}

#Preview("Brutal Brandon") {
    GoalSettingViewFixed2(selectedPersonality: .brutal)
}