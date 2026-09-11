import SwiftUI

enum ShellTab: Int, CaseIterable {
    case feed, explore, food, profile

    var title: String {
        switch self {
        case .feed: "Akış"
        case .explore: "Keşfet"
        case .food: "Lezzet"
        case .profile: "Profil"
        }
    }

    var icon: String {
        switch self {
        case .feed: "house.fill"
        case .explore: "map.fill"
        case .food: "fork.knife"
        case .profile: "person.fill"
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var auth: AuthStore
    @State private var tab: ShellTab = .feed
    @State private var showAuth = false

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                AppHeaderView(
                    showGreeting: tab == .feed,
                    userName: auth.user?.displayName,
                    onProfileTap: { tab = .profile }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                TabContent(tab: tab)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 88)
            }

            FloatingTabBar(
                selection: $tab,
                onCreateTap: {
                    if auth.isLoggedIn {
                        // Faz 2: etkinlik oluştur
                    } else {
                        showAuth = true
                    }
                }
            )
        }
        .sheet(isPresented: $showAuth) {
            AuthFlowView()
        }
    }
}

private struct TabContent: View {
    let tab: ShellTab

    var body: some View {
        switch tab {
        case .feed:
            FeedView()
        case .explore:
            PlaceholderTabView(title: "Keşfet", subtitle: "Harita ve rota — Faz 2")
        case .food:
            PlaceholderTabView(title: "Lezzet", subtitle: "Yeme-içme listesi — Faz 3")
        case .profile:
            ProfileView()
        }
    }
}

struct PlaceholderTabView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(AppColors.ink)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppColors.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AppHeaderView: View {
    let showGreeting: Bool
    let userName: String?
    let onProfileTap: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("BursaApp")
                    .font(.headline.bold())
                    .foregroundStyle(AppColors.ink)
                if showGreeting {
                    Text(userName.map { "Merhaba, \($0)" } ?? "Bursa'yı keşfet")
                        .font(.caption)
                        .foregroundStyle(AppColors.muted)
                }
            }
            Spacer()
            Button(action: onProfileTap) {
                Image(systemName: "person.crop.circle")
                    .font(.title2)
                    .foregroundStyle(AppColors.accentDeep)
            }
        }
        .padding(.top, 4)
    }
}

struct FloatingTabBar: View {
    @Binding var selection: ShellTab
    let onCreateTap: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ShellTab.allCases, id: \.rawValue) { item in
                if item == .food {
                    createButton
                }
                tabButton(item)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: AppRadii.xl, style: .continuous)
                .fill(AppColors.nav)
                .shadow(color: AppColors.ink.opacity(0.15), radius: 16, y: 8)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var createButton: some View {
        Button(action: onCreateTap) {
            Image(systemName: "plus")
                .font(.title3.bold())
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(
                    Circle()
                        .fill(AppColors.accentDeep)
                        .shadow(color: AppColors.accentDeep.opacity(0.45), radius: 10, y: 6)
                )
        }
        .offset(y: -18)
    }

    private func tabButton(_ item: ShellTab) -> some View {
        Button {
            selection = item
        } label: {
            VStack(spacing: 4) {
                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(item.title)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(selection == item ? AppColors.lime : .white.opacity(0.65))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
