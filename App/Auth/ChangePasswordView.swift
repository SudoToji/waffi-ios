import SwiftUI

/// The Temporary Password an Owner or Manager set must be replaced before anything else works. Styled like `SignInView`.
struct ChangePasswordView: View {
    let session: SessionModel
    @State private var current = ""
    @State private var new = ""
    @State private var showPasswords = false
    @State private var message: String?
    @State private var working = false

    private var canSubmit: Bool { !current.isEmpty && !new.isEmpty && !working }
    private var passwordToggle: LocalizedStringKey { showPasswords ? "Hide password" : "Show password" }

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
    }

    private var header: some View {
        VStack(spacing: 14) {
            WaffiMark(size: 72)
            Text("Choose your own password")
                .font(.title.weight(.heavy))
                .foregroundStyle(Theme.text)
                .accessibilityAddTraits(.isHeader)
            Text("Replace your temporary password before continuing.")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
        }
        .multilineTextAlignment(.center)
    }

    private var form: some View {
        VStack(spacing: 14) {
            labeled("Current password") {
                passwordField("Current password", text: $current, content: .password)
            }
            labeled("New password") {
                passwordField("New password", text: $new, content: .newPassword)
                    .onSubmit { Task { await submit() } }
            }
            Text("At least 8 characters, with an uppercase letter, a lowercase letter and a number.")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let message {
                Text(message)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await submit() }
            } label: {
                if working { ProgressView().tint(Theme.onAccent) } else { Text("Save password") }
            }
            .buttonStyle(.waffiPrimary)
            .disabled(!canSubmit)
            .padding(.top, 6)

            Button("Sign out", role: .destructive) { Task { await session.signOut() } }
                .font(.subheadline.weight(.semibold))
                .frame(minHeight: 44)
        }
    }

    /// A password box with the show/hide eye, like the sign-in screen's.
    private func passwordField(_ title: LocalizedStringKey, text: Binding<String>, content: UITextContentType) -> some View {
        Group {
            if showPasswords {
                TextField(title, text: text, prompt: Text(verbatim: ""))
            } else {
                SecureField(title, text: text, prompt: Text(verbatim: ""))
            }
        }
        .textContentType(content)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .padding(.trailing, 34)
        .waffiField()
        .overlay(alignment: .trailing) {
            Button(passwordToggle, systemImage: showPasswords ? "eye.slash" : "eye") {
                showPasswords.toggle()
            }
            .labelStyle(.iconOnly)
            .foregroundStyle(Theme.secondaryText)
            .frame(width: 44, height: 44)
            .padding(.trailing, 4)
        }
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
        working = true
        defer { working = false }
        do {
            try await session.changePassword(current: current, new: new)
        } catch let error as ApiError {
            message = error.message
        } catch {}
    }
}
