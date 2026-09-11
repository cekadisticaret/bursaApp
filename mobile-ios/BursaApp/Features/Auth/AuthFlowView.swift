import SwiftUI

struct AuthFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthStore
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            AuthWelcomeView(
                onStart: { path.append(AuthRoute.login) },
                onRegister: { path.append(AuthRoute.register) },
                onClose: { dismiss() }
            )
            .navigationDestination(for: AuthRoute.self) { route in
                switch route {
                case .login:
                    AuthLoginView(
                        onSuccess: { dismiss() },
                        onForgot: { email in path.append(AuthRoute.forgot(email)) },
                        onRegister: { path.append(AuthRoute.register) }
                    )
                case .register:
                    AuthRegisterView(onSuccess: { dismiss() })
                case .forgot(let email):
                    AuthForgotPasswordView(initialEmail: email)
                }
            }
        }
    }
}

private enum AuthRoute: Hashable {
    case login
    case register
    case forgot(String)
}

// MARK: - Shared auth UI

private struct AuthScreenShell<Content: View>: View {
    let title: String
    let onBack: (() -> Void)?
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(AppColors.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(title)
        .toolbar {
            if let onBack {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppColors.ink)
                    }
                }
            }
        }
    }
}

private struct AuthHeadline: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(AppColors.ink)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppColors.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 28)
    }
}

private struct AuthField: View {
    let label: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType?
    var isSecure = false
    var showToggle = false
    @Binding var reveal: Bool

    init(
        label: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default,
        contentType: UITextContentType? = nil,
        isSecure: Bool = false,
        reveal: Binding<Bool> = .constant(false)
    ) {
        self.label = label
        _text = text
        self.keyboard = keyboard
        self.contentType = contentType
        self.isSecure = isSecure
        self.showToggle = isSecure
        _reveal = reveal
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppColors.muted)
            HStack {
                Group {
                    if isSecure && !reveal {
                        SecureField("", text: $text)
                    } else {
                        TextField("", text: $text)
                            .keyboardType(keyboard)
                            .textContentType(contentType)
                            .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                            .autocorrectionDisabled()
                    }
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(AppColors.ink)
                if showToggle {
                    Button {
                        reveal.toggle()
                    } label: {
                        Image(systemName: reveal ? "eye.slash" : "eye")
                            .foregroundStyle(AppColors.muted)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: AppRadii.md, style: .continuous)
                    .fill(AppColors.card)
                    .shadow(color: AppColors.ink.opacity(0.06), radius: 12, y: 6)
            )
        }
    }
}

private struct AuthPrimaryButton: View {
    let title: String
    let loading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(loading ? "\(title)…" : title)
                .font(.headline.weight(.bold))
                .foregroundStyle(AppColors.lime)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: AppRadii.md, style: .continuous)
                        .fill(AppColors.nav)
                )
        }
        .disabled(loading)
        .buttonStyle(.plain)
    }
}

private struct AuthInlineLink: View {
    let prefix: String
    let actionText: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(prefix).foregroundStyle(AppColors.muted)
                Text(actionText)
                    .fontWeight(.black)
                    .foregroundStyle(AppColors.nav)
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .padding(.top, 16)
    }
}

// MARK: - Welcome

private struct AuthWelcomeView: View {
    let onStart: () -> Void
    let onRegister: () -> Void
    let onClose: () -> Void

    var body: some View {
        ZStack {
            AppColors.welcomeBg.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Button(action: onClose) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.ink)
                }
                .padding(.top, 8)

                welcomeHeadline
                    .padding(.top, 8)

                Spacer(minLength: 24)

                AuthWelcomeIllustration()
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)

                Spacer(minLength: 24)

                Text("BursaApp ile şehrini tanı")
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(AppColors.nav)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Text("Restoran, gezi, etkinlik ve nöbetçi eczane — hepsi tek rehberde.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.muted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                    .frame(maxWidth: .infinity)

                Button(action: onStart) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(.white).frame(width: 34, height: 34)
                            Image(systemName: "play.fill")
                                .foregroundStyle(AppColors.nav)
                        }
                        Text("Başlayalım!")
                            .font(.system(size: 18, weight: .heavy))
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                    .background(Capsule().fill(AppColors.nav))
                }
                .buttonStyle(.plain)
                .padding(.top, 28)

                AuthInlineLink(prefix: "Hesabın yok mu?", actionText: "Kayıt ol", action: onRegister)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .navigationBarHidden(true)
    }

    private var welcomeHeadline: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Bursa'yı")
                .font(.system(size: 34, weight: .black))
                .foregroundStyle(AppColors.ink)
            Text("Keşfet")
                .font(.system(size: 34, weight: .black))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(AppColors.nav)
        }
        .lineSpacing(2)
    }
}

private struct AuthWelcomeIllustration: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 120, style: .continuous)
                .fill(AppColors.accentDeep.opacity(0.35))
                .frame(height: 72)
                .padding(.horizontal, 24)
                .frame(maxHeight: .infinity, alignment: .bottom)

            Circle()
                .fill(AppColors.lime.opacity(0.55))
                .overlay(Circle().stroke(AppColors.accentDeep, lineWidth: 3))
                .frame(width: 96, height: 96)
                .overlay {
                    Image(systemName: "figure.hiking")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(AppColors.nav)
                }
                .offset(y: 18)

            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(AppColors.amber)
                .frame(width: 72, height: 88)
                .overlay {
                    Image(systemName: "wind")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(AppColors.nav)
                }
                .offset(x: 48, y: -36)

            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(AppColors.coral.opacity(0.85))
                .offset(x: -72, y: -48)
        }
    }
}

// MARK: - Login

struct AuthLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthStore
    @State private var email = ""
    @State private var password = ""
    @State private var revealPassword = false
    @State private var error: String?
    let onSuccess: () -> Void
    let onForgot: (String) -> Void
    let onRegister: () -> Void

    var body: some View {
        AuthScreenShell(title: "Giriş yap", onBack: { dismiss() }) {
            AuthHeadline(
                title: "Hesabınla devam et",
                subtitle: "Beğeni, yorum ve etkinlik için giriş yap."
            )
            AuthField(label: "E-posta", text: $email, keyboard: .emailAddress, contentType: .emailAddress)
            AuthField(
                label: "Şifre",
                text: $password,
                contentType: .password,
                isSecure: true,
                reveal: $revealPassword
            )
            .padding(.top, 12)

            HStack {
                Spacer()
                Button("Şifremi unuttum") { onForgot(email) }
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(AppColors.nav)
            }
            .padding(.top, 8)

            if let error {
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.coral)
                    .padding(.top, 12)
            }

            AuthPrimaryButton(title: "Giriş yap", loading: auth.loading) {
                Task { await submit() }
            }
            .padding(.top, 24)
            .disabled(email.isEmpty || password.isEmpty)

            AuthInlineLink(prefix: "Hesabın yok mu?", actionText: "Kayıt ol", action: onRegister)
        }
        .onAppear {
            if email.isEmpty, let saved = auth.savedEmail { email = saved }
        }
    }

    private func submit() async {
        error = nil
        do {
            try await auth.login(email: email, password: password)
            await auth.refreshUser()
            onSuccess()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Register

struct AuthRegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthStore
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var revealPassword = false
    @State private var error: String?
    let onSuccess: () -> Void

    var body: some View {
        AuthScreenShell(title: "Kayıt ol", onBack: { dismiss() }) {
            AuthHeadline(
                title: "BursaApp'e katıl",
                subtitle: "Ücretsiz hesap — puan kazan, etkinlik paylaş."
            )
            AuthField(label: "Ad Soyad", text: $name, contentType: .name)
            AuthField(label: "E-posta", text: $email, keyboard: .emailAddress, contentType: .emailAddress)
                .padding(.top, 12)
            AuthField(
                label: "Şifre (en az 8 karakter)",
                text: $password,
                contentType: .newPassword,
                isSecure: true,
                reveal: $revealPassword
            )
            .padding(.top, 12)

            if let error {
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.coral)
                    .padding(.top, 12)
            }

            AuthPrimaryButton(title: "Hesap oluştur", loading: auth.loading) {
                Task { await submit() }
            }
            .padding(.top, 24)
            .disabled(name.isEmpty || email.isEmpty || password.count < 8)
        }
        .onAppear {
            if email.isEmpty, let saved = auth.savedEmail { email = saved }
        }
    }

    private func submit() async {
        error = nil
        do {
            try await auth.register(name: name, email: email, password: password)
            await auth.refreshUser()
            onSuccess()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Forgot password

struct AuthForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthStore
    @State private var email: String
    @State private var error: String?
    @State private var success: String?
    @State private var loading = false

    init(initialEmail: String) {
        _email = State(initialValue: initialEmail)
    }

    var body: some View {
        AuthScreenShell(title: "Şifremi unuttum", onBack: { dismiss() }) {
            AuthHeadline(
                title: "Yeni şifre e-posta ile",
                subtitle: "Kayıtlı e-posta adresine yeni geçici şifre gönderilir. Giriş yaptıktan sonra profilden değiştirebilirsin."
            )
            AuthField(label: "E-posta", text: $email, keyboard: .emailAddress, contentType: .emailAddress)

            if let error {
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.coral)
                    .padding(.top, 12)
            }

            if let success {
                Text(success)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.ink)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadii.md)
                            .fill(AppColors.accentDeep.opacity(0.12))
                    )
                    .padding(.top, 12)
            }

            AuthPrimaryButton(title: "Yeni şifre gönder", loading: loading) {
                Task { await submit() }
            }
            .padding(.top, 24)
            .disabled(loading || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func submit() async {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("@") else {
            error = "Geçerli bir e-posta gir"
            success = nil
            return
        }
        error = nil
        success = nil
        loading = true
        defer { loading = false }
        do {
            success = try await auth.apiClient().forgotPassword(email: trimmed)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// Geriye uyumluluk — eski adlar
typealias LoginView = AuthLoginView
typealias RegisterView = AuthRegisterView
typealias ForgotPasswordView = AuthForgotPasswordView
