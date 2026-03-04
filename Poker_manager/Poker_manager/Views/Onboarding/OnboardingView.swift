
import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "suit.spade.fill",
            title: "Welcome to\nAll-In Poker Manager",
            description: "Track every buy-in, cash-out, and settlement. The ultimate companion for your home poker nights.",
            accentColor: AppTheme.accent
        ),
        OnboardingPage(
            icon: "person.3.fill",
            title: "Groups vs.\nQuick Start",
            description: "**Quick Start** — solo or local play. No account needed.\n\n**Groups** — invite friends with a shared code to track games, stats, and settlements together.",
            accentColor: Color.blue
        ),
        OnboardingPage(
            icon: "chart.bar.xaxis",
            title: "Track Every Hand",
            description: "Live pot display, buy-in history, automatic settlement calculations, and a shareable breakdown at the end of every game.",
            accentColor: AppTheme.profit
        )
    ]

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Pager
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        pageView(page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? AppTheme.accent : Color.white.opacity(0.3))
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // CTA Button
                AccentButton(
                    title: currentPage == pages.count - 1 ? "Let's Go! 🃏" : "Next",
                    icon: currentPage == pages.count - 1 ? nil : "arrow.right"
                ) {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                        if currentPage < pages.count - 1 {
                            currentPage += 1
                        } else {
                            hasSeenOnboarding = true
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
        // Allow skipping after page 0
        .overlay(alignment: .topTrailing) {
            if currentPage < pages.count - 1 {
                Button("Skip") {
                    hasSeenOnboarding = true
                }
                .foregroundStyle(AppTheme.textSecondary)
                .font(.subheadline)
                .padding(.top, 56)
                .padding(.trailing, 24)
            }
        }
    }

    @ViewBuilder
    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated icon badge
            ZStack {
                Circle()
                    .fill(page.accentColor.opacity(0.12))
                    .frame(width: 140, height: 140)
                Circle()
                    .stroke(page.accentColor.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 140, height: 140)
                Image(systemName: page.icon)
                    .font(.system(size: 60))
                    .foregroundStyle(page.accentColor)
            }
            .shadow(color: page.accentColor.opacity(0.25), radius: 30)

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)

                Text((try? AttributedString(markdown: page.description)) ?? AttributedString(page.description))
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
}
