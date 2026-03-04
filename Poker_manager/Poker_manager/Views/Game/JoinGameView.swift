
import SwiftUI

struct JoinGameView: View {
    let firebaseService = FirebaseService.shared
    @State private var codeDigits: [String] = ["", "", "", ""]
    @State private var isJoining = false
    @State private var errorMessage: String?
    @State private var joinedRoom: GameRoom?
    @FocusState private var focusedField: Int?
    
    @State private var activeRoom: GameRoom?
    @State private var isHost = false
    
    var body: some View {
        if let room = activeRoom, !isHost {
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
                    
                    Text("Enter the 4-digit code from the host")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                
                // Code Input
                HStack(spacing: 12) {
                    ForEach(0..<4, id: \.self) { index in
                        TextField("", text: $codeDigits[index])
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .frame(width: 64, height: 76)
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
                                // Limit to 1 digit
                                if newValue.count > 1 {
                                    codeDigits[index] = String(newValue.suffix(1))
                                }
                                // Auto-advance
                                if !newValue.isEmpty && index < 3 {
                                    focusedField = index + 1
                                }
                                // Auto-join when all 4 filled
                                if codeDigits.allSatisfy({ !$0.isEmpty }) {
                                    joinRoom()
                                }
                            }
                    }
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
                    .foregroundStyle(.white)
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
        guard codeComplete else { return }
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
                codeDigits = ["", "", "", ""]
                focusedField = 0
            }
        }
    }
}
