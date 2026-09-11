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
                    Text(error).foregroundStyle(AppColors.coral).padding()
                } else if let place {
                    VStack(alignment: .leading, spacing: 12) {
                        if let img = place["img_url"] as? String, !img.isEmpty {
                            RemoteImage(url: img, placeholder: "photo")
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadii.md))
                        }
                        if let ilce = place["ilce"] as? String, !ilce.isEmpty {
                            Text(ilce).font(.caption.weight(.semibold)).foregroundStyle(AppColors.accentDeep)
                        }
                        if let blurb = place["blurb"] as? String, !blurb.isEmpty {
                            Text(blurb).foregroundStyle(AppColors.ink)
                        }
                        if let body = place["body"] as? String, !body.isEmpty {
                            Text(body).font(.subheadline).foregroundStyle(AppColors.muted)
                        }
                        HStack {
                            Button {
                                Task { await toggleFavorite() }
                            } label: {
                                Label("\(favCount)", systemImage: isFav ? "heart.fill" : "heart")
                                    .foregroundStyle(isFav ? AppColors.coral : AppColors.muted)
                            }
                            .disabled(favBusy)
                            Spacer()
                            if let url = webURL(for: place) {
                                Link("Web'de aç", destination: url)
                                    .font(.headline)
                                    .foregroundStyle(AppColors.accentDeep)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .refreshable { await load() }
        }
        .task { await load() }
        .sheet(isPresented: $showAuth) { AuthFlowView() }
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
