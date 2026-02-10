
import SwiftUI
import SwiftData

struct GameSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: GameViewModel
    @State private var showAddBuyIn = false
    @State private var showEndGame = false
    
    init(session: GameSession, modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: GameViewModel(modelContext: modelContext, session: session))
    }
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header / Navbar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.white)
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Game Session")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Button {
                        // Menu action
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(.white)
                            .padding()
                    }
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Pot Display
                        VStack(spacing: 8) {
                            Text("Current Pot")
                                .foregroundStyle(AppTheme.textSecondary)
                                .font(.subheadline)
                            
                            Text("₪\(viewModel.activeSession.totalPot, specifier: "%.0f")")
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.accent)
                                .shadow(color: AppTheme.accent.opacity(0.3), radius: 20)
                        }
                        .padding(.vertical, 20)
                        
                        // Action Buttons
                        HStack(spacing: 16) {
                            AccentButton(title: "Buy In", icon: "plus.circle.fill") {
                                showAddBuyIn = true
                            }
                            
                            Button {
                                showEndGame = true
                            } label: {
                                HStack {
                                    Image(systemName: "flag.checkered")
                                    Text("End Game")
                                }
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 24)
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(30)
                            }
                        }
                        
                        // Players List
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Players (\(viewModel.activeSession.playerSessions.count))")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal)
                            
                            ForEach(viewModel.activeSession.playerSessions) { session in
                                PlayerRow(
                                    name: session.player?.name ?? "Unknown",
                                    detail: "\(session.buyIns.count) buy-ins",
                                    amount: "₪\(String(format: "%.0f", session.totalBuyIn))",
                                    isPositive: true // Just showing invested amount, always positive context
                                )
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showAddBuyIn) {
            AddBuyInSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showEndGame) {
            EndGameSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showSettlementView) {
            SettlementView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.fetchPlayers()
        }
    }
}
