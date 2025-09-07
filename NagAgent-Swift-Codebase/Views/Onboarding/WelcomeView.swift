import SwiftUI

struct WelcomeView: View {
    @State private var showPersonalityQuiz = false
    @State private var animateTitle = false
    @State private var animateSubtitle = false
    @State private var animateButton = false
    
    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                gradient: Gradient(colors: [.black, .purple.opacity(0.3), .black]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // App Icon/Logo
                VStack(spacing: 20) {
                    Text("🔥")
                        .font(.system(size: 80))
                        .scaleEffect(animateTitle ? 1.0 : 0.5)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animateTitle)
                    
                    Text("NagAgent")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(animateTitle ? 1.0 : 0.0)
                        .animation(.easeIn(duration: 1.0).delay(0.5), value: animateTitle)
                }
                
                // Subtitle
                VStack(spacing: 16) {
                    Text("The AI That Bullies You")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(animateSubtitle ? 1.0 : 0.0)
                        .animation(.easeIn(duration: 0.8).delay(1.0), value: animateSubtitle)
                    
                    Text("Into Productivity")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                        .opacity(animateSubtitle ? 1.0 : 0.0)
                        .animation(.easeIn(duration: 0.8).delay(1.2), value: animateSubtitle)
                    
                    Text("Choose your accountability coach and get roasted into success")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .opacity(animateSubtitle ? 1.0 : 0.0)
                        .animation(.easeIn(duration: 0.8).delay(1.4), value: animateSubtitle)
                }
                
                Spacer()
                
                // Sample roast preview
                VStack(spacing: 16) {
                    Text("Sample Roast:")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .opacity(animateButton ? 1.0 : 0.0)
                    
                    Text("\"Ready to disappoint both of us again? 💅\"")
                        .font(.body)
                        .foregroundStyle(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.purple.opacity(0.2))
                                .stroke(Color.purple.opacity(0.5), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        .opacity(animateButton ? 1.0 : 0.0)
                        .animation(.easeIn(duration: 0.8).delay(1.8), value: animateButton)
                    
                    Text("- Sassy Susan")
                        .font(.caption)
                        .foregroundColor(.purple)
                        .opacity(animateButton ? 1.0 : 0.0)
                }
                
                Spacer()
                
                // Get Started Button
                Button(action: {
                    showPersonalityQuiz = true
                }) {
                    HStack {
                        Text("Choose Your Nagger")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Image(systemName: "arrow.right")
                            .font(.headline)
                    }
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
                .scaleEffect(animateButton ? 1.0 : 0.8)
                .opacity(animateButton ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(2.0), value: animateButton)
                
                Spacer()
            }
        }
        .onAppear {
            animateTitle = true
            animateSubtitle = true
            animateButton = true
        }
        .fullScreenCover(isPresented: $showPersonalityQuiz) {
            PersonalityQuizView()
        }
    }
}

#Preview {
    WelcomeView()
}