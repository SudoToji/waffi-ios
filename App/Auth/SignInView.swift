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
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Waffi").font(.largeTitle.bold())
                    Text("Sign in with your Waffi account.").foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                    HStack {
                        Group {
                            if showPassword {
                                TextField("Password", text: $password)
                            } else {
                                SecureField("Password", text: $password)
                            }
                        }
                        .textContentType(.password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { Task { await submit() } }
                        Button(passwordToggle, systemImage: showPassword ? "eye.slash" : "eye") {
                            showPassword.toggle()
                        }
                        .labelStyle(.iconOnly)
                    }
                    if ServerOrigin.canChange {
                        TextField("Server", text: $server, prompt: Text(verbatim: ServerOrigin.production.absoluteString))
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textFieldStyle(.roundedBorder)
                            .environment(\.layoutDirection, .leftToRight)
                        Text("For testing only. Leave empty for the real server.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                if let text = message ?? session.notice {
                    Text(text)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await submit() }
                } label: {
                    if working { ProgressView() } else { Text("Sign in").frame(maxWidth: .infinity) }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!canSubmit)

                Link("Forgot password?", destination: ServerOrigin.current.appending(path: "\(ServerOrigin.language)/forgot-password"))
                Button("About") { showAbout = true }
                    .font(.footnote)
            }
            .padding(24)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $showAbout) {
            NavigationStack { AboutView() }
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
