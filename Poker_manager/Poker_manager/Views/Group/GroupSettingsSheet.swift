
import SwiftUI

struct GroupSettingsSheet: View {
    let group: PokerGroup
    
    @ObservedObject private var firebaseService = FirebaseService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showLeaveConfirmation = false
    @State private var codeCopied = false
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Handle bar
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                
                Text("Group Settings")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                
                // Group Code Section
                GlowCard {
                    VStack(spacing: 12) {
                        Text("Group Code")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        
                        Text(currentGroup.groupId)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppTheme.accent)
                            .kerning(3)
                        
                        HStack(spacing: 12) {
                            Button {
                                UIPasteboard.general.string = currentGroup.groupId
                                withAnimation { codeCopied = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation { codeCopied = false }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: codeCopied ? "checkmark" : "doc.on.doc")
                                    Text(codeCopied ? "Copied!" : "Copy Code")
                                }
                                .font(.subheadline.bold())
                                .foregroundStyle(AppTheme.accent)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(AppTheme.accent.opacity(0.15))
                                .clipShape(Capsule())
                            }
                            
                            ShareLink(
                                item: "Join my poker group \"\(currentGroup.name)\" using code: \(currentGroup.groupId)",
                                subject: Text("Poker Group Invite"),
                                message: Text("Join my poker group!")
                            ) {
                                HStack(spacing: 4) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share")
                                }
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                
                // Members List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Members (\(currentGroup.memberCount))")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal)
                    
                    ForEach(Array(currentGroup.memberNames), id: \.key) { uid, name in
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundStyle(AppTheme.accent.opacity(0.7))
                                .font(.title3)
                            
                            Text(name)
                                .foregroundStyle(.white)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            if uid == currentGroup.createdBy {
                                Text("Host")
                                    .font(.caption.bold())
                                    .foregroundStyle(AppTheme.accent)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(AppTheme.accent.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding()
                        .background(AppTheme.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
                
                // Leave Group
                Button {
                    showLeaveConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Leave Group")
                    }
                    .font(.headline)
                    .foregroundStyle(.red)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(14)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .alert("Leave Group?", isPresented: $showLeaveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Leave", role: .destructive) {
                firebaseService.leaveGroup(groupId: group.groupId)
                dismiss()
            }
        } message: {
            Text("You'll need the group code to rejoin.")
        }
    }
    
    private var currentGroup: PokerGroup {
        firebaseService.activeGroup ?? group
    }
}
