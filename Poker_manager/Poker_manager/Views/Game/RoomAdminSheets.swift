import SwiftUI

// Sheets a co-admin uses to run a live game straight from the shared room,
// plus the host/admin list. The host's own phone uses the regular game
// screen, whose changes reach the room through GameViewModel.

// MARK: - Buy-in

struct RoomBuyInSheet: View {
    let room: GameRoom
    let currencySymbol: String

    @Environment(\.dismiss) private var dismiss
    private let firebaseService = FirebaseService.shared

    /// A room player's id, or "new:<name>" for a group member not in the game yet
    @State private var selectedKey: String?
    @State private var newPlayerName = ""
    @State private var amount = ""
    @State private var isSaving = false
    @FocusState private var isInputFocused: Bool

    private struct Choice: Identifiable {
        let id: String
        let name: String
        let avatar: String
    }

    /// Players already in the game, then group members who aren't yet.
    private var choices: [Choice] {
        var list = room.players.map { Choice(id: $0.id, name: $0.name, avatar: $0.avatar) }
        let names = Set(room.players.map { $0.name.lowercased() })
        let members = firebaseService.activeGroup.map { Array($0.memberNames.values) } ?? []
        for name in members.sorted() where !names.contains(name.lowercased()) {
            list.append(Choice(id: "new:\(name)", name: name, avatar: "person.crop.circle.fill"))
        }
        return list
    }

    private var enteredName: String {
        newPlayerName.trimmingCharacters(in: .whitespaces)
    }

    private var canConfirm: Bool {
        guard let value = Double(amount), value > 0, !isSaving else { return false }
        return selectedKey != nil || !enteredName.isEmpty
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Text("Add Buy-In")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .padding(.top)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(choices) { choice in
                            Button {
                                selectedKey = choice.id
                                newPlayerName = ""
                            } label: {
                                VStack {
                                    Image(systemName: choice.avatar)
                                        .font(.largeTitle)
                                        .foregroundStyle(selectedKey == choice.id ? AppTheme.accent : .gray)
                                    Text(choice.name)
                                        .font(.caption)
                                        .foregroundStyle(.white)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedKey == choice.id ? AppTheme.accent.opacity(0.1) : AppTheme.cardBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedKey == choice.id ? AppTheme.accent : Color.clear, lineWidth: 2)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)

                    TextField("", text: $newPlayerName, prompt: Text("Or add a new player").foregroundColor(.gray))
                        .foregroundStyle(.white)
                        .textInputAutocapitalization(.words)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.inputBackground))
                        .padding(.horizontal)
                        .onChange(of: newPlayerName) { _, newValue in
                            if !newValue.isEmpty { selectedKey = nil }
                        }

                    HStack {
                        Text(currencySymbol)
                            .foregroundStyle(AppTheme.accent)
                            .font(.title)
                        TextField("0", text: $amount)
                            .keyboardType(.numberPad)
                            .foregroundStyle(.white)
                            .font(.system(size: 40, weight: .bold))
                            .multilineTextAlignment(.center)
                            .focused($isInputFocused)
                    }
                    .padding()

                    AccentButton(title: isSaving ? "Saving..." : "Confirm Buy-In") {
                        confirm()
                    }
                    .disabled(!canConfirm)
                    .opacity(canConfirm ? 1 : 0.5)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            if amount.isEmpty, let defaultBuyIn = firebaseService.activeGroup?.defaultBuyIn {
                amount = String(format: "%.0f", defaultBuyIn)
            }
        }
    }

    private func confirm() {
        guard let value = Double(amount), value > 0 else { return }

        let playerId: String
        let name: String
        let avatar: String
        if let key = selectedKey, let choice = choices.first(where: { $0.id == key }), !key.hasPrefix("new:") {
            playerId = choice.id
            name = choice.name
            avatar = choice.avatar
        } else {
            let chosenName = selectedKey.map { String($0.dropFirst("new:".count)) } ?? enteredName
            guard !chosenName.isEmpty else { return }
            // Reuse the id if someone with that name is already in the game
            playerId = room.players.first { $0.name.caseInsensitiveCompare(chosenName) == .orderedSame }?.id ?? UUID().uuidString
            name = chosenName
            avatar = "person.crop.circle.fill"
        }

        isSaving = true
        firebaseService.perform(.buyIn(eventId: UUID().uuidString, playerId: playerId, playerName: name,
                                       avatar: avatar, amount: value)) { _ in
            isSaving = false
        }
        // Queued and retried if offline, so the sheet can close right away
        dismiss()
    }
}

// MARK: - Cash out

struct RoomCashOutSheet: View {
    let room: GameRoom
    let currencySymbol: String

    @Environment(\.dismiss) private var dismiss
    private let firebaseService = FirebaseService.shared
    @State private var selectedId: String?
    @State private var amount = ""

    private var stillPlaying: [PlayerSnapshot] {
        room.players.filter { !$0.hasCashedOut }
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Text("Cash Out")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .padding(.top)

                    if stillPlaying.isEmpty {
                        Text("Everyone has cashed out.")
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    ForEach(stillPlaying) { player in
                        Button {
                            selectedId = player.id
                        } label: {
                            HStack {
                                Image(systemName: player.avatar)
                                    .foregroundStyle(selectedId == player.id ? AppTheme.accent : .gray)
                                Text(player.name)
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("In: \(currencySymbol)\(String(format: "%.0f", player.totalBuyIn))")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedId == player.id ? AppTheme.accent.opacity(0.1) : AppTheme.cardBackground)
                            )
                        }
                    }
                    .padding(.horizontal)

                    HStack {
                        Text(currencySymbol)
                            .foregroundStyle(AppTheme.accent)
                            .font(.title)
                        TextField("0", text: $amount)
                            .keyboardType(.numberPad)
                            .foregroundStyle(.white)
                            .font(.system(size: 40, weight: .bold))
                            .multilineTextAlignment(.center)
                    }
                    .padding()

                    AccentButton(title: "Confirm Cash Out") {
                        if let id = selectedId, let value = Double(amount), value >= 0 {
                            firebaseService.perform(.cashOut(playerId: id, amount: value))
                            dismiss()
                        }
                    }
                    .disabled(selectedId == nil || Double(amount) == nil)
                    .opacity(selectedId == nil || Double(amount) == nil ? 0.5 : 1)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
        }
    }
}

// MARK: - End game

struct RoomEndGameSheet: View {
    let room: GameRoom
    let currencySymbol: String

    @Environment(\.dismiss) private var dismiss
    private let firebaseService = FirebaseService.shared
    /// Final chip counts, keyed by player id
    @State private var finalCounts: [String: String] = [:]

    private var stillPlaying: [PlayerSnapshot] {
        room.players.filter { !$0.hasCashedOut }
    }

    private var finalCashOuts: [String: Double] {
        var result: [String: Double] = [:]
        for player in stillPlaying {
            if let value = Double(finalCounts[player.id] ?? "") {
                result[player.id] = value
            }
        }
        return result
    }

    private var tableTotal: Double {
        room.totalPot - finalCashOuts.values.reduce(0, +)
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Text("End Game")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .padding(.top)

                    Text("Enter each player's final chips. Anyone left blank counts as 0.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    ForEach(stillPlaying) { player in
                        HStack {
                            Text(player.name)
                                .foregroundStyle(.white)
                            Spacer()
                            Text(currencySymbol)
                                .foregroundStyle(AppTheme.accent)
                            TextField("0", text: Binding(
                                get: { finalCounts[player.id] ?? "" },
                                set: { finalCounts[player.id] = $0 }
                            ))
                            .keyboardType(.numberPad)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.cardBackground))
                    }
                    .padding(.horizontal)

                    Text(abs(tableTotal) < 0.01
                         ? "Chips match the pot"
                         : "\(currencySymbol)\(String(format: "%.0f", abs(tableTotal))) \(tableTotal > 0 ? "still unaccounted for" : "more than the pot")")
                        .font(.caption)
                        .foregroundStyle(abs(tableTotal) < 0.01 ? .green : .orange)

                    AccentButton(title: "End Game & Settle") {
                        firebaseService.perform(.endGame(finalCashOuts: finalCashOuts))
                        dismiss()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
        }
    }
}

// MARK: - Players & admins

struct RoomMembersSheet: View {
    @Environment(\.dismiss) private var dismiss
    private let firebaseService = FirebaseService.shared
    @State private var room: GameRoom?
    @State private var viewers: [ViewerPresence] = []
    @State private var busyUid: String?

    private var myUid: String? { firebaseService.currentUserId }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                List {
                    if let room {
                        Section {
                            ForEach(room.allAdminIds, id: \.self) { uid in
                                memberRow(uid: uid, name: name(for: uid, in: room), room: room)
                                    .listRowBackground(AppTheme.cardBackground)
                            }
                        } header: {
                            Text("Admins")
                        } footer: {
                            Text("Admins can add buy-ins, cash players out and end the game, so the game keeps going if the host leaves.")
                        }

                        Section {
                            let watchers = viewers.filter { !room.isAdmin($0.uid) && $0.isActive(at: Date()) }
                            if watchers.isEmpty {
                                Text("No one else is watching yet. Share the room code, or group members can open the Live tab.")
                                    .font(.footnote)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .listRowBackground(AppTheme.cardBackground)
                            }
                            ForEach(watchers) { viewer in
                                memberRow(uid: viewer.uid, name: viewer.name, room: room)
                                    .listRowBackground(AppTheme.cardBackground)
                            }
                        } header: {
                            Text("Watching now")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .environment(\.colorScheme, .dark)
            }
            .navigationTitle("Players & Admins")
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            room = firebaseService.activeRoom
            viewers = firebaseService.viewers
        }
        .onReceive(firebaseService.$activeRoom) { room = $0 }
        .onReceive(firebaseService.$viewers) { viewers = $0 }
    }

    private func name(for uid: String, in room: GameRoom) -> String {
        room.adminNames?[uid]
            ?? viewers.first(where: { $0.uid == uid })?.name
            ?? firebaseService.activeGroup?.memberNames[uid]
            ?? "Player"
    }

    @ViewBuilder
    private func memberRow(uid: String, name: String, room: GameRoom) -> some View {
        HStack {
            Image(systemName: uid == room.hostId ? "crown.fill" : (room.isAdmin(uid) ? "star.fill" : "person.fill"))
                .foregroundStyle(room.isAdmin(uid) ? AppTheme.accent : .gray)
            Text(uid == myUid ? "\(name) (you)" : name)
            Spacer()

            if busyUid == uid {
                ProgressView()
            } else if uid == room.hostId {
                Text("Host")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            } else if room.isAdmin(uid) {
                if room.hostId == myUid {
                    Button("Remove admin", role: .destructive) {
                        busyUid = uid
                        firebaseService.removeAdmin(uid: uid) { _ in busyUid = nil }
                    }
                    .font(.caption)
                } else {
                    Text("Admin")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            } else if room.isAdmin(myUid) {
                Button("Make admin") {
                    busyUid = uid
                    firebaseService.makeAdmin(ViewerPresence(uid: uid, name: name, lastSeen: nil)) { _ in busyUid = nil }
                }
                .font(.caption.bold())
                .tint(AppTheme.accent)
            }
        }
    }
}
