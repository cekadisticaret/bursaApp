import SwiftUI

struct CategoryPlacesView: View {
    @EnvironmentObject private var auth: AuthStore
    let title: String
    let category: String
    @State private var places: [PlaceItem] = []
    @State private var loading = true
    @State private var error: String?

    var body: some View {
        AppPage(title: title) {
            ScrollView {
                VStack(spacing: 12) {
                    LoadingStateView(loading: loading, error: error, empty: !loading && places.isEmpty, emptyText: "Sonuç yok")
                    PlaceListSection(places: places)
                }
                .padding(16)
            }
            .refreshable { await load() }
            .task { await load() }
        }
    }

    @MainActor
    private func load() async {
        loading = true
        error = nil
        defer { loading = false }
        do {
            places = try await auth.apiClient().places(category: category, limit: 40)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct MobilePlacesView: View {
    @EnvironmentObject private var auth: AuthStore
    let endpoint: MobileEndpoint
    let title: String
    @State private var places: [PlaceItem] = []
    @State private var groups: [[String: Any]] = []
    @State private var ilceler: [String] = []
    @State private var specs: [String] = []
    @State private var ilce = ""
    @State private var tab = "hepsi"
    @State private var band = ""
    @State private var spec = ""
    @State private var query = ""
    @State private var loading = true
    @State private var error: String?

    var body: some View {
        AppPage(title: title) {
            ScrollView {
                VStack(spacing: 12) {
                    if endpoint == .hotels {
                        TextField("Otel ara…", text: $query)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.search)
                            .onSubmit { Task { await load() } }
                    }
                    if !ilceler.isEmpty {
                        FilterChips(items: [("", "Tüm ilçe")] + ilceler.map { ($0, $0) }, selected: ilce) {
                            ilce = $0; Task { await load() }
                        }
                    }
                    if endpoint == .vets {
                        FilterChips(
                            items: [("hepsi", "Hepsi"), ("klinik", "Klinik"), ("petshop", "Pet shop")],
                            selected: tab
                        ) { tab = $0; Task { await load() } }
                    }
                    if endpoint == .dentists || endpoint == .hospitals {
                        FilterChips(
                            items: [("", "Tümü"), ("devlet", "Devlet"), ("ozel", "Özel")],
                            selected: band
                        ) { band = $0; Task { await load() } }
                    }
                    if endpoint == .doctors, !specs.isEmpty {
                        FilterChips(items: [("", "Tüm branş")] + specs.map { ($0, $0) }, selected: spec) {
                            spec = $0; Task { await load() }
                        }
                    }
                    LoadingStateView(loading: loading, error: error, empty: !loading && places.isEmpty && groups.isEmpty, emptyText: "Kayıt yok")
                    if !groups.isEmpty {
                        GroupedPlaceList(groups: groups)
                    } else {
                        PlaceListSection(places: places)
                    }
                }
                .padding(16)
            }
            .refreshable { await load() }
            .task { await load() }
        }
    }

    @MainActor
    private func load() async {
        loading = true
        error = nil
        defer { loading = false }
        do {
            let json = try await auth.apiClient().mobilePlaces(
                endpoint,
                ilce: ilce.isEmpty ? nil : ilce,
                tab: endpoint == .vets ? tab : nil,
                band: band.isEmpty ? nil : band,
                spec: spec.isEmpty ? nil : spec,
                q: query.isEmpty ? nil : query
            )
            groups = json["groups"] as? [[String: Any]] ?? []
            places = PlaceItem.fromGroups(json)
            ilceler = json["ilceler"] as? [String] ?? []
            specs = json["specs"] as? [String] ?? json["specialties"] as? [String] ?? []
        } catch {
            self.error = error.localizedDescription
        }
    }
}
