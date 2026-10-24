import SwiftUI

/// No Card chosen yet: the camera, the search field, the Manual Code row and the Customers served lately.
struct FindScreen: View {
    let model: EarnModel
    let session: SessionModel
    let account: AppAccount
    @State private var query = ""
    @State private var showManualCode = false

    private var searching: Bool { !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                EarnHeader(model: model, session: session, account: account)
                RecoveryPanel(model: model)
                ReceiptBanner(model: model)
                ScanPanel(busy: model.searching) { text in
                    Task { await model.lookup(text) }
                }
                if model.codeInvalid || model.lookupError != nil { lookupMessage }
                searchField
                manualCodeRow
                if searching {
                    SearchResults(model: model, query: query)
                } else {
                    RecentList(recent: model.recent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $showManualCode) {
            ManualCodeSheet(model: model)
        }
    }

    private var lookupMessage: some View {
        Text(model.lookupError?.message ?? String(localized: "Enter six card digits, a Waffi QR code, or a phone number. Local numbers use Egypt; include +country code for other countries."))
            .font(.subheadline)
            .foregroundStyle(Theme.warning)
            .accessibilityAddTraits(.updatesFrequently)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(Theme.secondaryText).accessibilityHidden(true)
            TextField("Search by phone or name", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .foregroundStyle(Theme.text)
            if searching {
                Button { query = "" } label: {
                    Label("Clear", systemImage: "xmark.circle.fill").labelStyle(.iconOnly)
                        .foregroundStyle(Theme.secondaryText)
                        .frame(width: 44, height: 44)
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 50)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border))
        .task(id: query) {
            // The website waits a quarter second after the last key.
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            await model.search(query)
        }
    }

    private var manualCodeRow: some View {
        Button { showManualCode = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "keyboard")
                    .foregroundStyle(Theme.accent)
                    .frame(width: 44, height: 44)
                    .background(Theme.accentTint, in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Enter Manual Code").font(.body.weight(.bold)).foregroundStyle(Theme.text)
                    Text("The short code printed under the Card's QR").font(.footnote).foregroundStyle(Theme.secondaryText)
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                Image(systemName: "chevron.forward").font(.footnote.weight(.semibold)).foregroundStyle(Theme.secondaryText)
                    .accessibilityHidden(true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

/// "Recently served": this phone's last Operations.
private struct RecentList: View {
    let recent: [RecentServe]

    var body: some View {
        if !recent.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Recently served")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.secondaryText)
                    .accessibilityAddTraits(.isHeader)
                VStack(spacing: 0) {
                    ForEach(recent) { item in
                        if item.id != recent.first?.id { Rectangle().fill(Theme.border).frame(height: 1 / 3) }
                        HStack(spacing: 12) {
                            Avatar(name: item.customerName, size: 40)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(verbatim: item.customerName).font(.body.weight(.bold)).foregroundStyle(Theme.text)
                                Text(verbatim: item.summary).font(.footnote).foregroundStyle(Theme.secondaryText)
                            }
                            Spacer(minLength: 8)
                            Text(item.date, format: .relative(presentation: .numeric, unitsStyle: .abbreviated))
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryText)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .accessibilityElement(children: .combine)
                    }
                }
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
            }
            .padding(.top, 4)
        }
    }
}

/// A round tile with the Customer's initials.
struct Avatar: View {
    let name: String
    var size: CGFloat = 44

    private var initials: String {
        String(name.split(separator: " ").prefix(2).compactMap(\.first)).uppercased()
    }

    var body: some View {
        Text(verbatim: initials)
            .font(.system(size: size * 0.36, weight: .bold))
            .foregroundStyle(Theme.accent)
            .frame(width: size, height: size)
            .background(Theme.accentTint, in: .circle)
            .accessibilityHidden(true)
    }
}
