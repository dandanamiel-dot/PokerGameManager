
import SwiftUI
import SwiftData

struct GroupSettingsSheet: View {
    let group: PokerGroup
    
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var firebaseService = FirebaseService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showLeaveConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var memberToRemove: (uid: String, name: String)?
    @State private var showRemoveConfirmation = false
    @State private var codeCopied = false
    @State private var errorMessage: String?
    
    private var isHost: Bool {
        firebaseService.currentUserId == currentGroup.createdBy
    }
    
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
                ScrollView {
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
                                } else if isHost {
                                    // Host can remove other members
                                    Button {
                                        memberToRemove = (uid: uid, name: name)
                                        showRemoveConfirmation = true
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.red.opacity(0.7))
                                            .font(.title3)
                                    }
                                }
                            }
                            .padding()
                            .background(AppTheme.cardBackground)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Error message
                if let error = errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    // Delete Group — host only
                    if isHost {
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Delete Group")
                            }
                            .font(.headline)
                            .foregroundStyle(.red)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(14)
                        }
                    }
                    
                    // Leave Group
                    Button {
                        showLeaveConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Leave Group")
                        }
                        .font(.headline)
                        .foregroundStyle(.red.opacity(0.7))
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.05))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.red.opacity(0.2), lineWidth: 1)
                        )
                    }
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
        .alert("Delete Group?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                firebaseService.deleteGroup(groupId: group.groupId) { result in
                    switch result {
                    case .success:
                        dismiss()
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            }
        } message: {
            Text("This will permanently delete the group for all members. This cannot be undone.")
        }
        .alert("Remove Member?", isPresented: $showRemoveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                if let member = memberToRemove {
                    firebaseService.removeMember(groupId: group.groupId, memberUid: member.uid) { result in
                        switch result {
                        case .success:
                            // Also remove the local player if it exists
                            removeLocalPlayer(name: member.name)
                        case .failure(let error):
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        } message: {
            if let member = memberToRemove {
                Text("Remove \(member.name) from the group? They'll need the code to rejoin.")
            }
        }
    }
    
    private var currentGroup: PokerGroup {
        firebaseService.activeGroup ?? group
    }
    
    private func removeLocalPlayer(name: String) {
        let gId = group.groupId
        do {
            let descriptor = FetchDescriptor<Player>(
                predicate: #Predicate { $0.groupId == gId && $0.name == name }
            )
            let players = try modelContext.fetch(descriptor)
            for player in players {
                modelContext.delete(player)
            }
            try modelContext.save()
        } catch {
            print("Failed to remove local player: \(error)")
        }
    }
}
