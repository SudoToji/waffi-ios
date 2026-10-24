import SwiftUI

/// The Temporary Password an Owner or Manager set must be replaced before anything else works.
struct ChangePasswordView: View {
    let session: SessionModel
    @State private var current = ""
    @State private var new = ""
    @State private var message: String?
    @State private var working = false

    private var canSubmit: Bool { !current.isEmpty && !new.isEmpty && !working }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Choose your own password").font(.title2.bold())
                    Text("Replace your temporary password before continuing.").foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    SecureField("Current password", text: $current)
                        .textContentType(.password)
                        .textFieldStyle(.roundedBorder)
                    SecureField("New password", text: $new)
                        .textContentType(.newPassword)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { Task { await submit() } }
                    Text("At least 8 characters, with an uppercase letter, a lowercase letter and a number.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let message {
                    Text(message).foregroundStyle(.red).multilineTextAlignment(.center)
                }

                Button {
                    Task { await submit() }
                } label: {
                    if working { ProgressView() } else { Text("Save password").frame(maxWidth: .infinity) }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!canSubmit)

                Button("Sign out", role: .destructive) { Task { await session.signOut() } }
                    .font(.footnote)
            }
            .padding(24)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
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
