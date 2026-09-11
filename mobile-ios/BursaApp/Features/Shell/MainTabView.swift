import SwiftUI

enum ShellTab: Int, CaseIterable {
    case feed, explore, food, profile

    var title: String {
        switch self {
        case .feed: "Ana sayfa"
        case .explore: "Harita"
        case .food: "Lezzet"
        case .profile: "Profil"
        }
    }

    var icon: String {
        switch self {
        case .feed: "house.fill"
        case .explore: "magnifyingglass"
        case .food: "heart"
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
                userAvatar: auth.user?.avatarUrl,
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
            .padding(.top, isActive ? 8 : 0)
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
            .padding(.top, isActive ? 8 : 0)
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
                .navigationDestination(for: String.self) { PlaceDetailView(slug: slug) }
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

struct FloatingTabBar: View {
    @Binding var selection: ShellTab
    var userAvatar: String?
    let onCreateTap: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            tabIcon(.feed)
            tabIcon(.explore)
            createButton
            tabIcon(.food)
            profileIcon
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.10), radius: 16, y: 6)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private func tabIcon(_ item: ShellTab) -> some View {
        Button { selection = item } label: {
            ZStack {
                if selection == item {
                    Circle()
                        .fill(AppColors.nav)
                        .frame(width: 46, height: 46)
                }
                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(selection == item ? .white : AppColors.muted)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 46)
        }
        .buttonStyle(.plain)
    }

    private var createButton: some View {
        Button(action: onCreateTap) {
            Image(systemName: "plus")
                .font(.title3.bold())
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(Circle().fill(AppColors.nav).shadow(color: AppColors.nav.opacity(0.35), radius: 10, y: 5))
        }
        .offset(y: -14)
    }

    private var profileIcon: some View {
        Button { selection = .profile } label: {
            ZStack {
                if selection == .profile {
                    Circle().fill(AppColors.nav).frame(width: 46, height: 46)
                }
                Group {
                    if let userAvatar, !userAvatar.isEmpty {
                        RemoteImage(url: userAvatar, placeholder: "person.fill")
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                .frame(width: 28, height: 28)
                .clipShape(Circle())
                .foregroundStyle(selection == .profile ? .white : AppColors.muted)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 46)
        }
        .buttonStyle(.plain)
    }
}
