import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var auth: AuthStore
    @State private var showAuth = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if auth.isLoggedIn, let user = auth.user {
                    loggedIn(user)
                } else {
                    guest
                }
            }
            .padding(24)
        }
        .sheet(isPresented: $showAuth) {
            AuthFlowView()
        }
    }

    private func loggedIn(_ user: AuthUser) -> some View {
        VStack(spacing: 16) {
            RemoteImage(url: user.avatarUrl, placeholder: "person.crop.circle.fill")
                .frame(width: 88, height: 88)
                .clipShape(Circle())
            Text(user.displayName)
                .font(.title2.bold())
                .foregroundStyle(AppColors.ink)
            Text("\(user.points) puan")
                .font(.subheadline)
                .foregroundStyle(AppColors.accentDeep)
            if !user.email.isEmpty {
                Text(user.email)
                    .font(.caption)
                    .foregroundStyle(AppColors.muted)
            }
            Button("Çıkış yap", role: .destructive) {
                Task { await auth.logout() }
            }
            .buttonStyle(.bordered)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
    }

    private var guest: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(AppColors.accentDeep)
            Text("Profilin")
                .font(.title2.bold())
            Text("Giriş yaparak etkinlik ekleyebilir, beğeni ve puan biriktirebilirsin.")
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.muted)
            Button("Giriş yap / Kayıt ol") {
                showAuth = true
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.accentDeep)
        }
    }
}
