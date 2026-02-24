import SwiftUI
import SwiftData
import CoreImage.CIFilterBuiltins

struct GroupDashboardView: View {
    let group: PokerGroup
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var firebaseService = FirebaseService.shared
    @Query private var allGames: [GameSession]
    
    @State private var showNewGameSheet = false
    @State private var showSettings = false
    @State private var selectedGame: GameSession?
    @State private var codeCopied = false
    @State private var showQRCode = false
    
    init(group: PokerGroup) {
        self.group = group
        let gId = group.groupId
        _allGames = Query(
            filter: #Predicate<GameSession> { $0.groupId == gId },
            sort: \GameSession.date,
            order: .reverse
        )
    }
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Members Section
                        membersSection
                        
                        // Game Actions
                        if firebaseService.activeGroup?.groupId == group.groupId {
                            AccentButton(title: "Start New Game", icon: "plus") {
                                showNewGameSheet = true
                            }
                        }
                        
                        // Recent Games
                        recentGamesSection
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showNewGameSheet) {
            NewGameSheet(groupId: group.groupId)
        }
        .sheet(isPresented: $showSettings) {
            GroupSettingsSheet(group: group)
        }
        .fullScreenCover(item: $selectedGame) { game in
            GameSessionView(session: game, modelContext: modelContext)
        }
        .sheet(isPresented: $showQRCode) {
            QRCodeSheet(code: currentGroup.groupId)
        }
        .onAppear {
            firebaseService.listenToGroup(groupId: group.groupId)
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 0) {
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
            
            VStack(spacing: 2) {
                Text(currentGroup.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text("\(currentGroup.memberCount) members")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
        }
        .padding()
        
        // Compact Code/QR/Copy Row
        HStack(spacing: 16) {
            Text("Code:")
                .foregroundStyle(.gray)
                .font(.subheadline)
            
            Text(currentGroup.groupId)
                .font(.system(.subheadline, design: .monospaced, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            
            Button {
                showQRCode = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "qrcode")
                    Text("QR Code")
                }
                .font(.subheadline.bold())
                .foregroundStyle(.green)
            }
            
            Button {
                UIPasteboard.general.string = currentGroup.groupId
                withAnimation { codeCopied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { codeCopied = false }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: codeCopied ? "checkmark.doc.fill" : "doc.on.doc")
                    Text(codeCopied ? "Copied" : "Copy")
                }
                .font(.subheadline.bold())
                .foregroundStyle(.blue)
            }
            }
        }
        .padding(.bottom, 16)
    }
    
    // Removed explicit large `groupIdCard` in favor of inline compact header above.
    
    // MARK: - Members
    
    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Members")
                .font(.title3.bold())
                .foregroundStyle(.white)
            
            let memberNames = Array(currentGroup.memberNames.values).sorted()
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(memberNames, id: \.self) { name in
                    HStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundStyle(AppTheme.accent.opacity(0.7))
                        Text(name)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Recent Games
    
    private var recentGamesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Games")
                .font(.title3.bold())
                .foregroundStyle(.white)
            
            if allGames.isEmpty {
                VStack(spacing: 8) {
                    Text("No games yet")
                        .foregroundStyle(.gray)
                    Text("Start a new game to get going!")
                        .font(.caption)
                        .foregroundStyle(.gray.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(allGames.prefix(5)) { game in
                    GlowCard {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(game.date.formatted(date: .abbreviated, time: .shortened))
                                    .foregroundStyle(.white)
                                    .fontWeight(.medium)
                                Text("\(game.playerCount) Players")
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .font(.caption)
                            }
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Text("\(currentGroup.currencySymbol)\(game.totalPot, specifier: "%.0f")")
                                    .foregroundStyle(AppTheme.accent)
                                    .fontWeight(.bold)
                                
                                if game.status == .active {
                                    Text("LIVE")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.green)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.2))
                                        .clipShape(Capsule())
                                } else if game.status == .completed {
                                    Text("ENDED")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.red)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.red.opacity(0.2))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding()
                    }
                    .onTapGesture {
                        selectedGame = game
                    }
                }
            }
        }
    }
    
    // MARK: - Helper
    
    private var currentGroup: PokerGroup {
        firebaseService.activeGroup ?? group
    }
}

// MARK: - QR Code Sheet

struct QRCodeSheet: View {
    let code: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 32) {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.gray)
                    }
                }
                .padding()
                
                Spacer()
                
                VStack(spacing: 16) {
                    Text("Scan to Join Group")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    
                    Text("Point your camera at this QR code\nto instantly join the poker group.")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        
                    Image(uiImage: generateQRCode(from: code))
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(16)
                        .padding(.top, 24)
                        
                    Text(code)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundStyle(AppTheme.accent)
                        .kerning(4)
                        .padding(.top, 16)
                }
                
                Spacer()
                Spacer()
            }
        }
    }
    
    // Uses CoreImage built-in QR Code Generator for crisp rendering without third-party frameworks.
    private func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}
