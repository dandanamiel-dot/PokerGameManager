# Poker Cash Game Manager

A beautiful, modern iOS app for managing poker cash games built with SwiftUI.

## Features

- 🎮 **Game Session Management**: Create and manage active poker games
- 💰 **Buy-In Tracking**: Track multiple buy-ins per player during games
- 🧮 **Smart Settlement**: Automatically calculates optimized "who owes whom" transactions
- 📊 **Game History**: View past games with statistics and analytics
- 👥 **Player Management**: Persistent player database across sessions
- 🌙 **Premium Dark Theme**: Eye-catching neon green accents on dark background
- 📱 **Custom Tab Bar**: Smooth, animated floating tab bar navigation

## Live games and co-admins

- A game started in a group is shared live automatically. Group members see it in their Live tab and can watch with one tap; anyone else can join with the 6-digit room code.
- The live room in Firestore (`rooms/{code}`) is the source of truth while a game runs. The host and co-admins apply actions (buy-in, cash-out, end game) in Firestore transactions via `RoomReducer`, so two admins tapping at once never overwrite each other. Actions that fail offline are retried when the connection is back.
- The host can make any viewer an admin (Players & Admins). Admins can run the game from their own phone if the host leaves; only the host can remove admins.
- The room logic lives in `Poker_manager/Poker_manager/LiveCore/` (plain Foundation, no Firebase).

## Tests

```bash
# Live-game logic (macOS, Xcode 26)
swift test

# Firestore security rules (needs Node 20+ and Java 21 for the emulator)
cd firestore-tests && npm install && npm test
```

GitHub Actions runs both, plus a simulator build of the app, on every pull request.

## Deploying Firestore rules

The app and `firestore.rules` ship together. After the App Store update is approved, deploy the rules:

```bash
firebase deploy --only firestore:rules --project <your-firebase-project-id>
```

The rules stay compatible with v1.0 clients (hosts can still share games, members can still join groups).

## Technology Stack

- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Local data persistence
- **MVVM Architecture**: Clean separation of concerns
- **SF Symbols**: Native iOS iconography

## Screenshots

[Add screenshots here]

## Installation

1. Clone the repository:
```bash
git clone [repository-url]
cd PokerGameManager
```

2. Open the Xcode project:
```bash
open Poker_manager/Poker_manager.xcodeproj
```

3. Build and run on a simulator or physical device (iOS 17.0+)

## Project Structure

```
Poker_manager/
├── Models/              # SwiftData models
│   ├── Player.swift
│   ├── GameSession.swift
│   ├── PlayerSession.swift
│   └── BuyIn.swift
├── ViewModels/          # Business logic
│   └── GameViewModel.swift
├── Views/              
│   ├── Components/      # Reusable UI components
│   ├── Home/           # Dashboard screen
│   ├── Game/           # Active game management
│   ├── History/        # Past games & statistics
│   └── Players/        # Player management
└── Theme/              # Design system
    └── AppTheme.swift
```

## Key Functionality

### Settlement Algorithm

The app implements an optimized debt settlement algorithm that minimizes the number of transactions needed. Instead of everyone paying the house, it calculates direct player-to-player transfers.

### Data Models

- **Player**: Persistent player profiles with avatars
- **GameSession**: Tracks game metadata and status
- **PlayerSession**: Links players to specific games with buy-ins and cash-outs
- **BuyIn**: Individual buy-in transactions

## Design

The app features a premium dark theme with:
- **Primary Colors**: Dark backgrounds (#0A0A0A, #1A1A1A)
- **Accent Color**: Neon green (#C8F542)
- **Typography**: SF Pro with rounded variants
- **Components**: Glassmorphic cards with subtle glow effects

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Author

Created with SwiftUI and ❤️

## License

[Add your license here]
