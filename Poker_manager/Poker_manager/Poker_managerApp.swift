//
//  Poker_managerApp.swift
//  Poker_manager
//
//  Created by Dan Amiel on 10/02/2026.
//

import SwiftUI
import SwiftData

@main
struct Poker_managerApp: App {
    var body: some Scene {
        WindowGroup {
            WelcomeView()
        }
        .modelContainer(for: [
            Player.self,
            GameSession.self,
            PlayerSession.self,
            BuyIn.self
        ])
    }
}
