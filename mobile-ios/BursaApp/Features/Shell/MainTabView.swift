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
    @State private var profilePath = NavigationPath()
    @State private var feedPath = NavigationPath()
    @State private var showAuth = false
    @State private var showCreateEvent = false
    @State private var showNotifications = false

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                AppHeaderView(
                    showGreeting: tab == .feed,
                    userName: auth.user?.displayName,
                    avatarUrl: auth.user?.avatarUrl,
                    onProfileTap: { tab = .profile },
                    onNotificationsTap: { showNotifications = true }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                TabContent(
                    tab: tab,
                    profilePath: $profilePath,
                    feedPath: $feedPath,
                    tabSelection: $tab,
                    showAuth: $showAuth
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 88)
            }

            FloatingTabBar(
                selection: $tab,
                onCreateTap: {
                    if auth.isLoggedIn {
                        showCreateEvent = true
                    } else {
                        showAuth = true
                    }
                }
            )
        }
        .sheet(isPresented: $showAuth) {
            AuthFlowView()
        }
        .sheet(isPresented: $showCreateEvent) {
            CreateEventView()
        }
        .sheet(isPresented: $showNotifications) {
            NavigationStack {
                NotificationsView()
            }
        }
    }
}

private struct TabContent: View {
    let tab: ShellTab
    @Binding var profilePath: NavigationPath
    @Binding var feedPath: NavigationPath
    @Binding var tabSelection: ShellTab
    @Binding var showAuth: Bool

    var body: some View {
        switch tab {
        case .feed:
            NavigationStack(path: $feedPath) {
                FeedView(
                    onSearchTap: { feedPath.append(AppNavRoute.search("")) },
                    onChipTap: { title, category in
                        feedPath.append(AppNavRoute.category(title, category))
                    }
                )
                    .navigationDestination(for: AppNavRoute.self) { route in
                        switch route {
                        case .search(let q):
                            PlaceSearchView(initialQuery: q)
                        case .category(let title, let cat):
                            CategoryPlacesView(title: title, category: cat)
                        default:
                            EmptyView()
                        }
                    }
                    .navigationDestination(for: String.self) { slug in
                        PlaceDetailView(slug: slug)
                    }
            }
        case .explore:
            ExploreView()
        case .food:
            FoodView()
        case .profile:
            NavigationStack(path: $profilePath) {
                ProfileView(tabSelection: $tabSelection, navPath: $profilePath)
                    .navigationDestination(for: MenuDestination.self) { dest in
                        MenuDestinationView(link: dest.link)
                    }
                    .navigationDestination(for: String.self) { slug in
                        PlaceDetailView(slug: slug)
                    }
                    .navigationDestination(for: AppNavRoute.self) { route in
                        if case .settings = route {
                            ProfileSettingsView()
                        }
                    }
            }
        }
    }
}

struct AppHeaderView: View {
    let showGreeting: Bool
    let userName: String?
    let avatarUrl: String?
    let onProfileTap: () -> Void
    let onNotificationsTap: () -> Void

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
            Button(action: onNotificationsTap) {
                Image(systemName: "bell")
                    .font(.title3)
                    .foregroundStyle(AppColors.ink)
            }
            Button(action: onProfileTap) {
                if let avatarUrl, !avatarUrl.isEmpty {
                    RemoteImage(url: avatarUrl, placeholder: "person.crop.circle")
                        .frame(width: 34, height: 34)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle")
                        .font(.title2)
                        .foregroundStyle(AppColors.accentDeep)
                }
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
