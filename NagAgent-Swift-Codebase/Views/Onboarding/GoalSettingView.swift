import SwiftUI

struct GoalSettingView: View {
    let selectedPersonality: PersonalityType
    
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
                            Text(selectedPersonality.emoji)
                                .font(.system(size: 40))
                            
                            VStack(alignment: .leading) {
                                Text(selectedPersonality.displayName)
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
                        
                        Text("What do you want to accomplish today? Your nagger is watching... 👀")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .animation(.easeIn(duration: 0.6).delay(0.4), value: animateContent)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal)
                    
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
                        Text("Start Getting Roasted")
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
        }
        .fullScreenCover(isPresented: $showHome) {
            HomeView(personality: selectedPersonality, initialGoals: goals)
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

#Preview {
    GoalSettingView(selectedPersonality: .sassy)
}