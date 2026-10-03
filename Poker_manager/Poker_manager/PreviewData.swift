//
//  PreviewData.swift
//  Poker Manager
//
//  Preview data for App Store screenshots
//

import Foundation
import SwiftUI

/// Sample data for creating beautiful App Store screenshots
struct PreviewData {
    
    // MARK: - Sample Players
    static let players = [
        "Sarah",
        "Mike",
        "David",
        "Emma",
        "James",
        "Lisa",
        "Tom",
        "Anna"
    ]
    
    // MARK: - Sample Poker Group
    static func createSampleGroup() -> PokerGroup {
        var group = PokerGroup(
            groupId: "POKER23",
            name: "Friday Night Poker",
            createdBy: "user123",
            currency: .USD
        )
        group.memberNames = [
            "user1": "Sarah",
            "user2": "Mike",
            "user3": "David",
            "user4": "Emma"
        ]
        return group
    }
    
    // MARK: - Sample Active Game Session
    static func createActiveGameSession(groupId: String = "local") -> GameSession {
        let session = GameSession(groupId: groupId)
        session.date = Date()
        session.status = .active
        
        // Add some realistic buy-ins
        let amounts: [Double] = [200, 200, 300, 200, 150, 200]
        
        for (index, amount) in amounts.enumerated() {
            if index < players.count {
                let buyIn = BuyIn(amount: amount)
                buyIn.timestamp = Date().addingTimeInterval(-Double(3600 - index * 300))
                // Note: In real app, you'd associate with actual Player objects
            }
        }
        
        return session
    }
    
    // MARK: - Sample Completed Game Session
    static func createCompletedGameSession(groupId: String = "local") -> GameSession {
        let session = GameSession(groupId: groupId)
        session.date = Date().addingTimeInterval(-86400) // Yesterday
        session.status = .completed
        session.endedAt = Date().addingTimeInterval(-82800)
        
        return session
    }
    
    // MARK: - Multiple Sample Games for History
    static func createSampleGameHistory(groupId: String = "local") -> [GameSession] {
        var games: [GameSession] = []
        
        // Last 10 games
        for i in 0..<10 {
            let session = GameSession(groupId: groupId)
            session.date = Date().addingTimeInterval(-Double(i * 86400)) // Days ago
            session.status = (i == 0) ? .active : .completed
            if session.status == .completed {
                session.endedAt = session.date.addingTimeInterval(14400) // 4 hours later
            }
            games.append(session)
        }
        
        return games
    }
}

// MARK: - Screenshot Helper Extension

extension View {
    /// Modifier to prepare views for App Store screenshots
    /// Hides sensitive info and makes UI look polished
    func screenshotReady() -> some View {
        self
            .preferredColorScheme(.dark) // Your app uses dark theme
    }
}

// MARK: - Instructions for Taking Screenshots

/*
 HOW TO TAKE APP STORE SCREENSHOTS:
 
 1. PREPARE YOUR SIMULATOR
    - Open Xcode
    - Select Product > Destination > iPhone 16 Pro Max (6.9")
    - Run your app (⌘R)
 
 2. LOAD PREVIEW DATA
    - Navigate to the screens you want to capture
    - Make sure you have realistic data showing
 
 3. TAKE SCREENSHOTS
    Method A - Manual:
    - Press ⌘S in the Simulator
    - Screenshots save to Desktop
    
    Method B - Using Xcode (Recommended):
    - Window > Devices and Simulators
    - Select your simulator
    - Click "Take Screenshot" button
    - Saves to Desktop
 
 4. REQUIRED SCREENSHOTS FOR POKER APP
    ✓ Home screen with groups
    ✓ Active game session with pot
    ✓ Player list with buy-ins
    ✓ Game history view
    ✓ Settlement/results screen
 
 5. SCREENSHOT SIZES NEEDED
    - iPhone 6.9" (iPhone 16 Pro Max): 1320 x 2868 px
    - iPhone 6.7" (iPhone 15 Plus): 1290 x 2796 px
    
 6. WHERE SCREENSHOTS SAVE
    - Desktop folder by default
    - Look for files named "Screenshot YYYY-MM-DD at HH.MM.SS.png"
 
 7. UPLOAD TO APP STORE CONNECT
    - Go to appstoreconnect.apple.com
    - Select your app
    - Go to "App Store" tab
    - Scroll to "App Preview and Screenshots"
    - Drag and drop your images
    
 IMPORTANT FOR POKER APPS:
    ⚠️ Don't show real money gambling
    ✓ Emphasize "chip tracking" and "game organization"
    ✓ Use generic player names (no real people)
    ✓ Show social/friendly game aspects
 */
