// swift-tools-version:6.0
// Unit tests for the app's live-game logic (Poker_manager/Poker_manager/LiveCore).
// The app target compiles those same files; this package only exists so they
// can be tested with `swift test` without a simulator.
import PackageDescription

let package = Package(
    name: "PokerLiveCore",
    platforms: [.macOS(.v14), .iOS(.v17)],
    targets: [
        .target(
            name: "PokerLiveCore",
            path: "Poker_manager/Poker_manager/LiveCore"
        ),
        .testTarget(
            name: "PokerLiveCoreTests",
            dependencies: ["PokerLiveCore"],
            path: "Tests/PokerLiveCoreTests"
        ),
    ],
    swiftLanguageModes: [.v5]
)
