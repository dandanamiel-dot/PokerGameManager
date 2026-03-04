
import SwiftUI

struct LandingView: View {
    let firebaseService = FirebaseService.shared
    @State private var userGroups: [PokerGroup] = []
    
    @State private var showCreateGroup = false
    @State private var showJoinGroup = false
    @State private var navigateToQuickStart = false
    @State private var selectedGroup: PokerGroup?
    @State private var appearAnimation = false
    
    var body: some View {
        if navigateToQuickStart {
            MainTabView(group: nil) {
                withAnimation(.spring(response: 0.4)) {
                    navigateToQuickStart = false
                }
            }
        } else if let group = selectedGroup {
            MainTabView(group: group) {
                withAnimation(.spring(response: 0.4)) {
                    selectedGroup = nil
                    firebaseService.activeGroup = nil
                }
            }
        } else {
            landingContent
        }
    }
    
    // MARK: - Landing Content
    
    private var landingContent: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(AppTheme.cardBackground)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(AppTheme.accent.opacity(0.25), lineWidth: 1.5)
                                )
                            Text("♠")
                                .font(.system(size: 44, weight: .bold))
                                .foregroundStyle(AppTheme.accent)
                        }
                        
                        Text("All-In Poker Manager")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        
                        Text("Choose how you want to play")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(.top, 60)
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 20)
                    
                    // MARK: - Existing Groups
                    
                    if !userGroups.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("My Groups")
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                                .padding(.top, 10)
                            
                            ForEach(userGroups) { group in
                                GlowCard {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(AppTheme.accent.opacity(0.15))
                                                .frame(width: 44, height: 44)
                                            Image(systemName: "person.3.fill")
                                                .foregroundStyle(AppTheme.accent)
                                                .font(.system(size: 16))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(group.name)
                                                .foregroundStyle(.white)
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                            
                                            HStack(spacing: 8) {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "person.2.fill")
                                                        .font(.caption2)
                                                    Text("\(group.memberCount)")
                                                        .font(.caption)
                                                }
                                                .foregroundStyle(AppTheme.textSecondary)
                                                
                                                Text(group.currencySymbol)
                                                    .font(.caption.bold())
                                                    .foregroundStyle(AppTheme.accent.opacity(0.8))
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                                            .font(.caption.weight(.bold))
                                    }
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 16)
                                }
                                .onTapGesture {
                                    firebaseService.activeGroup = group
                                    withAnimation(.spring(response: 0.4)) {
                                        selectedGroup = group
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                    }
                    
                    // MARK: - Main Options
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Actions")
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                            .padding(.top, userGroups.isEmpty ? 10 : 20)
                            .opacity(appearAnimation ? 1 : 0)
                        
                        // Create Group
                        optionCard(
                            icon: "person.3.fill",
                            title: "Create Group",
                            subtitle: "Start a new poker group with friends.\nSet currency, invite players & track stats.",
                            accentColor: AppTheme.accent,
                            delay: 0.1
                        ) {
                            showCreateGroup = true
                        }
                        
                        // Join Group
                        optionCard(
                            icon: "person.badge.plus",
                            title: "Join Group",
                            subtitle: "Enter a group code to join your\nfriends' existing poker group.",
                            accentColor: Color(hex: "60A5FA"),
                            delay: 0.2
                        ) {
                            showJoinGroup = true
                        }
                        
                        // Quick Start
                        optionCard(
                            icon: "bolt.fill",
                            title: "Quick Start",
                            subtitle: "Jump right in! Play locally without\na group. Full features, no setup.",
                            accentColor: Color(hex: "FBBF24"),
                            delay: 0.3
                        ) {
                            withAnimation(.spring(response: 0.4)) {
                                navigateToQuickStart = true
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            firebaseService.loadUserGroups()
            withAnimation(.easeOut(duration: 0.6)) {
                appearAnimation = true
            }
        }
        .onReceive(firebaseService.$userGroups) { groups in
            userGroups = groups
        }
        .sheet(isPresented: $showCreateGroup) {
            CreateGroupView { group in
                firebaseService.activeGroup = group
                showCreateGroup = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.4)) {
                        selectedGroup = group
                    }
                }
            }
        }
        .sheet(isPresented: $showJoinGroup) {
            JoinGroupView { group in
                firebaseService.activeGroup = group
                showJoinGroup = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.4)) {
                        selectedGroup = group
                    }
                }
            }
        }
    }
    
    // MARK: - Option Card
    
    private func optionCard(
        icon: String,
        title: String,
        subtitle: String,
        accentColor: Color,
        delay: Double,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(accentColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(accentColor.opacity(0.6))
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(AppTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(accentColor.opacity(0.15), lineWidth: 1)
                    )
            )
            .shadow(color: accentColor.opacity(0.08), radius: 12, y: 6)
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 30)
        .animation(.easeOut(duration: 0.5).delay(delay), value: appearAnimation)
    }
}

#Preview {
    LandingView()
}
