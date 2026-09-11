import SwiftUI

struct DestinationCard: View {
    let place: PlaceItem
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(alignment: .top, spacing: 12) {
                RemoteImage(url: place.imgUrl, placeholder: "photo")
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadii.sm, style: .continuous))
                VStack(alignment: .leading, spacing: 6) {
                    Text(place.title)
                        .font(.headline)
                        .foregroundStyle(AppColors.ink)
                        .multilineTextAlignment(.leading)
                    if !place.ilce.isEmpty {
                        Text(place.ilce)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColors.accentDeep)
                    }
                    if !place.blurb.isEmpty {
                        Text(place.blurb)
                            .font(.caption)
                            .foregroundStyle(AppColors.muted)
                            .lineLimit(2)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: AppRadii.md, style: .continuous)
                    .fill(AppColors.card)
                    .shadow(color: AppColors.ink.opacity(0.06), radius: 8, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
}

struct AppPage<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .background(AppColors.bg.ignoresSafeArea())
    }
}

struct LoadingStateView: View {
    let loading: Bool
    let error: String?
    let empty: Bool
    let emptyText: String

    var body: some View {
        if loading {
            ProgressView().frame(maxWidth: .infinity).padding(.vertical, 40)
        } else if let error, !error.isEmpty {
            Text(error).foregroundStyle(AppColors.coral).padding()
        } else if empty {
            Text(emptyText).foregroundStyle(AppColors.muted).padding(.vertical, 40)
        }
    }
}

struct PlaceListSection: View {
    let places: [PlaceItem]

    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(places) { place in
                NavigationLink(value: place.detailSlug) {
                    DestinationCard(place: place)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
