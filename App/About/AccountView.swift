import SwiftUI

/// The account sheet of the staff Pager: who is signed in, Sign out, the privacy policy, support, and where an account is deleted.
struct AccountView: View {
    let session: SessionModel
    let account: AppAccount
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Appearance.storageKey) private var appearance = Appearance.system

    private var version: String {
        let info = Bundle.main.infoDictionary
        return "\(info?["CFBundleShortVersionString"] as? String ?? "") (\(info?["CFBundleVersion"] as? String ?? ""))"
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Email") { Text(verbatim: account.user.email) }
                LabeledContent("Business") { Text(verbatim: account.business.name) }
            }
            Section {
                Picker("Appearance", selection: $appearance) {
                    ForEach(Appearance.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Appearance")
            }
            Section {
                Button("Sign out", role: .destructive) {
                    dismiss()
                    Task { await session.signOut() }
                }
            }
            Section {
                Link("Privacy policy", destination: ServerOrigin.production.appending(path: "\(ServerOrigin.language)/privacy"))
                Link("Support", destination: URL(string: "mailto:contact@waffieg.com")!)
                LabeledContent("Version", value: version)
            }
            Section {
                Link("Open the Waffi website", destination: ServerOrigin.current.appending(path: "\(ServerOrigin.language)/login"))
            } header: {
                Text("Delete account")
            } footer: {
                Text("Accounts are managed on the Waffi website by the Business Owner. To delete your account, ask your Owner, or open the website and sign in as the Owner.")
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}
