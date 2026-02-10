
import SwiftUI

struct FloatingTabBar: View {
    @Binding var selectedTab: Int
    
    let tabs = [
        (icon: "house.fill", title: "Home"),
        (icon: "gamecontroller.fill", title: "Game"),
        (icon: "clock.fill", title: "History"),
        (icon: "person.2.fill", title: "Players")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[index].icon)
                            .font(.system(size: 20))
                        
                        if selectedTab == index {
                            Text(tabs[index].title)
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                    }
                    .foregroundColor(selectedTab == index ? .black : AppTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        ZStack {
                            if selectedTab == index {
                                Capsule()
                                    .fill(AppTheme.accent)
                                    .matchedGeometryEffect(id: "TabBackground", in: namespace)
                            }
                        }
                    )
                }
            }
        }
        .padding(6)
        .background(Color.black.opacity(0.8))
        .clipShape(Capsule())
        .shadow(color: AppTheme.accent.opacity(0.1), radius: 10, y: 5)
        .padding(.horizontal)
    }
    
    @Namespace private var namespace
}

#Preview {
    ZStack {
        Color.gray
        VStack {
            Spacer()
            FloatingTabBar(selectedTab: .constant(0))
        }
    }
}
