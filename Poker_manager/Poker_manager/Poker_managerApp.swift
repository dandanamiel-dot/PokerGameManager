//
//  Poker_managerApp.swift
//  Poker_manager
//
//  Created by Dan Amiel on 10/02/2026.
//

import SwiftUI
import SwiftData
import FirebaseCore

@main
struct Poker_managerApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            WelcomeView()
                .fullScreenCover(isPresented: .init(
                    get: { !hasSeenOnboarding },
                    set: { if !$0 { hasSeenOnboarding = true } }
                )) {
                    OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                }
        }
        .modelContainer(for: [
            Player.self,
            GameSession.self,
            PlayerSession.self,
            BuyIn.self
        ])
    }
}
