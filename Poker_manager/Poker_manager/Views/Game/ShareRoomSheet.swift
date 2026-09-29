
import SwiftUI

struct ShareRoomSheet: View {
    let roomCode: String
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 40))
                    .foregroundStyle(AppTheme.accent)
                
                Text("Game Room Live")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                
                Text("Share this code with players at the table")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            
            // Room Code Display
            VStack(spacing: 12) {
                Text("ROOM CODE")
                    .font(.caption.bold())
                    .foregroundStyle(.gray)
                    .tracking(2)
                
                HStack(spacing: 8) {
                    ForEach(Array(roomCode.enumerated()), id: \.offset) { _, digit in
                        Text(String(digit))
                            .font(.system(size: 34, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 64)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.04))
            )
            
            // Copy Button
            Button {
                UIPasteboard.general.string = roomCode
                withAnimation(.spring(response: 0.3)) {
                    copied = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { copied = false }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                    Text(copied ? "Copied!" : "Copy Code")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(copied ? .green : AppTheme.accent)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill((copied ? Color.green : AppTheme.accent).opacity(0.15))
                )
            }
            
            // Info
            VStack(spacing: 6) {
                Label("Players join from their device", systemImage: "iphone.gen3")
                Label("Group members see the game in their Live tab", systemImage: "eye")
                Label("Make someone an admin in Players & Admins", systemImage: "crown")
            }
            .font(.footnote)
            .foregroundStyle(.gray)
            
            Spacer()
            
            // Done Button
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(AppTheme.accent)
                    )
            }
        }
        .padding(24)
        .background(AppTheme.background.ignoresSafeArea())
    }
}
