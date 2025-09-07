import SwiftUI

struct TaskRowView: View {
    @Binding var task: Task
    let onComplete: () -> Void
    let onExcuse: (String) -> Void
    
    @State private var showExcuseSheet = false
    @State private var excuseText = ""
    @State private var animateCompletion = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Completion Button
            Button(action: {
                withAnimation(.spring(response: 0.4)) {
                    task.toggle()
                    animateCompletion = true
                }
                onComplete()
                
                // Reset animation after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    animateCompletion = false
                }
            }) {
                ZStack {
                    Circle()
                        .stroke(task.isCompleted ? Color.green : Color.gray, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if task.isCompleted {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                            .font(.system(size: 14, weight: .bold))
                            .scaleEffect(animateCompletion ? 1.3 : 1.0)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Task Content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.text)
                    .font(.body)
                    .foregroundColor(task.isCompleted ? .gray : .white)
                    .strikethrough(task.isCompleted)
                    .animation(.easeInOut(duration: 0.3), value: task.isCompleted)
                
                if let completedAt = task.completedAt {
                    Text("Completed at \(completedAt, formatter: timeFormatter)")
                        .font(.caption)
                        .foregroundColor(.green)
                        .transition(.opacity.combined(with: .slide))
                }
            }
            
            Spacer()
            
            // Action Buttons
            if !task.isCompleted {
                HStack(spacing: 8) {
                    // Excuse Button
                    Button(action: {
                        showExcuseSheet = true
                    }) {
                        Text("Make Excuse")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.2))
                                    .stroke(Color.red.opacity(0.5), lineWidth: 1)
                            )
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(task.isCompleted ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                .stroke(
                    task.isCompleted ? Color.green.opacity(0.3) : Color.gray.opacity(0.3),
                    lineWidth: 1
                )
        )
        .scaleEffect(animateCompletion ? 1.02 : 1.0)
        .sheet(isPresented: $showExcuseSheet) {
            ExcuseInputSheet(
                taskText: task.text,
                onSubmit: { excuse in
                    onExcuse(excuse)
                    showExcuseSheet = false
                }
            )
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

struct ExcuseInputSheet: View {
    let taskText: String
    let onSubmit: (String) -> Void
    
    @State private var excuseText = ""
    @Environment(\.dismiss) private var dismiss
    
    private let commonExcuses = [
        "I'm too tired",
        "I don't have time",
        "I'll do it tomorrow",
        "I forgot",
        "I'm not feeling it",
        "Something came up",
        "The weather is bad",
        "I'm too busy"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text("🤡")
                            .font(.system(size: 60))
                        
                        Text("Making an excuse for:")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text(taskText)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Custom excuse input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Excuse:")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("Type your excuse here...", text: $excuseText, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    .padding(.horizontal)
                    
                    // Common excuses
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Or pick a classic:")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(commonExcuses, id: \.self) { excuse in
                                Button(excuse) {
                                    excuseText = excuse
                                }
                                .font(.body)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.2))
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Submit button
                    Button(action: {
                        if !excuseText.trimmingCharacters(in: .whitespaces).isEmpty {
                            onSubmit(excuseText)
                        }
                    }) {
                        Text("Submit Excuse (and Get Roasted)")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.red, .orange]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .padding(.horizontal)
                    }
                    .disabled(excuseText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("Excuse Generator")
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

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 16) {
            TaskRowView(
                task: .constant(Task(text: "Go to the gym")),
                onComplete: { print("Completed") },
                onExcuse: { excuse in print("Excuse: \(excuse)") }
            )
            
            TaskRowView(
                task: .constant(Task(text: "Read 20 pages", isCompleted: true)),
                onComplete: { print("Completed") },
                onExcuse: { excuse in print("Excuse: \(excuse)") }
            )
        }
        .padding()
    }
}