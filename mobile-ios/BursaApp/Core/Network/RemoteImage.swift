import SwiftUI

struct RemoteImage: View {
    let url: String
    var placeholder: String = "photo"

    var body: some View {
        Group {
            if let u = resolvedURL {
                AsyncImage(url: u) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        placeholderView
                    case .empty:
                        ProgressView()
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }
        }
        .background(AppColors.bgSoft)
    }

    private var placeholderView: some View {
        Image(systemName: placeholder)
            .font(.title2)
            .foregroundStyle(AppColors.muted.opacity(0.5))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
