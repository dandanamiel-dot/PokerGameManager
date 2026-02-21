
import SwiftUI

struct EndGameSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GameViewModel
    var onCalculateSettlement: () -> Void
    
    @FocusState private var focusedField: UUID?
    
    // Ordered list of player session IDs for keyboard navigation
    private var sessionIDs: [UUID] {
        viewModel.activeSession.playerSessions.map { $0.id }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.spacingL) {
                        // MARK: - Header
                        Text("Cash Out")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        VStack(spacing: 4) {
                            Text("Verify or update final chip counts for each player")
                                .foregroundStyle(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                            
                            Text("Total must equal the pot of ₪\(viewModel.activeSession.totalPot, specifier: "%.0f")")
                                .font(.caption)
                                .foregroundStyle(AppTheme.accent.opacity(0.7))
                        }
                        
                        // MARK: - Player Cards
                        VStack(spacing: AppTheme.spacingM) {
                            ForEach($viewModel.activeSession.playerSessions) { $session in
                                let isFocused = focusedField == session.id
                                let alreadyCashedOut = session.cashOutTime != nil
                                
                                GlowCard {
                                    HStack(spacing: AppTheme.spacingS) {
                                        // Player icon
                                        Image(systemName: "person.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(alreadyCashedOut ? AppTheme.accent.opacity(0.3) : AppTheme.accent.opacity(0.6))
                                        
                                        // Player info
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(session.player?.name ?? "Unknown")
                                                .font(.title3)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.white)
                                            
                                            if alreadyCashedOut {
                                                Text("Cashed Out Mid-Game")
                                                    .font(.caption2)
                                                    .foregroundStyle(AppTheme.accent)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(AppTheme.accent.opacity(0.12))
                                                    .clipShape(Capsule())
                                            } else {
                                                Text("Buy-in: ₪\(session.totalBuyIn, specifier: "%.0f")")
                                                    .font(.caption2)
                                                    .foregroundStyle(AppTheme.textSecondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        if alreadyCashedOut {
                                            // Read-only display for already-cashed-out
                                            Text("₪\(session.cashOut ?? 0, specifier: "%.0f")")
                                                .font(.title2.bold())
                                                .foregroundStyle(AppTheme.accent.opacity(0.5))
                                                .frame(width: 110, alignment: .trailing)
                                        } else {
                                            // Editable cash-out input
                                            TextField("Enter amount", value: Binding(
                                                get: { session.cashOut ?? 0 },
                                                set: { session.cashOut = $0 }
                                            ), format: .number)
                                            .keyboardType(.numberPad)
                                            .multilineTextAlignment(.trailing)
                                            .foregroundStyle(AppTheme.accent)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .frame(width: 110)
                                            .padding(10)
                                            .background(AppTheme.inputBackground)
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(
                                                        isFocused ? AppTheme.inputBorderFocused : AppTheme.inputBorderDefault,
                                                        lineWidth: isFocused ? 2 : 1
                                                    )
                                            )
                                            .focused($focusedField, equals: session.id)
                                            .animation(.easeInOut(duration: 0.2), value: isFocused)
                                        }
                                    }
                                    .padding()
                                }
                                .frame(minHeight: 64)
                                
                                // Per-field validation hint
                                if !alreadyCashedOut, let co = session.cashOut, co > session.totalBuyIn * 5, session.totalBuyIn > 0 {
                                    Text("⚠️ Unusually high — double-check this value")
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.loss.opacity(0.8))
                                        .padding(.horizontal, 4)
                                        .transition(.opacity)
                                }
                            }
                        }
                        
                        // MARK: - Validation Summary
                        let totalBuyIn = viewModel.activeSession.totalPot
                        let totalCashOut = viewModel.activeSession.playerSessions.reduce(0.0) { $0 + ($1.cashOut ?? 0) }
                        let diff = totalCashOut - totalBuyIn
                        let isBalanced = abs(diff) <= 1
                        
                        if isBalanced {
                            Text("✅ Balanced")
                                .foregroundStyle(AppTheme.profit)
                                .fontWeight(.bold)
                        } else {
                            VStack(spacing: 4) {
                                Text("⚠️ Mismatch: ₪\(diff, specifier: "%.0f")")
                                    .foregroundStyle(AppTheme.loss)
                                    .fontWeight(.bold)
                                Text("Adjust values so the total equals the pot")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                        
                        Spacer().frame(height: 40)
                        
                        // MARK: - Action Button
                        if isBalanced {
                            AccentButton(title: "Calculate Settlement") {
                                viewModel.calculateSettlements()
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    onCalculateSettlement()
                                }
                            }
                        } else {
                            Button {} label: {
                                Text("Balance Required (₪\(abs(diff), specifier: "%.0f") off)")
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white.opacity(0.5))
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 24)
                                    .background(Color.gray.opacity(0.4))
                                    .cornerRadius(30)
                            }
                            .disabled(true)
                        }
                    }
                    .padding()
                }
                .toolbar {
                    // Keyboard navigation toolbar
                    ToolbarItemGroup(placement: .keyboard) {
                        Button {
                            focusPrevious()
                        } label: {
                            Image(systemName: "chevron.up")
                        }
                        
                        Button {
                            focusNext()
                        } label: {
                            Image(systemName: "chevron.down")
                        }
                        
                        Spacer()
                        
                        Button("Done") {
                            focusedField = nil
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
    }
    
    // MARK: - Keyboard Navigation Helpers
    
    private func focusPrevious() {
        guard let current = focusedField,
              let idx = sessionIDs.firstIndex(of: current),
              idx > 0 else { return }
        focusedField = sessionIDs[idx - 1]
    }
    
    private func focusNext() {
        guard let current = focusedField,
              let idx = sessionIDs.firstIndex(of: current),
              idx < sessionIDs.count - 1 else { return }
        focusedField = sessionIDs[idx + 1]
    }
}
