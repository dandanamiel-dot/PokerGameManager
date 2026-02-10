import SwiftUI
import SwiftData

struct LiveGameTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allGames: [GameSession]
    @State private var showNewGameSheet = false
    
    var activeGame: GameSession? {
        allGames.first { $0.status == .active }
    }
    
    var body: some View {
        if let game = activeGame {
            GameSessionView(session: game, modelContext: modelContext, isEmbedded: true)
        } else {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    Image(systemName: "suit.spade.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.3))
                    
                    Text("No Active Game")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text("Start a new session to track chips,\nbuys-ins, and cash-outs.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal)
                    
                    AccentButton(title: "Start New Game", icon: "plus") {
                        showNewGameSheet = true
                    }
                    .padding(.top)
                    
                    Spacer()
                    Spacer()
                }
            }
            .sheet(isPresented: $showNewGameSheet) {
                NewGameSheet()
            }
        }
    }
}
