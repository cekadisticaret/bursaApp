import SwiftUI

struct FeedView: View {
    @EnvironmentObject private var auth: AuthStore
    @StateObject private var vm = FeedViewModel()
    @State private var showAuth = false
    @State private var showFilter = false
    @State private var chip = "all"

    var onSearchTap: (() -> Void)?
    var onChipTap: ((String, String) -> Void)?
    var onHotels: (() -> Void)?
    var onSeeAllEvents: (() -> Void)?

    private let chips: [(String, String)] = [
        ("all", "Tümü"), ("event", "Etkinlik"), ("food", "Lezzet"), ("visit", "Gezi"),
    ]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                FeedSearchBar(onSearchTap: { onSearchTap?() }, onFilterTap: { showFilter = true })
                FilterChips(items: chips, selected: chip, onSelect: onChip)
                if let hero = vm.heroEvent {
                    NavigationLink(value: hero.slug) {
                        FeedHeroCard(event: hero)
                    }
                    .buttonStyle(.plain)
                    HStack {
                        Text("Topluluk akışı").font(.headline.weight(.black))
                        Spacer()
                        Button("Tümü") { onSeeAllEvents?() }
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(AppColors.accentDeep)
                    }
                }
                if vm.isLoading && vm.rows.isEmpty {
                    ProgressView().frame(maxWidth: .infinity).padding(.vertical, 40)
                } else {
                    ForEach(vm.rows) { row in
                        switch row {
                        case .post(let item):
                            FeedPostCard(item: item) {
                                if auth.isLoggedIn { Task { await vm.toggleLike(postId: item.id, auth: auth) } }
                                else { showAuth = true }
                            }
                        case .event(let event):
                            if event.slug.isEmpty {
                                FeedEventStrip(event: event)
                            } else {
                                NavigationLink(value: event.slug) {
                                    FeedEventStrip(event: event)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                if vm.hasMore && !vm.isLoading {
                    Button("Daha fazla") { vm.loadMore(auth: auth) }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(AppColors.accentDeep)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
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
        .sheet(isPresented: $showFilter) {
            FeedFilterSheet(
                onPick: { title, cat in onChipTap?(title, cat) },
                onHotels: { onHotels?() }
            )
        }
    }

    private func onChip(_ value: String) {
        chip = value
        if value == "all" { vm.load(auth: auth, refresh: true); return }
        let title: String
        let category: String
        switch value {
        case "event": title = "Etkinlikler"; category = "event"
        case "food": title = "Lezzet"; category = "food"
        default: title = "Gezilecek"; category = "visit"
        }
        onChipTap?(title, category)
    }
}

private struct FeedHeroCard: View {
    let event: EventItem
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImage(url: event.imgUrl).frame(height: 220).clipped()
            LinearGradient(colors: [.clear, AppColors.ink.opacity(0.75)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 8) {
                Text(event.whenLabel.isEmpty ? "Yakında" : event.whenLabel)
                    .font(.caption2.weight(.black))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(AppColors.lime))
                Text(event.title).font(.title2.weight(.black)).foregroundStyle(.white)
                Text("\(event.startsAtLabel)\(event.ilce.isEmpty ? "" : " · \(event.ilce)")")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.xl))
        .cardShadow()
    }
}

private struct FeedEventStrip: View {
    let event: EventItem
    var body: some View {
        HStack(spacing: 12) {
            RemoteImage(url: event.imgUrl).frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: AppRadii.sm))
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title).font(.subheadline.weight(.black)).lineLimit(2)
                Text(event.startsAtLabel.isEmpty ? event.whenLabel : event.startsAtLabel)
                    .font(.caption).foregroundStyle(AppColors.muted)
            }
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: AppRadii.md).fill(AppColors.card).cardShadow())
    }
}

private struct FeedPostCard: View {
    let item: FeedItem
    let onLike: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Circle()
                    .fill(AppColors.accentDeep)
                    .frame(width: 36, height: 36)
                    .overlay(Text(String(item.user.name.prefix(1)).uppercased()).foregroundStyle(.white).fontWeight(.bold))
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.user.name).font(.subheadline.weight(.heavy))
                    Text("\(item.ago) · \(item.user.handle)").font(.caption).foregroundStyle(AppColors.muted)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "star.fill").foregroundStyle(AppColors.amber).font(.caption)
                    Text("4.8").font(.caption.weight(.heavy))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(AppColors.bgSoft))
            }
            .padding(14)
            if let first = item.images.first {
                RemoteImage(url: first)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1.1, contentMode: .fill)
                    .clipped()
                    .padding(.horizontal, 12)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadii.md))
            }
            if !item.body.isEmpty {
                Text(item.body).padding(.horizontal, 16).padding(.vertical, 12)
            }
            if let title = item.placeTitle, !title.isEmpty, let slug = item.placeSlug, !slug.isEmpty {
                NavigationLink(value: slug) {
                    Label(title, systemImage: "mappin.and.ellipse")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppColors.accentDeep)
                        .padding(.horizontal, 16)
                }
                .buttonStyle(.plain)
            } else if let title = item.placeTitle, !title.isEmpty {
                Label(title, systemImage: "mappin.and.ellipse")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppColors.muted)
                    .padding(.horizontal, 16)
            }
            HStack(spacing: 12) {
                pill(icon: item.liked ? "heart.fill" : "heart", label: "\(item.likes)", accent: AppColors.coral, action: onLike)
                pill(icon: "bubble.right", label: "\(item.comments)", accent: AppColors.muted, action: {})
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .background(RoundedRectangle(cornerRadius: AppRadii.lg).fill(AppColors.card).cardShadow())
    }

    private func pill(icon: String, label: String, accent: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.caption.weight(.heavy))
                .foregroundStyle(accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(AppColors.bgSoft))
        }
        .buttonStyle(.plain)
    }
}
