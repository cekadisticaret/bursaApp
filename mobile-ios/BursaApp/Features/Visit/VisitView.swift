import SwiftUI

struct VisitView: View {
    @EnvironmentObject private var auth: AuthStore
    @State private var places: [PlaceItem] = []
    @State private var meta: [String: Any] = [:]
    @State private var loading = true
    @State private var error: String?
    @State private var query = ""
    @State private var sort = "featured"
    @State private var ilce = ""
    @State private var kinds: Set<String> = []
    @State private var fees: Set<String> = []
    @State private var page = 1
    @State private var hasMore = false

    private let sortChips = [("featured", "Öne çıkan"), ("rating", "Puan"), ("name", "A–Z")]
    private let feeChips = [("free", "Ücretsiz"), ("paid", "Ücretli")]

    var body: some View {
        AppPage(title: "Gezilecek yerler") {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        TextField("Ara…", text: $query)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.search)
                            .onSubmit { Task { await load(refresh: true) } }
                        Button("Ara") { Task { await load(refresh: true) } }
                            .buttonStyle(.borderedProminent)
                            .tint(AppColors.accentDeep)
                    }
                    FilterChips(items: sortChips, selected: sort) { sort = $0; Task { await load(refresh: true) } }
                    if let ilceler = meta["ilceler"] as? [String], !ilceler.isEmpty {
                        FilterChips(items: [("", "Tüm ilçe")] + ilceler.map { ($0, $0) }, selected: ilce) {
                            ilce = $0; Task { await load(refresh: true) }
                        }
                    }
                    if let kindRows = meta["kinds"] as? [[String: Any]], !kindRows.isEmpty {
                        FilterChips(
                            items: [("", "Tüm tür")] + kindRows.compactMap { row in
                                guard let key = row["key"] as? String, let label = row["label"] as? String else { return nil }
                                return (key, label)
                            },
                            selected: kinds.first ?? ""
                        ) { key in
                            if key.isEmpty { kinds.removeAll() }
                            else if kinds.contains(key) { kinds.remove(key) } else { kinds = [key] }
                            Task { await load(refresh: true) }
                        }
                    }
                    FilterChips(items: [("", "Tüm ücret")] + feeChips, selected: fees.first ?? "") { key in
                        if key.isEmpty { fees.removeAll() }
                        else if fees.contains(key) { fees.remove(key) } else { fees = [key] }
                        Task { await load(refresh: true) }
                    }
                    LoadingStateView(loading: loading, error: error, empty: !loading && places.isEmpty, emptyText: "Mekan bulunamadı")
                    PlaceListSection(places: places)
                    if hasMore && !loading {
                        Button("Daha fazla") { Task { await loadMore() } }
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(AppColors.accentDeep)
                    }
                }
                .padding(16)
            }
            .refreshable { await load(refresh: true) }
            .task { await load(refresh: true) }
        }
    }

    @MainActor
    private func load(refresh: Bool) async {
        if refresh { page = 1 }
        loading = true
        error = nil
        defer { loading = false }
        do {
            let json = try await auth.apiClient().visitPlaces(
                page: page, q: query, ilce: ilce, sort: sort,
                kinds: Array(kinds), fees: Array(fees)
            )
            meta = json
            let next = PlaceItem.list(from: json)
            places = refresh ? next : places + next
            hasMore = json["has_more"] as? Bool ?? false
        } catch {
            self.error = error.localizedDescription
        }
    }

    @MainActor
    private func loadMore() async {
        page += 1
        await load(refresh: false)
    }
}
