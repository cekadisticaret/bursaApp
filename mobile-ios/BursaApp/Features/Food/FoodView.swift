import SwiftUI

struct FoodView: View {
    @EnvironmentObject private var auth: AuthStore
    @State private var filter = "food"
    @State private var places: [PlaceItem] = []
    @State private var loading = true
    @State private var error: String?
    @State private var path = NavigationPath()

    private let filters: [(String, String)] = [
        ("food", "Restoran & kafe"),
        ("live", "Canlı müzik"),
        ("fun2", "Eğlence"),
    ]

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Yeme & içme")
                        .font(.title2.bold())
                        .foregroundStyle(AppColors.ink)
                    filterPills
                    LoadingStateView(loading: loading, error: error, empty: !loading && places.isEmpty, emptyText: "Sonuç yok")
                    PlaceListSection(places: places)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .refreshable { await load() }
            .task { await load() }
            .navigationDestination(for: String.self) { slug in
                PlaceDetailView(slug: slug)
            }
        }
    }

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.0) { key, label in
                    Button(label) {
                        filter = key
                        Task { await load() }
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(filter == key ? AppColors.accentDeep : AppColors.card)
                    .foregroundStyle(filter == key ? .white : AppColors.ink)
                    .clipShape(Capsule())
                }
            }
        }
    }

    @MainActor
    private func load() async {
        loading = true
        error = nil
        defer { loading = false }
        do {
            let api = auth.apiClient()
            switch filter {
            case "live":
                let funRows = try await api.places(category: "fun", spec: "Canlı müzik", limit: 40)
                let barRows = try await api.places(category: "nightlife", sub: "canli-muzik", limit: 40)
                var seen = Set<String>()
                places = (funRows + barRows).filter { p in
                    guard !p.slug.isEmpty, !seen.contains(p.slug) else { return false }
                    seen.insert(p.slug)
                    return true
                }
            case "fun2":
                places = try await api.places(category: "fun", limit: 24)
            default:
                places = try await api.places(category: "food", limit: 24)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
