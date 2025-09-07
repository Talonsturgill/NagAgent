import SwiftUI

struct PersonalityQuizViewFixed: View {
    @StateObject private var personalityManager = PersonalityManager.shared
    @State private var personalities = PersonalityType.allCases.map { Personality(type: $0) }
    @State private var selectedPersonality: PersonalityType?
    @State private var showGoalSetting = false
    @State private var animateCards = false
    
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
                    // Header
                    VStack(spacing: 16) {
                        Text("Choose Your")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Accountability Style")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                        
                        Text("Pick the personality that will roast you into productivity")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Personality Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(Array(personalities.enumerated()), id: \.element.id) { index, personality in
                            PersonalityCard(
                                personality: personality,
                                isSelected: selectedPersonality == personality.type,
                                onTap: {
                                    withAnimation(.spring()) {
                                        selectedPersonality = personality.type
                                        // IMPORTANT: Save the selection immediately
                                        personalityManager.setPersonality(personality.type)
                                    }
                                }
                            )
                            .scaleEffect(animateCards ? 1.0 : 0.8)
                            .opacity(animateCards ? 1.0 : 0.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: animateCards)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Sample Roast Preview - USES SELECTED PERSONALITY
                    if let selectedPersonality = selectedPersonality {
                        VStack(spacing: 12) {
                            Text("Sample Roast:")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            // This will now show the correct personality's roast
                            Text("\"\(personalityManager.getRoastForContext(.morning(taskCount: 3)))\"")
                                .font(.body)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.gray.opacity(0.2))
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .padding(.horizontal)
                            
                            Text("- \(selectedPersonality.displayName)")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                        .transition(.slide.combined(with: .opacity))
                        .animation(.easeInOut, value: selectedPersonality)
                    }
                    
                    // Debug Info (remove in production)
                    #if DEBUG
                    VStack {
                        Text("Selected: \(selectedPersonality?.displayName ?? "None")")
                            .foregroundColor(.green)
                        Text("Saved: \(personalityManager.selectedPersonality.displayName)")
                            .foregroundColor(.yellow)
                    }
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
                    #endif
                    
                    Spacer(minLength: 100)
                }
                .padding(.bottom, 100)
            }
            
            // Continue Button (fixed at bottom)
            VStack {
                Spacer()
                
                if selectedPersonality != nil {
                    Button(action: {
                        showGoalSetting = true
                    }) {
                        Text("Let's Get Started")
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
                    .animation(.spring(), value: selectedPersonality)
                }
            }
        }
        .onAppear {
            animateCards = true
            // Load any previously selected personality
            if personalityManager.selectedPersonality != .sassy {
                selectedPersonality = personalityManager.selectedPersonality
            }
        }
        .fullScreenCover(isPresented: $showGoalSetting) {
            // Pass the ACTUAL selected personality
            GoalSettingViewFixed(selectedPersonality: personalityManager.selectedPersonality)
        }
    }
}