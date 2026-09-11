import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var auth: AuthStore
    @Binding var tabSelection: ShellTab
    @Binding var navPath: NavigationPath

    @State private var menu: [MenuGroup] = []
    @State private var loadingMenu = true
    @State private var showAuth = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                quickTiles
                if loadingMenu {
                    ProgressView().padding()
                } else {
                    ForEach(menu) { group in
                        menuBlock(group)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .refreshable { await refresh() }
        .task { await refresh() }
        .sheet(isPresented: $showAuth) { AuthFlowView() }
    }

    private var header: some View {
        VStack(spacing: 12) {
            if auth.isLoggedIn, let user = auth.user {
                RemoteImage(url: user.avatarUrl, placeholder: "person.crop.circle.fill")
                    .frame(width: 96, height: 96)
                    .clipShape(Circle())
                Text(user.displayName).font(.title2.bold())
                Text("\(user.points) puan · Bursa rehberi")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.muted)
                Button("Çıkış yap", role: .destructive) {
                    Task { await auth.logout(); await refresh() }
                }
                .buttonStyle(.bordered)
                Button("Hesap ayarları") {
                    navPath.append(AppNavRoute.settings)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.nav)
            } else {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 56))
                    .foregroundStyle(AppColors.accentDeep)
                Text("Giriş").font(.title2.bold())
                Text("Hesabınla etkinlik ekle, beğeni ve puan biriktir.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppColors.muted)
                Button("Giriş yap / Kayıt ol") { showAuth = true }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.nav)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var quickTiles: some View {
        HStack(spacing: 10) {
            quickTile("Gez", icon: "mountain.2.fill") {
                navPath.append(MenuDestination(link: MenuLink(label: "Gezilecek", path: "/gezilecek", category: nil)))
            }
            quickTile("Liderler", icon: "trophy.fill") {
                navPath.append(MenuDestination(link: MenuLink(label: "Liderler", path: "/liderler", category: nil)))
            }
            quickTile("Partner", icon: "person.3.fill") {
                navPath.append(MenuDestination(link: MenuLink(label: "Partner", path: "/arkadas-ara", category: nil)))
            }
            quickTile("Eczane", icon: "cross.case.fill") {
                navPath.append(MenuDestination(link: MenuLink(label: "Nöbetçi", path: "/nobetci-eczaneler", category: nil)))
            }
        }
    }

    private func quickTile(_ label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.title3)
                Text(label).font(.caption.weight(.bold))
            }
            .foregroundStyle(AppColors.accentDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: AppRadii.md).fill(AppColors.accentDeep.opacity(0.15)))
        }
        .buttonStyle(.plain)
    }

    private func menuBlock(_ group: MenuGroup) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(group.title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppColors.muted)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            ForEach(group.items) { item in
                Button {
                    AppMenuPath.open(item, tabSelection: $tabSelection, navigationPath: $navPath)
                } label: {
                    HStack {
                        Text(item.label)
                            .foregroundStyle(AppColors.ink)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppColors.muted)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                if item.id != group.items.last?.id {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: AppRadii.lg).fill(AppColors.card))
    }

    @MainActor
    private func refresh() async {
        loadingMenu = true
        defer { loadingMenu = false }
        if auth.isLoggedIn {
            await auth.refreshUser()
        }
        if let groups = try? await auth.apiClient().mobileMenu() {
            menu = groups
        }
    }
}
