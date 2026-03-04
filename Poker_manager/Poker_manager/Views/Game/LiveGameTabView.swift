import SwiftUI
import SwiftData

struct LiveGameTabView: View {
    let groupId: String
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allGames: [GameSession]
    @State private var showNewGameSheet = false
    @State private var showJoinGame = false
    private let firebaseService = FirebaseService.shared
    @State private var hasActiveRoom: Bool = FirebaseService.shared.activeRoom != nil
    @State private var isHost: Bool = FirebaseService.shared.isHost
    
    init(groupId: String) {
        self.groupId = groupId
        let gId = groupId
        _allGames = Query(
            filter: #Predicate<GameSession> { $0.groupId == gId }
        )
    }
    
    var activeGame: GameSession? {
        allGames.first { $0.status == .active }
    }
    
    var body: some View {
        Group {
            if let game = activeGame {
                GameSessionView(session: game, modelContext: modelContext, isEmbedded: true)
            } else if hasActiveRoom && !isHost {
                // Viewer mode — watching a remote game
                ViewerGameView()
            } else if showJoinGame {
            JoinGameView()
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
                    
                    // Join Game Button
                    Button {
                        showJoinGame = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                            Text("Join a Game")
                        }
                        .font(.headline)
                        .foregroundStyle(AppTheme.accent)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(
                            Capsule()
                                .stroke(AppTheme.accent.opacity(0.4), lineWidth: 1.5)
                        )
                    }
                    
                    Spacer()
                    Spacer()
                }
            }
            .sheet(isPresented: $showNewGameSheet) {
                NewGameSheet(groupId: groupId)
            }
        }
        }
        .onAppear {
            hasActiveRoom = firebaseService.activeRoom != nil
            isHost = firebaseService.isHost
        }
        .onReceive(firebaseService.$activeRoom) { room in
            hasActiveRoom = room != nil
        }
        .onReceive(firebaseService.$isHost) { hostValue in
            isHost = hostValue
        }
    }
}
