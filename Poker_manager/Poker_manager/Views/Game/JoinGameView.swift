
import SwiftUI

struct JoinGameView: View {
    let firebaseService = FirebaseService.shared
    @State private var codeDigits: [String] = Array(repeating: "", count: RoomCode.length)
    @AppStorage(FirebaseService.liveDisplayNameKey) private var displayName = ""
    @State private var isJoining = false
    @State private var errorMessage: String?
    @State private var joinedRoom: GameRoom?
    @FocusState private var focusedField: Int?
    
    @State private var activeRoom: GameRoom?
    @State private var isHost = false
    
    var body: some View {
        if activeRoom != nil, !isHost {
            ViewerGameView()
        } else {
            joinInputView
        }
    }
    
    private var joinInputView: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Icon
                VStack(spacing: 12) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 50))
                        .foregroundStyle(AppTheme.accent)
                    
                    Text("Join a Game")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                    
                    Text("Enter the 6-digit code from the host")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                
                // Code Input
                HStack(spacing: 8) {
                    ForEach(0..<RoomCode.length, id: \.self) { index in
                        TextField("", text: $codeDigits[index])
                            .font(.system(size: 30, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .frame(width: 46, height: 64)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                focusedField == index ? AppTheme.accent : AppTheme.accent.opacity(0.3),
                                                lineWidth: focusedField == index ? 2 : 1
                                            )
                                    )
                            )
                            .focused($focusedField, equals: index)
                            .onChange(of: codeDigits[index]) { oldValue, newValue in
                                // A whole pasted code fills every box
                                if newValue.count > 1, let code = RoomCode.extract(from: newValue) {
                                    codeDigits = code.map { String($0) }
                                    focusedField = nil
                                    return
                                }
                                // Limit to 1 digit
                                if newValue.count > 1 {
                                    codeDigits[index] = String(newValue.suffix(1))
                                }
                                // Auto-advance
                                if !newValue.isEmpty && index < RoomCode.length - 1 {
                                    focusedField = index + 1
                                }
                                // Auto-join when all 4 filled
                                if codeDigits.allSatisfy({ !$0.isEmpty }) {
                                    joinRoom()
                                }
                            }
                    }
                }
                
                // Name shown to the host, so they know who to make admin
                TextField("", text: $displayName, prompt: Text("Your name").foregroundColor(.gray))
                    .font(.body)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.words)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.08))
                    )
                    .padding(.horizontal, 40)
                    .onChange(of: displayName) { _, newValue in
                        if newValue.count > 30 { displayName = String(newValue.prefix(30)) }
                    }
                
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
                    joinRoom()
                } label: {
                    HStack {
                        if isJoining {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "play.fill")
                            Text("Join Game")
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(codeComplete ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(codeComplete ? AppTheme.accent : Color.gray.opacity(0.3))
                    )
                }
                .disabled(!codeComplete || isJoining)
                .padding(.horizontal, 40)
                
                Spacer()
                Spacer()
            }
            .padding(24)
        }
        .onAppear {
            focusedField = 0
            if displayName.isEmpty, let uid = firebaseService.currentUserId,
               let groupName = firebaseService.activeGroup?.memberNames[uid] {
                displayName = groupName
            }
            activeRoom = firebaseService.activeRoom
            isHost = firebaseService.isHost
        }
        .onReceive(firebaseService.$activeRoom) { room in
            activeRoom = room
        }
        .onReceive(firebaseService.$isHost) { host in
            isHost = host
        }
    }
    
    private var codeComplete: Bool {
        codeDigits.allSatisfy { !$0.isEmpty }
    }
    
    private var roomCode: String {
        codeDigits.joined()
    }
    
    private func joinRoom() {
        guard codeComplete, !isJoining else { return }
        errorMessage = nil
        isJoining = true
        
        firebaseService.joinRoom(code: roomCode) { result in
            isJoining = false
            switch result {
            case .success(let room):
                joinedRoom = room
            case .failure(let error):
                errorMessage = error.localizedDescription
                // Clear inputs for retry
                codeDigits = Array(repeating: "", count: RoomCode.length)
                focusedField = 0
            }
        }
    }
}
