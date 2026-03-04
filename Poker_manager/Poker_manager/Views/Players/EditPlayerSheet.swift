
import SwiftUI
import SwiftData

struct EditPlayerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let player: Player
    @State private var playerName: String = ""
    @State private var saveErrorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Edit Player")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.top)
                    
                    GlowCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Player Name")
                                .foregroundStyle(AppTheme.textSecondary)
                                .font(.caption)
                            
                            TextField("Enter name", text: $playerName)
                                .foregroundStyle(.white)
                                .font(.title3)
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(12)
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    AccentButton(title: "Save Changes") {
                        saveChanges()
                    }
                    .disabled(playerName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(playerName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                }
                .padding()
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
        .onAppear {
            playerName = player.name
        }
        .alert("Save Error", isPresented: .init(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveErrorMessage ?? "")
        }
    }
    
    private func saveChanges() {
        player.name = playerName.trimmingCharacters(in: .whitespaces)
        do {
            try modelContext.save()
        } catch {
            print("⚠️ SwiftData save error: \(error)")
            saveErrorMessage = "Failed to save player: \(error.localizedDescription)"
            return
        }
        dismiss()
    }
}
