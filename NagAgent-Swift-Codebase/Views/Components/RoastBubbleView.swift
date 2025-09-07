import SwiftUI

struct RoastBubbleView: View {
    let roast: String
    let personality: PersonalityType
    let onShare: (() -> Void)?
    
    @State private var animateIn = false
    @State private var showShareButton = false
    
    init(roast: String, personality: PersonalityType, onShare: (() -> Void)? = nil) {
        self.roast = roast
        self.personality = personality
        self.onShare = onShare
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Personality Header
            HStack {
                Text(personality.emoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(personality.displayName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("says...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if let onShare = onShare, showShareButton {
                    Button(action: onShare) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundColor(.purple)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            
            // Roast Content
            Text(roast)
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(personalityBackgroundColor)
                .stroke(personalityAccentColor, lineWidth: 1)
        )
        .scaleEffect(animateIn ? 1.0 : 0.8)
        .opacity(animateIn ? 1.0 : 0.0)
        .rotation3DEffect(
            .degrees(animateIn ? 0 : -15),
            axis: (x: 1, y: 0, z: 0)
        )
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateIn = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeIn(duration: 0.3)) {
                    showShareButton = true
                }
            }
        }
    }
    
    private var personalityBackgroundColor: Color {
        switch personality {
        case .sergeant:
            return Color.red.opacity(0.2)
        case .sassy:
            return Color.purple.opacity(0.2)
        case .passive:
            return Color.blue.opacity(0.2)
        case .brutal:
            return Color.black.opacity(0.4)
        }
    }
    
    private var personalityAccentColor: Color {
        switch personality {
        case .sergeant:
            return Color.red.opacity(0.6)
        case .sassy:
            return Color.purple.opacity(0.6)
        case .passive:
            return Color.blue.opacity(0.6)
        case .brutal:
            return Color.gray.opacity(0.6)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 20) {
            RoastBubbleView(
                roast: "Morning bestie! Ready to disappoint both of us again? 💅",
                personality: .sassy
            ) {
                print("Share tapped")
            }
            
            RoastBubbleView(
                roast: "RISE AND SHINE, MAGGOT! Time to disappoint me again!",
                personality: .sergeant
            )
            
            RoastBubbleView(
                roast: "Your potential called. It's filing a missing person report.",
                personality: .brutal
            )
        }
        .padding()
    }
}