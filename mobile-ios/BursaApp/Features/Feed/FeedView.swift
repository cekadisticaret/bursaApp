import SwiftUI

struct FeedView: View {
    @EnvironmentObject private var auth: AuthStore
    @StateObject private var vm = FeedViewModel()
    @State private var showAuth = false
    var onSearchTap: (() -> Void)?
    var onChipTap: ((String, String) -> Void)?

    private let chips: [(String, String)] = [
        ("all", "Tümü"), ("event", "Etkinlik"), ("food", "Lezzet"), ("visit", "Gezi"),
    ]
    @State private var chip = "all"

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                searchBar
                FilterChips(items: chips, selected: chip, onSelect: onChip)
                if let hero = vm.heroEvent {
                    NavigationLink(value: hero.slug) {
                        HeroEventCard(event: hero)
                    }
                    .buttonStyle(.plain)
                    sectionTitle("Topluluk akışı")
                }
                if vm.isLoading && vm.rows.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else {
                    ForEach(vm.rows) { row in
                        switch row {
                        case .post(let item):
                            FeedCard(item: item) {
                                if auth.isLoggedIn {
                                    Task { await vm.toggleLike(postId: item.id, auth: auth) }
                                } else {
                                    showAuth = true
                                }
                            }
                        case .event(let event):
                            if event.slug.isEmpty {
                                EventStripCard(event: event)
                            } else {
                                NavigationLink(value: event.slug) {
                                    EventStripCard(event: event)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                if vm.hasMore && !vm.isLoading {
                    Button("Daha fazla") {
                        vm.loadMore(auth: auth)
                    }
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
        .task {
            vm.load(auth: auth, refresh: true)
        }
        .onChange(of: auth.isLoggedIn) { _ in
            vm.load(auth: auth, refresh: true)
        }
        .alert("Hata", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .sheet(isPresented: $showAuth) {
            AuthFlowView()
        }
    }

    private func onChip(_ value: String) {
        chip = value
        if value == "all" {
            vm.load(auth: auth, refresh: true)
            return
        }
        let title: String
        let category: String
        switch value {
        case "event":
            title = "Etkinlikler"
            category = "event"
        case "food":
            title = "Lezzet"
            category = "food"
        default:
            title = "Gezilecek"
            category = "visit"
        }
        onChipTap?(title, category)
    }

    private var searchBar: some View {
        Button(action: { onSearchTap?() }) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppColors.muted)
                Text("Mekan, etkinlik, mahalle…")
                    .foregroundStyle(AppColors.muted)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: AppRadii.lg, style: .continuous)
                    .fill(AppColors.card)
                    .shadow(color: AppColors.ink.opacity(0.06), radius: 18, y: 8)
            )
        }
        .buttonStyle(.plain)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline.bold())
            .foregroundStyle(AppColors.ink)
    }
}

private struct HeroEventCard: View {
    let event: EventItem

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImage(url: event.imgUrl)
                .frame(height: 200)
                .clipped()
            LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 4) {
                Text(event.whenLabel)
                    .font(.caption.bold())
                    .foregroundStyle(AppColors.lime)
                Text(event.title)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                if !event.ilce.isEmpty {
                    Text(event.ilce)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.md, style: .continuous))
    }
}

private struct EventStripCard: View {
    let event: EventItem

    var body: some View {
        HStack(spacing: 12) {
            RemoteImage(url: event.imgUrl)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: AppRadii.sm, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.ink)
                    .lineLimit(2)
                Text(event.startsAtLabel.isEmpty ? event.whenLabel : event.startsAtLabel)
                    .font(.caption)
                    .foregroundStyle(AppColors.muted)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: AppRadii.md, style: .continuous)
                .fill(AppColors.card)
        )
    }
}

private struct FeedCard: View {
    let item: FeedItem
    let onLike: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                RemoteImage(url: item.user.avatarUrl, placeholder: "person.circle.fill")
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.user.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppColors.ink)
                    Text("\(item.user.handle) · \(item.ago)")
                        .font(.caption)
                        .foregroundStyle(AppColors.muted)
                }
                Spacer()
            }
            if !item.body.isEmpty {
                Text(item.body)
                    .font(.body)
                    .foregroundStyle(AppColors.ink)
            }
            if let first = item.images.first {
                RemoteImage(url: first)
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadii.sm, style: .continuous))
            }
            HStack(spacing: 16) {
                Button(action: onLike) {
                    Label("\(item.likes)", systemImage: item.liked ? "heart.fill" : "heart")
                        .foregroundStyle(item.liked ? AppColors.coral : AppColors.muted)
                }
                Label("\(item.comments)", systemImage: "bubble.right")
                    .foregroundStyle(AppColors.muted)
                Spacer()
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: AppRadii.md, style: .continuous)
                .fill(AppColors.card)
                .shadow(color: AppColors.ink.opacity(0.05), radius: 12, y: 6)
        )
    }
}
