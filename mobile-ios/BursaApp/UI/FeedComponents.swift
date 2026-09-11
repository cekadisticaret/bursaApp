import SwiftUI

struct FeedSearchBar: View {
    let onSearchTap: () -> Void
    let onFilterTap: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onSearchTap) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(AppColors.muted)
                    Text("Mekan, etkinlik, mahalle…")
                        .foregroundStyle(AppColors.muted)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            Button(action: onFilterTap) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.lime)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 14).fill(AppColors.nav))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: AppRadii.lg)
                .fill(AppColors.card)
                .cardShadow()
        )
    }
}

struct FeedFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onPick: (String, String) -> Void
    let onHotels: () -> Void

    private let options: [(String, String, String)] = [
        ("Etkinlikler", "event", "calendar"),
        ("Yeme-içme", "food", "fork.knife"),
        ("Gezilecek", "visit", "mountain.2.fill"),
        ("Konserler", "concert", "music.note"),
        ("Tiyatro", "theater", "theatermasks.fill"),
        ("Sinema", "cinema", "film"),
        ("Oteller", "hotel", "bed.double.fill"),
        ("Eğlence", "fun", "party.popper.fill"),
        ("Gece hayatı", "nightlife", "moon.stars.fill"),
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Mekan listesine git")
                        .font(.caption)
                        .foregroundStyle(AppColors.muted)
                }
                ForEach(options, id: \.0) { label, key, icon in
                    Button {
                        dismiss()
                        if key == "hotel" { onHotels() }
                        else if key == "food" || key == "visit" || key == "event" {
                            let title = label
                            onPick(title, key)
                        } else {
                            onPick(label, key)
                        }
                    } label: {
                        Label(label, systemImage: icon)
                            .font(.body.weight(.bold))
                    }
                }
            }
            .navigationTitle("Kategori filtrele")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
