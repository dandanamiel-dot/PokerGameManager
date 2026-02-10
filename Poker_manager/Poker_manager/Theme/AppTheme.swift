
import SwiftUI

struct AppTheme {
    // MARK: - Colors
    static let background = Color(hex: "0A0E0F")
    static let cardBackground = Color(hex: "1A1E1F")
    static let accent = Color(hex: "C8F542") // Neon Green
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "9CA3AF")
    static let profit = Color(hex: "4ADE80") // Green-400
    static let loss = Color(hex: "F87171")   // Red-400
    
    // MARK: - Input Field Styles
    static let inputBackground = Color.white.opacity(0.1)
    static let inputBorderDefault = accent.opacity(0.3)
    static let inputBorderFocused = accent
    
    // MARK: - Spacing Tokens
    static let spacingS: CGFloat = 12
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    
    // MARK: - Touch Targets
    static let minTouchTarget: CGFloat = 44
    
    // MARK: - Gradients
    static let primaryGradient = LinearGradient(
        colors: [accent.opacity(0.8), accent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(hex: "0F2015"), // Subtle green tint at top
            background
        ],
        startPoint: .top,
        endPoint: .center
    )
}

// MARK: - Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers
struct GlowCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
            .shadow(color: AppTheme.accent.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func glowCard() -> some View {
        modifier(GlowCardModifier())
    }
    
    func appFont(_ size: CGFloat, weight: Font.Weight = .regular) -> some View {
        self.font(.system(size: size, weight: weight, design: .rounded))
    }
}
