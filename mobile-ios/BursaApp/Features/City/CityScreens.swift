import SwiftUI

struct PharmacyView: View {
    @EnvironmentObject private var auth: AuthStore
    @State private var rows: [[String: Any]] = []
    @State private var loading = true
    @State private var error: String?

    var body: some View {
        AppPage(title: "Nöbetçi eczaneler") {
            ScrollView {
                VStack(spacing: 12) {
                    LoadingStateView(loading: loading, error: error, empty: !loading && rows.isEmpty, emptyText: "Bugün nöbetçi eczane yok")
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                        pharmacyCard(row)
                    }
                }
                .padding(16)
            }
            .refreshable { await load() }
            .task { await load() }
        }
    }

    @ViewBuilder
    private func pharmacyCard(_ row: [String: Any]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(row["title"] as? String ?? row["name"] as? String ?? "Eczane")
                .font(.headline)
            if let ilce = row["ilce"] as? String, !ilce.isEmpty {
                Text(ilce).font(.caption).foregroundStyle(AppColors.accentDeep)
            }
            if let addr = row["address"] as? String ?? row["adres"] as? String, !addr.isEmpty {
                Text(addr).font(.caption).foregroundStyle(AppColors.muted)
            }
            if let tel = row["phone"] as? String ?? row["tel"] as? String, !tel.isEmpty {
                Link(tel, destination: URL(string: "tel:\(tel.filter { $0.isNumber || $0 == "+" })") ?? URL(string: "tel:")!)
                    .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: AppRadii.md).fill(AppColors.card))
    }

    @MainActor
    private func load() async {
        loading = true
        error = nil
        defer { loading = false }
        do {
            let json = try await auth.apiClient().nobetciEczaneler()
            rows = json["pharmacies"] as? [[String: Any]] ?? json["places"] as? [[String: Any]] ?? []
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct NewsView: View {
    @EnvironmentObject private var auth: AuthStore
    @State private var rows: [[String: Any]] = []
    @State private var loading = true

    var body: some View {
        AppPage(title: "Bursa haberleri") {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if loading { ProgressView().padding() }
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(row["title"] as? String ?? "Haber")
                                .font(.headline)
                            if let sum = row["summary"] as? String ?? row["blurb"] as? String {
                                Text(sum).font(.caption).foregroundStyle(AppColors.muted).lineLimit(3)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: AppRadii.md).fill(AppColors.card))
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
        defer { loading = false }
        if let json = try? await auth.apiClient().bursaNews() {
            rows = json["news"] as? [[String: Any]] ?? json["items"] as? [[String: Any]] ?? []
        }
    }
}

struct BursasporView: View {
    @EnvironmentObject private var auth: AuthStore
    @State private var payload: [String: Any] = [:]
    @State private var loading = true

    var body: some View {
        AppPage(title: "Bursaspor") {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if loading { ProgressView() }
                    if let match = payload["match"] as? [String: Any] {
                        Text("Maç").font(.headline)
                        Text(match["label"] as? String ?? match["title"] as? String ?? "")
                    }
                    let news = payload["news"] as? [[String: Any]] ?? []
                    ForEach(Array(news.enumerated()), id: \.offset) { _, row in
                        Text(row["title"] as? String ?? "")
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: AppRadii.md).fill(AppColors.card))
                    }
                }
                .padding(16)
            }
            .task { await load() }
        }
    }

    @MainActor
    private func load() async {
        loading = true
        defer { loading = false }
        if let json = try? await auth.apiClient().bursasporFeed() {
            payload = json
        }
    }
}

struct TeleferikView: View {
    @EnvironmentObject private var auth: AuthStore
    @State private var info: [String: Any] = [:]

    var body: some View {
        AppPage(title: "Uludağ teleferik") {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if let status = info["status"] as? String { Text(status).font(.headline) }
                    if let price = info["price"] as? String { Text("Bilet: \(price)") }
                    if let hours = info["hours"] as? String { Text("Saatler: \(hours)") }
                    if let note = info["note"] as? String { Text(note).foregroundStyle(AppColors.muted) }
                }
                .padding(16)
            }
            .task {
                if let json = try? await auth.apiClient().teleferikInfo() {
                    info = json
                }
            }
        }
    }
}

struct UtilitiesView: View {
    @EnvironmentObject private var auth: AuthStore
    @State private var sections: [[String: Any]] = []

    var body: some View {
        AppPage(title: "Faturalar & tarifeler") {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(sections.enumerated()), id: \.offset) { _, sec in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(sec["title"] as? String ?? "Kurum")
                                .font(.headline)
                            if let body = sec["body"] as? String {
                                Text(body).font(.caption).foregroundStyle(AppColors.muted)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: AppRadii.md).fill(AppColors.card))
                    }
                }
                .padding(16)
            }
            .task { await load() }
        }
    }

    @MainActor
    private func load() async {
        if let json = try? await auth.apiClient().utilitiesInfo() {
            sections = json["sections"] as? [[String: Any]] ?? []
        }
    }
}

struct WeekendView: View {
    @EnvironmentObject private var auth: AuthStore
    @State private var picks: [[String: Any]] = []

    var body: some View {
        AppPage(title: "Hafta sonu planı") {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(picks.enumerated()), id: \.offset) { _, row in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(row["title"] as? String ?? "Öneri")
                                .font(.headline)
                            if let blurb = row["blurb"] as? String {
                                Text(blurb).font(.caption).foregroundStyle(AppColors.muted)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: AppRadii.md).fill(AppColors.card))
                    }
                }
                .padding(16)
            }
            .task {
                if let json = try? await auth.apiClient().weekend() {
                    picks = json["picks"] as? [[String: Any]] ?? json["places"] as? [[String: Any]] ?? []
                }
            }
        }
    }
}

struct LeadersView: View {
    @EnvironmentObject private var auth: AuthStore
    @State private var leaders: [LeaderRow] = []

    var body: some View {
        AppPage(title: "Haftanın liderleri") {
            List(leaders) { row in
                HStack {
                    Text("#\(row.rank)").font(.headline).foregroundStyle(AppColors.accentDeep)
                    Text(row.name)
                    Spacer()
                    Text("\(row.points) puan").foregroundStyle(AppColors.muted)
                }
            }
            .task {
                if let rows = try? await auth.apiClient().weeklyLeaders() {
                    leaders = rows
                }
            }
        }
    }
}

struct ActivityBuddyView: View {
    var body: some View {
        AppPage(title: "Partner ara") {
            Text("Aktivite partner ilanları — giriş yaparak listeyi görebilirsin.")
                .foregroundStyle(AppColors.muted)
                .padding()
        }
    }
}
