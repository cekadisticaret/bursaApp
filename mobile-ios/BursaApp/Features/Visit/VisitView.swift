import SwiftUI

struct VisitView: View {
    @EnvironmentObject private var auth: AuthStore
    @State private var places: [PlaceItem] = []
    @State private var loading = true
    @State private var error: String?
    @State private var query = ""

    var body: some View {
        AppPage(title: "Gezilecek yerler") {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        TextField("Ara…", text: $query)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.search)
                            .onSubmit { Task { await load() } }
                        Button("Ara") { Task { await load() } }
                            .buttonStyle(.borderedProminent)
                            .tint(AppColors.accentDeep)
                    }
                    LoadingStateView(loading: loading, error: error, empty: !loading && places.isEmpty, emptyText: "Mekan bulunamadı")
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
            let json = try await auth.apiClient().visitPlaces(page: 1, q: query)
            places = PlaceItem.list(from: json)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
