import SwiftUI

struct AuthFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthStore
    @State private var mode: AuthMode = .welcome
    @State private var resetEmail = ""

    enum AuthMode {
        case welcome, login, register, forgot
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.bg.ignoresSafeArea()
                switch mode {
                case .welcome:
                    WelcomeAuthView(
                        onLogin: { mode = .login },
                        onRegister: { mode = .register }
                    )
                case .login:
                    LoginView(
                        onSuccess: { dismiss() },
                        onForgot: { email in
                            resetEmail = email
                            mode = .forgot
                        }
                    )
                case .register:
                    RegisterView(onSuccess: { dismiss() })
                case .forgot:
                    ForgotPasswordView(
                        initialEmail: resetEmail,
                        onBack: { mode = .login }
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
                if mode != .welcome {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Geri") { mode = .welcome }
                    }
                }
            }
        }
    }
}

private struct WelcomeAuthView: View {
    let onLogin: () -> Void
    let onRegister: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("BursaApp")
                .font(.largeTitle.bold())
                .foregroundStyle(AppColors.ink)
            Text("Etkinlik paylaş, mekan keşfet, topluluğa katıl.")
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.muted)
                .padding(.horizontal, 32)
            Spacer()
            VStack(spacing: 12) {
                Button(action: onLogin) {
                    Text("Giriş yap")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.accentDeep)
                Button(action: onRegister) {
                    Text("Hesap oluştur")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

struct LoginView: View {
    @EnvironmentObject private var auth: AuthStore
    @State private var email = ""
    @State private var password = ""
    @State private var error: String?
    let onSuccess: () -> Void
    let onForgot: (String) -> Void

    var body: some View {
        Form {
            Section {
                TextField("E-posta", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                SecureField("Şifre", text: $password)
            }
            Section {
                Button("Şifremi unuttum") { onForgot(email) }
                    .foregroundStyle(AppColors.accentDeep)
            }
            if let error {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }
            Section {
                Button(auth.loading ? "Giriş yapılıyor…" : "Giriş yap") {
                    Task { await submit() }
                }
                .disabled(auth.loading || email.isEmpty || password.isEmpty)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppColors.bg)
        .navigationTitle("Giriş")
        .onAppear {
            if email.isEmpty, let saved = auth.savedEmail { email = saved }
        }
    }

    private func submit() async {
        error = nil
        do {
            try await auth.login(email: email, password: password)
            onSuccess()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct ForgotPasswordView: View {
    @EnvironmentObject private var auth: AuthStore
    @State private var email: String
    @State private var error: String?
    @State private var success: String?
    @State private var loading = false
    let onBack: () -> Void

    init(initialEmail: String, onBack: @escaping () -> Void) {
        _email = State(initialValue: initialEmail)
        self.onBack = onBack
    }

    var body: some View {
        Form {
            Section {
                Text("Kayıtlı e-posta adresine yeni geçici şifre gönderilir.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.muted)
            }
            Section {
                TextField("E-posta", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            if let success {
                Section {
                    Text(success).foregroundStyle(AppColors.accentDeep)
                }
            }
            if let error {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }
            Section {
                Button(loading ? "Gönderiliyor…" : "Yeni şifre gönder") {
                    Task { await submit() }
                }
                .disabled(loading || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppColors.bg)
        .navigationTitle("Şifremi unuttum")
    }

    private func submit() async {
        error = nil
        success = nil
        loading = true
        defer { loading = false }
        do {
            let msg = try await auth.apiClient().forgotPassword(email: email)
            success = msg
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct RegisterView: View {
    @EnvironmentObject private var auth: AuthStore
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var error: String?
    let onSuccess: () -> Void

    var body: some View {
        Form {
            Section {
                TextField("Ad", text: $name)
                TextField("E-posta", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                SecureField("Şifre (min 6)", text: $password)
            }
            if let error {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }
            Section {
                Button(auth.loading ? "Kaydediliyor…" : "Kayıt ol") {
                    Task { await submit() }
                }
                .disabled(auth.loading || name.isEmpty || email.isEmpty || password.count < 6)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppColors.bg)
        .navigationTitle("Kayıt")
    }

    private func submit() async {
        error = nil
        do {
            try await auth.register(name: name, email: email, password: password)
            onSuccess()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
