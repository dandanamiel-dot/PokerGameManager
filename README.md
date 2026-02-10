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
