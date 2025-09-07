import SwiftUI

struct GoalSettingViewFixed: View {
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
                    // Header with personality - USES ACTUAL SELECTED PERSONALITY
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
                        
                        // Personality-specific message
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
                    
                    // Rest of the view remains the same...
                    // Goal Input
                    VStack(spacing: 16) {
                        HStack {
                            TextField("Enter a goal...", text: $goalText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onSubmit {
                                    addGoal()
                                }
                            
                            Button(action: addGoal) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.purple)
                            }
                            .disabled(goalText.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .padding(.horizontal)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(.easeIn(duration: 0.6).delay(0.6), value: animateContent)
                        
                        // Sample goals
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Examples:")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(sampleGoals, id: \.self) { goal in
                                    Button(goal) {
                                        goalText = goal
                                    }
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
                        .padding(.horizontal)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(.easeIn(duration: 0.6).delay(0.8), value: animateContent)
                    }
                    
                    // Current Goals List
                    if !goals.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Today's Goals:")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            ForEach(Array(goals.enumerated()), id: \.offset) { index, goal in
                                HStack {
                                    Text("✓")
                                        .foregroundColor(.green)
                                    
                                    Text(goal)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        withAnimation {
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
                                .transition(.slide.combined(with: .opacity))
                            }
                            .padding(.horizontal)
                        }
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(.easeIn(duration: 0.6).delay(1.0), value: animateContent)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.bottom, 100)
            }
            
            // Continue Button (fixed at bottom)
            VStack {
                Spacer()
                
                if !goals.isEmpty {
                    Button(action: {
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
                            .padding(.horizontal, 32)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(), value: goals.isEmpty)
                }
            }
        }
        .onAppear {
            animateContent = true
            // Ensure personality is set
            personalityManager.setPersonality(selectedPersonality)
        }
        .fullScreenCover(isPresented: $showHome) {
            // Pass the CORRECT personality to HomeView
            HomeViewFixed(personality: personalityManager.selectedPersonality, initialGoals: goals)
        }
    }
    
    private func addGoal() {
        let trimmedGoal = goalText.trimmingCharacters(in: .whitespaces)
        if !trimmedGoal.isEmpty && !goals.contains(trimmedGoal) {
            withAnimation(.spring()) {
                goals.append(trimmedGoal)
                goalText = ""
            }
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