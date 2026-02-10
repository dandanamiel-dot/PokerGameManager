
import SwiftUI
import SwiftData

struct PlayersView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Player.name) private var players: [Player]
    @State private var showAddPlayer = false
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Players")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        showAddPlayer = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundStyle(AppTheme.accent)
                            .padding(12)
                            .background(AppTheme.cardBackground)
                            .clipShape(Circle())
                    }
                }
                .padding()
                .padding(.top, 40)
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(players) { player in
                            PlayerRow(
                                name: player.name,
                                detail: "Joined \(player.createdAt.formatted(date: .abbreviated, time: .omitted))",
                                amount: nil, 
                                isPositive: true
                            )
                        }
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showAddPlayer) {
            AddPlayerView()
        }
    }
}
