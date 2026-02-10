import SwiftUI
import SwiftData

struct EditGameSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var game: GameSession
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                Form {
                    Section(header: Text("Game Details").foregroundStyle(AppTheme.accent)) {
                        DatePicker("Date", selection: $game.date)
                            .foregroundStyle(.white)
                            .listRowBackground(AppTheme.cardBackground)
                        
                        TextField("Notes", text: Binding(
                            get: { game.notes ?? "" },
                            set: { game.notes = $0.isEmpty ? nil : $0 }
                        ))
                        .foregroundStyle(.white)
                        .listRowBackground(AppTheme.cardBackground)
                    }
                    
                    if game.status == .completed {
                        Section(header: Text("Status").foregroundStyle(AppTheme.accent)) {
                            HStack {
                                Text("Status")
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("Completed")
                                    .foregroundStyle(AppTheme.profit)
                                    .fontWeight(.bold)
                            }
                            .listRowBackground(AppTheme.cardBackground)
                            
                            Button("Re-open Game") {
                                game.status = .active
                                game.endedAt = nil
                                dismiss()
                            }
                            .foregroundStyle(AppTheme.accent)
                            .listRowBackground(AppTheme.cardBackground)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.accent)
                }
            }
        }
    }
}
