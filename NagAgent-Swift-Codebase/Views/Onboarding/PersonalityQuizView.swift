import SwiftUI

struct PersonalityQuizView: View {
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
                                    }
                                }
                            )
                            .scaleEffect(animateCards ? 1.0 : 0.8)
                            .opacity(animateCards ? 1.0 : 0.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: animateCards)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Sample Roast Preview
                    if let selectedPersonality = selectedPersonality {
                        let personality = personalities.first { $0.type == selectedPersonality }!
                        
                        VStack(spacing: 12) {
                            Text("Sample Roast:")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("\"\(personality.sampleRoast)\"")
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
                            
                            Text("- \(personality.name)")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                        .transition(.slide.combined(with: .opacity))
                        .animation(.easeInOut, value: selectedPersonality)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.bottom, 100) // Space for button
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
        }
        .fullScreenCover(isPresented: $showGoalSetting) {
            GoalSettingView(selectedPersonality: selectedPersonality!)
        }
    }
}

struct PersonalityCard: View {
    let personality: Personality
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Emoji
                Text(personality.emoji)
                    .font(.system(size: 40))
                
                // Name
                Text(personality.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Description
                Text(personality.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding()
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected 
                        ? Color.purple.opacity(0.3)
                        : Color.gray.opacity(0.1)
                    )
                    .stroke(
                        isSelected 
                        ? Color.purple
                        : Color.gray.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PersonalityQuizView()
}