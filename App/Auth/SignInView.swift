import SwiftUI

/// Email and password of a Waffi account (Owner, Manager or Staff Member). No sign-up and no reset here: the website does those.
struct SignInView: View {
    let session: SessionModel
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var server = ServerOrigin.saved
    @State private var message: String?
    @State private var working = false
    @State private var showAbout = false

    private var passwordToggle: LocalizedStringKey { showPassword ? "Hide password" : "Show password" }
    private var canSubmit: Bool { !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty && !working }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                form.padding(.top, 36)
            }
            .padding(.horizontal, 24)
            .padding(.top, 56)
            .padding(.bottom, 24)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollBounceBehavior(.basedOnSize)
        .background(Theme.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) { footer }
        .sheet(isPresented: $showAbout) {
            NavigationStack { AboutView() }
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            Text(verbatim: "W")
                .font(.system(size: 40, weight: .heavy))
                .foregroundStyle(Theme.onAccent)
                .frame(width: 72, height: 72)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 20))
                .accessibilityHidden(true)
            Text("Waffi for staff")
                .font(.title.weight(.heavy))
                .foregroundStyle(Theme.text)
                .accessibilityAddTraits(.isHeader)
            Text("Sign in with your Waffi dashboard account")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
        }
        .multilineTextAlignment(.center)
    }

    private var form: some View {
        VStack(spacing: 14) {
            labeled("Email") {
                TextField("Email", text: $email, prompt: Text(verbatim: "name@example.com"))
                    .textContentType(.username)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .waffiField()
            }
            labeled("Password") {
                Group {
                    if showPassword {
                        TextField("Password", text: $password, prompt: Text(verbatim: ""))
                    } else {
                        SecureField("Password", text: $password, prompt: Text(verbatim: ""))
                    }
                }
                .textContentType(.password)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit { Task { await submit() } }
                .padding(.trailing, 34)
                .waffiField()
                .overlay(alignment: .trailing) {
                    Button(passwordToggle, systemImage: showPassword ? "eye.slash" : "eye") {
                        showPassword.toggle()
                    }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(Theme.secondaryText)
                    .frame(width: 44, height: 44)
                    .padding(.trailing, 4)
                }
            }

            Link("Forgot password?", destination: ServerOrigin.current.appending(path: "\(ServerOrigin.language)/forgot-password"))
                .font(.subheadline.weight(.semibold))
                .frame(minHeight: 44)
                .frame(maxWidth: .infinity, alignment: .trailing)

            if let text = message ?? session.notice {
                Text(text)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await submit() }
            } label: {
                if working { ProgressView().tint(Theme.onAccent) } else { Text("Sign in") }
            }
            .buttonStyle(.waffiPrimary)
            .disabled(!canSubmit)

            if ServerOrigin.canChange {
                labeled("Server") {
                    TextField("Server", text: $server, prompt: Text(verbatim: ServerOrigin.production.absoluteString))
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .environment(\.layoutDirection, .leftToRight)
                        .waffiField()
                }
                Text("For testing only. Leave empty for the real server.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 4) {
            Text("Only for Business teams. Customers just scan the QR.")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
            Button("About") { showAbout = true }
                .font(.footnote)
                .frame(minHeight: 44)
        }
        .padding(.horizontal, 24)
    }

    private func labeled<Field: View>(_ title: LocalizedStringKey, @ViewBuilder field: () -> Field) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.text)
                .accessibilityHidden(true)
            field()
        }
    }

    private func submit() async {
        guard canSubmit else { return }
        message = nil
        if ServerOrigin.canChange {
            guard ServerOrigin.save(server) else {
                message = String(localized: "Enter an address that starts with https://")
                return
            }
            server = ServerOrigin.saved
        }
        working = true
        defer { working = false }
        do {
            try await session.signIn(email: email.trimmingCharacters(in: .whitespaces), password: password)
        } catch let error as ApiError {
            message = error.message
        } catch {}
    }
}
