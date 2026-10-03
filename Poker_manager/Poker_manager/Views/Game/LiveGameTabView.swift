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
    @State private var groupLiveRooms: [GameRoom] = []
    @State private var joiningCode: String?
    @State private var joinError: String?
    
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
                // Watching (or co-running) a game hosted on another phone
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
                    
                    // Games already running in this group, one tap to watch
                    ForEach(groupLiveRooms, id: \.roomCode) { room in
                        liveRoomCard(room)
                    }
                    .padding(.horizontal)
                    
                    if let joinError {
                        Text(joinError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                    
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
            firebaseService.listenToGroupRooms(groupId: groupId)
            if activeGame == nil {
                firebaseService.rejoinLastRoomIfNeeded()
            }
        }
        .onDisappear {
            firebaseService.stopGroupRoomsListener()
        }
        .onReceive(firebaseService.$groupLiveRooms) { rooms in
            // Our own hosted game already shows as the game screen
            groupLiveRooms = rooms.filter { $0.hostId != firebaseService.currentUserId }
        }
        .onReceive(firebaseService.$activeRoom) { room in
            hasActiveRoom = room != nil
        }
        .onReceive(firebaseService.$isHost) { hostValue in
            isHost = hostValue
        }
    }
    
    private func liveRoomCard(_ room: GameRoom) -> some View {
        Button {
            joinError = nil
            joiningCode = room.roomCode
            firebaseService.joinRoom(code: room.roomCode) { result in
                joiningCode = nil
                if case .failure(let error) = result {
                    joinError = error.localizedDescription
                }
            }
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(hostName(room))'s game is live")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("\(room.players.count) players · \(room.currencySymbol ?? "")\(String(format: "%.0f", room.totalPot)) pot")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                if joiningCode == room.roomCode {
                    ProgressView().tint(AppTheme.accent)
                } else {
                    Text("Watch")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.accent)
                }
            }
            .padding()
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(0.4), lineWidth: 1))
        }
        .disabled(joiningCode != nil)
    }
    
    private func hostName(_ room: GameRoom) -> String {
        room.adminNames?[room.hostId] ?? firebaseService.activeGroup?.memberNames[room.hostId] ?? "Someone"
    }
}
