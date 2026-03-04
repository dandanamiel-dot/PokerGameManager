import SwiftUI

struct PastActivitiesSheet: View {
    let events: [ActivityEvent]
    let currencySymbol: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(events.enumerated()), id: \.offset) { index, event in
                            HStack(alignment: .top, spacing: 16) {
                                Text(event.time.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .frame(width: 90, alignment: .trailing)
                                    .padding(.top, 2)
                                
                                // Timeline dot & line
                                VStack(spacing: 0) {
                                    Circle()
                                        .fill(AppTheme.accent)
                                        .frame(width: 12, height: 12)
                                        .shadow(color: AppTheme.accent.opacity(0.8), radius: 4)
                                    
                                    if index < events.count - 1 {
                                        Rectangle()
                                            .fill(AppTheme.accent.opacity(0.6))
                                            .frame(width: 2)
                                            .padding(.vertical, 2)
                                    }
                                }
                                
                                // Event content
                                Text(eventDescription(for: event))
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                    .padding(.bottom, index == events.count - 1 ? 0 : 32)
                                
                                Spacer()
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Past Activities")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
    }
    
    private func eventDescription(for event: ActivityEvent) -> AttributedString {
        var str = AttributedString("\(event.playerName) ")
        str.font = .subheadline.bold()
        
        var actionStr: AttributedString
        switch event.type {
        case .joined:
            actionStr = AttributedString("joined the game")
        case .buyIn(let amount):
            actionStr = AttributedString("bought in for \(currencySymbol)\(String(format: "%.0f", amount))")
        case .cashOut(let amount):
            actionStr = AttributedString("cashed out \(currencySymbol)\(String(format: "%.0f", amount))")
        case .ended:
            return AttributedString("Game ended")
        }
        
        return str + actionStr
    }
}
