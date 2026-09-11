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
    @StateObject private var shellNav = ShellNavigator()
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
                    user: auth.user,
                    isLoggedIn: auth.isLoggedIn,
                    onProfileTap: { tab = .profile },
                    onNotificationsTap: { showNotifications = true }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                ZStack {
                    FeedTabStack(path: $feedPath, isActive: tab == .feed, showAuth: $showAuth)
                    ExploreTabStack(isActive: tab == .explore)
                    FoodTabStack(isActive: tab == .food)
                    ProfileTabStack(path: $profilePath, tabSelection: $tab, isActive: tab == .profile, showAuth: $showAuth)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 88)
            }

            FloatingTabBar(
                selection: $tab,
                onCreateTap: {
                    if auth.isLoggedIn { showCreateEvent = true }
                    else { showAuth = true }
                }
            )
        }
        .sheet(isPresented: $showAuth) { AuthFlowView() }
        .sheet(isPresented: $showCreateEvent) { CreateEventView() }
        .sheet(isPresented: $showNotifications) {
            NavigationStack { NotificationsView() }
        }
        .environmentObject(shellNav)
        .onAppear { shellNav.onSelectTab = { tab = $0 } }
    }
}

private struct FeedTabStack: View {
    @Binding var path: NavigationPath
    let isActive: Bool
    @Binding var showAuth: Bool

    var body: some View {
        NavigationStack(path: $path) {
            FeedView(
                onSearchTap: { path.append(AppNavRoute.search("")) },
                onChipTap: { title, cat in path.append(AppNavRoute.category(title, cat)) },
                onHotels: { path.append(AppNavRoute.hotels) },
                onSeeAllEvents: { path.append(AppNavRoute.category("Etkinlikler", "event")) }
            )
            .navigationDestination(for: AppNavRoute.self) { route in
                switch route {
                case .search(let q): PlaceSearchView(initialQuery: q)
                case .category(let title, let cat): CategoryPlacesView(title: title, category: cat)
                case .hotels: HotelsView()
                default: EmptyView()
                }
            }
            .navigationDestination(for: String.self) { slug in PlaceDetailView(slug: slug) }
        }
        .opacity(isActive ? 1 : 0)
        .allowsHitTesting(isActive)
    }
}

private struct ExploreTabStack: View {
    let isActive: Bool
    var body: some View {
        ExploreView()
            .opacity(isActive ? 1 : 0)
            .allowsHitTesting(isActive)
    }
}

private struct FoodTabStack: View {
    let isActive: Bool
    var body: some View {
        FoodView()
            .opacity(isActive ? 1 : 0)
            .allowsHitTesting(isActive)
    }
}

private struct ProfileTabStack: View {
    @Binding var path: NavigationPath
    @Binding var tabSelection: ShellTab
    let isActive: Bool
    @Binding var showAuth: Bool

    var body: some View {
        NavigationStack(path: $path) {
            ProfileView(tabSelection: $tabSelection, navPath: $path)
                .navigationDestination(for: MenuDestination.self) { MenuDestinationView(link: $0.link) }
                .navigationDestination(for: String.self) { PlaceDetailView(slug: $0) }
                .navigationDestination(for: AppNavRoute.self) { route in
                    switch route {
                    case .settings: ProfileSettingsView()
                    case .createEvent: CreateEventView()
                    case .hotels: HotelsView()
                    case .category(let title, let cat): CategoryPlacesView(title: title, category: cat)
                    default: EmptyView()
                    }
                }
        }
        .opacity(isActive ? 1 : 0)
        .allowsHitTesting(isActive)
    }
}

struct AppHeaderView: View {
    let showGreeting: Bool
    let user: AuthUser?
    let isLoggedIn: Bool
    let onProfileTap: () -> Void
    let onNotificationsTap: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image("BrandMark")
                .resizable()
                .scaledToFill()
                .frame(width: 38, height: 38)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                if showGreeting {
                    Text(isLoggedIn ? "Merhaba, \(firstName) 👋" : "Merhaba 👋")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.muted)
                }
                Text("BursaApp")
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(AppColors.ink)
            }
            Spacer()
            Button(action: onNotificationsTap) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.ink)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(AppColors.card).cardShadow())
                    Circle()
                        .fill(AppColors.coral)
                        .frame(width: 8, height: 8)
                        .offset(x: -10, y: 10)
                }
            }
            Button(action: onProfileTap) {
                headerAvatar
            }
        }
        .padding(.top, 4)
    }

    private var firstName: String {
        guard let name = user?.name, !name.isEmpty else { return "BursaApp" }
        return name.split(separator: " ").first.map(String.init) ?? name
    }

    @ViewBuilder
    private var headerAvatar: some View {
        let letter = (user?.name.first.map(String.init) ?? "B").uppercased()
        Group {
            if isLoggedIn, let url = user?.avatarUrl, !url.isEmpty {
                RemoteImage(url: url, placeholder: letter)
            } else {
                Text(letter)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppColors.accentDeep)
            }
        }
        .frame(width: 46, height: 46)
        .clipShape(Circle())
        .overlay(Circle().stroke(AppColors.lime, lineWidth: 2.5))
        .cardShadow()
    }
}

struct FloatingTabBar: View {
    @Binding var selection: ShellTab
    let onCreateTap: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ShellTab.allCases, id: \.rawValue) { item in
                if item == .food { createButton }
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
                .background(Circle().fill(AppColors.accentDeep).shadow(color: AppColors.accentDeep.opacity(0.45), radius: 10, y: 6))
        }
        .offset(y: -18)
    }

    private func tabButton(_ item: ShellTab) -> some View {
        Button { selection = item } label: {
            VStack(spacing: 4) {
                Image(systemName: item.icon).font(.system(size: 18, weight: .semibold))
                Text(item.title).font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(selection == item ? AppColors.lime : .white.opacity(0.65))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
