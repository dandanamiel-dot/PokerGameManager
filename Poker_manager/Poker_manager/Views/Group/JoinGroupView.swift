
import SwiftUI

struct JoinGroupView: View {
    let firebaseService = FirebaseService.shared
    @Environment(\.dismiss) private var dismiss
    
    var onGroupJoined: ((PokerGroup) -> Void)?
    
    @State private var groupCode = ""
    @State private var displayName = ""
    @State private var isJoining = false
    @State private var errorMessage: String?
    @State private var joinedGroup: PokerGroup?
    
    init(onGroupJoined: ((PokerGroup) -> Void)? = nil) {
        self.onGroupJoined = onGroupJoined
    }
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            if let group = joinedGroup {
                joinSuccessView(group: group)
            } else {
                joinFormView
            }
        }
    }
    
    // MARK: - Join Form
    
    private var joinFormView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            VStack(spacing: 12) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 50))
                    .foregroundStyle(AppTheme.accent)
                
                Text("Join a Group")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                
                Text("Enter the group code shared by your host")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
            }
            
            // Input Fields
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Group Code")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    
                    TextField("e.g. A3F29X", text: $groupCode)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1)
                        )
                        .onChange(of: groupCode) { _, newValue in
                            if newValue.count > 6 { groupCode = String(newValue.prefix(6)) }
                        }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Display Name")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    
                    TextField("e.g. Dana", text: $displayName)
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1)
                        )
                        .onChange(of: displayName) { _, newValue in
                            if newValue.count > 30 { displayName = String(newValue.prefix(30)) }
                        }
                }
            }
            .padding(.horizontal, 24)
            
            // Error
            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(error)
                }
                .font(.footnote)
                .foregroundStyle(.red)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.1))
                .clipShape(Capsule())
            }
            
            // Join Button
            Button {
                joinGroup()
            } label: {
                HStack {
                    if isJoining {
                        ProgressView().tint(.black)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Join Group")
                    }
                }
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(canJoin ? AppTheme.accent : Color.gray.opacity(0.3))
                )
            }
            .disabled(!canJoin || isJoining)
            .padding(.horizontal, 24)
            
            Spacer()
            Spacer()
        }
    }
    
    // MARK: - Success View
    
    private func joinSuccessView(group: PokerGroup) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            
            Text("You're In!")
                .font(.title.bold())
                .foregroundStyle(.white)
            
            Text("Joined \"\(group.name)\"")
                .foregroundStyle(.gray)
            
            HStack(spacing: 12) {
                Text("\(group.memberCount) member\(group.memberCount == 1 ? "" : "s")")
                    .foregroundStyle(AppTheme.accent)
                    .font(.headline)
                
                Text("•")
                    .foregroundStyle(.gray)
                
                Text("\(group.currencySymbol) \(group.currency)")
                    .foregroundStyle(AppTheme.accent.opacity(0.7))
                    .font(.headline)
            }
            
            Spacer()
            
            AccentButton(title: "Go to Group", icon: "arrow.right") {
                if let callback = onGroupJoined {
                    callback(group)
                } else {
                    dismiss()
                }
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Helpers
    
    private var canJoin: Bool {
        !groupCode.trimmingCharacters(in: .whitespaces).isEmpty &&
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func joinGroup() {
        guard canJoin else { return }
        isJoining = true
        errorMessage = nil
        
        firebaseService.joinGroup(code: groupCode.trimmingCharacters(in: .whitespaces),
                                   displayName: displayName.trimmingCharacters(in: .whitespaces)) { result in
            isJoining = false
            switch result {
            case .success(let group):
                withAnimation {
                    joinedGroup = group
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}
