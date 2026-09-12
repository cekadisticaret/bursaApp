import SwiftUI

struct FeedView: View {
    @EnvironmentObject private var auth: AuthStore
    @StateObject private var vm = FeedViewModel()
    @State private var showAuth = false
    @State private var showFilter = false
    @State private var showNotifications = false
    @State private var chip: TravelCategoryChip = .all
    @State private var query = ""

    var onSearchTap: (() -> Void)?
    var onChipTap: ((String, String) -> Void)?
    var onHotels: (() -> Void)?
    var onSeeAllEvents: (() -> Void)?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                TravelTopBar(location: "Bursa, Türkiye", notificationCount: 2, onNotificationsTap: { showNotifications = true })
                TravelHeroTitle()
                TravelSearchCapsule(query: $query, onSearchTap: { onSearchTap?() })
                TravelCategoryChips(selected: $chip)

                if let hero = infoHero {
                    TravelInfoCard(
                        title: hero.title,
                        subtitle: heroSubtitle(hero),
                        imageUrl: hero.imgUrl,
                        timeLabel: hero.startsAtLabel.isEmpty ? "Yakında" : hero.startsAtLabel,
                        tourLabel: hero.whenLabel.isEmpty ? "Bursa" : hero.whenLabel,
                        onTap: { if !hero.slug.isEmpty { /* NavigationLink below */ } }
                    )
                    .overlay {
                        if !hero.slug.isEmpty {
                            NavigationLink(value: hero.slug) { Color.clear }
                                .buttonStyle(.plain)
                        }
                    }
                }

                if chip == .all || chip == .event {
                    eventsSection
                }
                if !vm.leaders.isEmpty {
                    leadersSection
                }
                if !vm.locals.isEmpty {
                    localsSection
                }
                destinationsSection
            }
            .padding(.horizontal, AppSpacing.screenX)
            .padding(.bottom, 24)
        }
        .background(AppColors.bg.ignoresSafeArea())
        .refreshable {
            vm.load(auth: auth, refresh: true)
            while vm.isLoading { try? await Task.sleep(nanoseconds: 100_000_000) }
        }
        .task { vm.load(auth: auth, refresh: true) }
        .onChange(of: auth.isLoggedIn) { _ in vm.load(auth: auth, refresh: true) }
        .alert("Hata", isPresented: Binding(get: { vm.errorMessage != nil }, set: { if !$0 { vm.errorMessage = nil } })) {
            Button("Tamam", role: .cancel) {}
        } message: { Text(vm.errorMessage ?? "") }
        .sheet(isPresented: $showAuth) { AuthFlowView() }
        .sheet(isPresented: $showNotifications) { NavigationStack { NotificationsView() } }
        .sheet(isPresented: $showFilter) {
            FeedFilterSheet(onPick: { title, cat in onChipTap?(title, cat) }, onHotels: { onHotels?() })
        }
    }

    private var infoHero: EventItem? {
        vm.heroEvent ?? vm.events.first
    }

    private func heroSubtitle(_ hero: EventItem) -> String {
        let parts = [hero.ilce, "Etkinlik"].filter { !$0.isEmpty }
        return parts.joined(separator: " • ")
    }

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            TravelSectionHeader(title: "Yakınındaki etkinlikler", onSeeAll: onSeeAllEvents)
            if vm.events.isEmpty && !vm.isLoading {
                Text("Şu an etkinlik yok").font(.caption).foregroundStyle(AppColors.muted)
            } else {
                ForEach(vm.events.prefix(2)) { event in
                    if event.slug.isEmpty {
                        eventRow(event)
                    } else {
                        NavigationLink(value: event.slug) { eventRow(event) }.buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func eventRow(_ event: EventItem) -> some View {
        HStack(spacing: 12) {
            RemoteImage(url: event.imgUrl, placeholder: "calendar")
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: AppRadii.sm))
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title).font(.subheadline.weight(.bold)).foregroundStyle(AppColors.ink).lineLimit(2)
                Text(event.startsAtLabel.isEmpty ? event.whenLabel : event.startsAtLabel)
                    .font(.caption).foregroundStyle(AppColors.muted)
            }
            Spacer()
            Text("Katıl")
                .font(.caption.weight(.heavy))
                .foregroundStyle(AppColors.nav)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(AppColors.chipSelected))
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: AppRadii.md).fill(.white).shadow(color: .black.opacity(0.05), radius: 8, y: 3))
    }

    private var leadersSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            TravelSectionHeader(title: "Haftanın liderleri")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(vm.leaders) { leader in
                        TravelLeaderCard(leader: leader)
                    }
                }
            }
        }
    }

    private var localsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            TravelSectionHeader(title: "Yerel favoriler")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(vm.locals) { place in
                        NavigationLink(value: place.detailSlug) {
                            TravelLocalAvatar(place: place)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var destinationsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            TravelSectionHeader(title: "Öne çıkan rotalar", onSeeAll: {
                let cat = chip.apiCategory.isEmpty ? "visit" : chip.apiCategory
                onChipTap?(chip.title, cat)
            })
            if vm.isLoading && filteredDestinations.isEmpty {
                ProgressView().frame(maxWidth: .infinity).padding(.vertical, 30)
            } else {
                ForEach(filteredDestinations.prefix(6)) { place in
                    NavigationLink(value: place.detailSlug) {
                        TravelFeaturedCard(place: place)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var filteredDestinations: [PlaceItem] {
        var rows = vm.destinations
        if !chip.apiCategory.isEmpty {
            rows = rows.filter { $0.category == chip.apiCategory }
        }
        if !query.isEmpty {
            rows = rows.filter {
                $0.title.localizedCaseInsensitiveContains(query)
                    || $0.ilce.localizedCaseInsensitiveContains(query)
            }
        }
        return rows
    }
}
