import SwiftUI

struct PlaceDetailView: View {
    @EnvironmentObject private var auth: AuthStore
    let slug: String
    @State private var place: [String: Any]?
    @State private var loading = true
    @State private var error: String?
    @State private var isFav = false
    @State private var favCount = 0
    @State private var favBusy = false
    @State private var showAuth = false

    var body: some View {
        AppPage(title: place?["title"] as? String ?? "Detay") {
            ScrollView {
                if loading && place == nil {
                    ProgressView().padding(.vertical, 40)
                } else if let error {
                    VStack(spacing: 12) {
                        Text(error).foregroundStyle(AppColors.coral)
                        Button("Tekrar dene") { Task { await load() } }
                    }
                    .padding()
                } else if let place {
                    VStack(alignment: .leading, spacing: 16) {
                        heroImage(place)
                        Text(place["title"] as? String ?? "")
                            .font(.title.weight(.black))
                            .foregroundStyle(AppColors.ink)
                        if !metaLine(for: place).isEmpty {
                            Text(metaLine(for: place))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppColors.muted)
                        }
                        if let address = place["address"] as? String, !address.isEmpty {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundStyle(AppColors.accentDeep)
                                Text(address)
                                    .font(.subheadline)
                                    .foregroundStyle(AppColors.ink)
                            }
                        }
                        if let maps = mapsURL(for: place) {
                            Link(destination: maps) {
                                Label("Haritada aç", systemImage: "map.fill")
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                        Text(bodyText(for: place))
                            .font(.body)
                            .foregroundStyle(AppColors.ink)
                            .lineSpacing(4)
                        HStack {
                            Button {
                                Task { await toggleFavorite() }
                            } label: {
                                Label("\(favCount)", systemImage: isFav ? "heart.fill" : "heart")
                                    .font(.headline)
                                    .foregroundStyle(isFav ? AppColors.coral : AppColors.muted)
                            }
                            .disabled(favBusy)
                            Spacer()
                        }
                        if let url = webURL(for: place) {
                            Link(destination: url) {
                                Label("Web sayfasında aç", systemImage: "arrow.up.right.square.fill")
                                    .font(.headline.weight(.heavy))
                                    .foregroundStyle(AppColors.lime)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(RoundedRectangle(cornerRadius: AppRadii.md).fill(AppColors.nav))
                            }
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 24)
                }
            }
            .refreshable { await load() }
        }
        .task { await load() }
        .sheet(isPresented: $showAuth) { AuthFlowView() }
    }

    @ViewBuilder
    private func heroImage(_ place: [String: Any]) -> some View {
        if let img = place["img_url"] as? String, !img.isEmpty {
            RemoteImage(url: img, placeholder: "photo")
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: AppRadii.lg, style: .continuous))
                .cardShadow()
        }
    }

    private func metaLine(for place: [String: Any]) -> String {
        [
            place["category_label"] as? String,
            place["ilce"] as? String,
            place["starts_at_label"] as? String ?? place["starts_at"] as? String
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: " · ")
    }

    private func bodyText(for place: [String: Any]) -> String {
        let blurb = (place["blurb"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let body = (place["body"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !blurb.isEmpty ? blurb : body
    }

    private func mapsURL(for place: [String: Any]) -> URL? {
        if let lat = place["lat"] as? Double, let lng = place["lng"] as? Double {
            return URL(string: "https://maps.apple.com/?ll=\(lat),\(lng)")
        }
        if let lat = place["lat"] as? Int, let lng = place["lng"] as? Int {
            return URL(string: "https://maps.apple.com/?ll=\(lat),\(lng)")
        }
        return nil
    }

    private func webURL(for place: [String: Any]) -> URL? {
        let path = (place["path"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let s = (place["slug"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? slug
        let rel = path.isEmpty ? "/yer/\(s)" : path
        return URL(string: rel, relativeTo: AppConfig.siteBase)?.absoluteURL
    }

    @MainActor
    private func load() async {
        loading = true
        error = nil
        defer { loading = false }
        do {
            let p = try await auth.apiClient().placeDetail(slug: slug)
            place = p
            isFav = p["is_fav"] as? Bool ?? false
            favCount = JSONValue.int(p["fav_count"])
        } catch {
            self.error = error.localizedDescription
        }
    }

    @MainActor
    private func toggleFavorite() async {
        guard auth.isLoggedIn else { showAuth = true; return }
        favBusy = true
        defer { favBusy = false }
        do {
            let (fav, count) = try await auth.apiClient().togglePlaceFavorite(slug: slug)
            isFav = fav
            favCount = count
        } catch {
            self.error = error.localizedDescription
        }
    }
}
