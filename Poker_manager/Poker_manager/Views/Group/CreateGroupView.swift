
import SwiftUI

struct CreateGroupView: View {
    let firebaseService = FirebaseService.shared
    @Environment(\.dismiss) private var dismiss
    
    var onGroupCreated: ((PokerGroup) -> Void)?
    
    @State private var groupName = ""
    @State private var displayName = ""
    @State private var selectedCurrency: CurrencyOption = .ILS
    @State private var defaultBuyInText = ""
    @State private var isCreating = false
    @State private var createdGroup: PokerGroup?
    @State private var errorMessage: String?
    
    init(onGroupCreated: ((PokerGroup) -> Void)? = nil) {
        self.onGroupCreated = onGroupCreated
    }
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            if let group = createdGroup {
                // Success — show group code
                groupCreatedView(group: group)
            } else {
                createFormView
            }
        }
    }
    
    // MARK: - Create Form
    
    private var createFormView: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Icon
                VStack(spacing: 12) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(AppTheme.accent)
                    
                    Text("Create a Group")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                    
                    Text("Give your poker group a name\nand set preferences")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
            
            // Input Fields
            VStack(spacing: 16) {
                // Group Name
                VStack(alignment: .leading, spacing: 6) {
                    Text("Group Name")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    
                    TextField("e.g. Friday Night Poker", text: $groupName)
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1)
                        )
                        .onChange(of: groupName) { _, newValue in
                            if newValue.count > 30 { groupName = String(newValue.prefix(30)) }
                        }
                }
                
                // Display Name
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
                
                // Currency Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Currency")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    
                    HStack(spacing: 10) {
                        ForEach(CurrencyOption.allCases) { option in
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedCurrency = option
                                }
                            } label: {
                                VStack(spacing: 4) {
                                    Text(option.symbol)
                                        .font(.title2.bold())
                                    Text(option.rawValue)
                                        .font(.caption2)
                                }
                                .foregroundStyle(selectedCurrency == option ? .black : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedCurrency == option ? AppTheme.accent : Color.white.opacity(0.08))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedCurrency == option ? Color.clear : AppTheme.accent.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                    }
                }
                
                // Default Buy-In (optional)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Default Buy-In (optional)")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    
                    HStack {
                        Text(selectedCurrency.symbol)
                            .foregroundStyle(AppTheme.accent)
                            .fontWeight(.bold)
                        
                        TextField("e.g. 50", text: $defaultBuyInText)
                            .keyboardType(.decimalPad)
                            .foregroundStyle(.white)
                    }
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 24)
            
            // Error
            if let error = errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            
            // Create Button
            Button {
                createGroup()
            } label: {
                HStack {
                    if isCreating {
                        ProgressView().tint(.black)
                    } else {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Group")
                    }
                }
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(canCreate ? AppTheme.accent : Color.gray.opacity(0.3))
                )
            }
            .disabled(!canCreate || isCreating)
            .padding(.horizontal, 24)
            }
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    // MARK: - Success View
    
    private func groupCreatedView(group: PokerGroup) -> some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            
            Text("Group Created!")
                .font(.title.bold())
                .foregroundStyle(.white)
            
            Text("Share this code with your friends")
                .foregroundStyle(.gray)
            
            // Group Code Display
            VStack(spacing: 12) {
                Text(group.groupId)
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppTheme.accent)
                    .kerning(4)
                
                Text(group.name)
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                
                HStack(spacing: 6) {
                    Text(group.currencySymbol)
                        .font(.caption.bold())
                    Text(group.currency)
                        .font(.caption)
                }
                .foregroundStyle(AppTheme.accent.opacity(0.7))
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)
            
            // Action Buttons
            HStack(spacing: 16) {
                Button {
                    UIPasteboard.general.string = group.groupId
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Copy")
                    }
                    .font(.headline)
                    .foregroundStyle(AppTheme.accent)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(
                        Capsule()
                            .stroke(AppTheme.accent, lineWidth: 1.5)
                    )
                }
                
                ShareLink(
                    item: "Join my poker group \"\(group.name)\" using code: \(group.groupId)",
                    subject: Text("Poker Group Invite"),
                    message: Text("Join my poker group!")
                ) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.headline)
                    .foregroundStyle(.black)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(AppTheme.accent)
                    .clipShape(Capsule())
                }
            }
            
            Spacer()
            
            AccentButton(title: "Go to Group", icon: "arrow.right") {
                if let callback = onGroupCreated {
                    callback(group)
                } else {
                    dismiss()
                }
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Helpers
    
    private var canCreate: Bool {
        !groupName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func createGroup() {
        guard canCreate else { return }
        isCreating = true
        errorMessage = nil
        
        let buyIn = Double(defaultBuyInText.trimmingCharacters(in: .whitespaces))
        
        firebaseService.createGroup(
            name: groupName.trimmingCharacters(in: .whitespaces),
            displayName: displayName.trimmingCharacters(in: .whitespaces),
            currency: selectedCurrency,
            defaultBuyIn: buyIn
        ) { result in
            isCreating = false
            switch result {
            case .success(let group):
                withAnimation {
                    createdGroup = group
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}
