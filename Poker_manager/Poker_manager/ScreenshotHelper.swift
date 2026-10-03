//
//  ScreenshotHelper.swift
//  Automated screenshot capture for App Store
//
//  HOW TO USE:
//  1. Add this to a UI Test target (or create one if needed)
//  2. Run the UI tests on iPhone 16 Pro Max simulator
//  3. Screenshots automatically save to your Mac
//

#if canImport(XCTest)
import XCTest

/*
 TO CREATE UI TEST TARGET:
 1. File > New > Target
 2. Choose "UI Testing Bundle"
 3. Name it "PokerManagerUITests"
 4. Add this file to that target
 */

final class AppStoreScreenshotTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        
        // Launch arguments to load preview data
        app.launchArguments = ["UI-Testing", "Screenshot-Mode"]
        
        // Set screenshot mode
        setupSnapshot(app)
    }
    
    // MARK: - Screenshot 1: Home Screen
    func testScreenshot1_HomeScreen() throws {
        app.launch()
        
        // Wait for home screen to load
        sleep(2)
        
        // Take screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "01-HomeScreen"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        print("📸 Screenshot saved: 01-HomeScreen")
    }
    
    // MARK: - Screenshot 2: Active Game Session
    func testScreenshot2_ActiveGame() throws {
        app.launch()
        sleep(1)
        
        // Tap on "Start New Game" or existing game
        // Adjust these selectors based on your actual UI
        let startGameButton = app.buttons["Start New Game"]
        if startGameButton.exists {
            startGameButton.tap()
            sleep(1)
        }
        
        sleep(2)
        
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "02-ActiveGame"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        print("📸 Screenshot saved: 02-ActiveGame")
    }
    
    // MARK: - Screenshot 3: History View
    func testScreenshot3_History() throws {
        app.launch()
        sleep(1)
        
        // Navigate to History tab (swipe or tap)
        // Adjust based on your tab navigation
        app.swipeLeft()
        app.swipeLeft()
        sleep(1)
        
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "03-History"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        print("📸 Screenshot saved: 03-History")
    }
    
    // Helper to setup for screenshots
    func setupSnapshot(_ app: XCUIApplication) {
        // Configure for best screenshot quality
        // Dark mode is already your default
    }
}

// MARK: - Manual Screenshot Instructions

/*
 ═══════════════════════════════════════════════════════════
 EASIEST METHOD - MANUAL SCREENSHOTS (5 MINUTES)
 ═══════════════════════════════════════════════════════════
 
 1. OPEN SIMULATOR
    - In Xcode: Product > Destination > iPhone 16 Pro Max
    - Press ⌘R to run your app
 
 2. TAKE SCREENSHOTS
    - Navigate to each screen you want to capture
    - Press ⌘S (Command + S) in the Simulator
    - Or: Device > Trigger Screenshot
 
 3. FIND YOUR SCREENSHOTS
    📁 They save to: ~/Desktop/
    📄 Named: "Simulator Screen Shot - iPhone 16 Pro Max - [date].png"
 
 4. RECOMMENDED SCREENSHOTS FOR POKER APP:
 
    Screenshot 1: HOME SCREEN
    - Shows your main dashboard
    - Group overview (if you have one)
    - "Start New Game" button visible
    
    Screenshot 2: ACTIVE GAME
    - Current pot display
    - Timeline chart showing
    - Player list with buy-ins
    
    Screenshot 3: PLAYER DETAILS
    - Individual player stats
    - Buy-in history
    - Cash-out information
    
    Screenshot 4: GAME HISTORY
    - List of past games
    - Shows dates and amounts
    - Mix of completed games
    
    Screenshot 5: SETTLEMENT VIEW
    - End game results
    - Who won/lost
    - Transaction list
 
 5. UPLOAD TO APP STORE CONNECT
    - Go to: https://appstoreconnect.apple.com
    - Your App > App Store tab
    - Scroll to "iPhone 6.9 Display"
    - Drag & drop your screenshots
    - They must be exactly 1320 x 2868 pixels
 
 ═══════════════════════════════════════════════════════════
 TIPS FOR GREAT SCREENSHOTS
 ═══════════════════════════════════════════════════════════
 
 ✅ DO:
    - Use clean, realistic data
    - Show your app's best features
    - Use consistent player names
    - Show variety (different screens)
    - Ensure good contrast and readability
 
 ❌ DON'T:
    - Show real money gambling
    - Use real people's names/photos
    - Show empty states (unless intentional)
    - Include offensive content
    - Show bugs or errors
 
 ═══════════════════════════════════════════════════════════
 REQUIRED DIMENSIONS
 ═══════════════════════════════════════════════════════════
 
 iPhone 6.9" Display (iPhone 16 Pro Max) - REQUIRED
    Portrait: 1320 x 2868 pixels
 
 iPhone 6.7" Display (iPhone 15 Pro Max) - Optional but recommended
    Portrait: 1290 x 2796 pixels
 
 iPhone 6.5" Display (older) - Optional
    Portrait: 1284 x 2778 pixels
 
 You need AT LEAST 3 screenshots, MAX 10 screenshots
 
 ═══════════════════════════════════════════════════════════
 */

#endif
