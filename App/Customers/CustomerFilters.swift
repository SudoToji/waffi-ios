import SwiftUI

/// The tier filter and the Joining Branch chips above the list.
struct CustomerFilters: View {
    @Bindable var model: CustomersModel

    var body: some View {
        VStack(spacing: 0) {
            if model.tiersOn { tierRow }
            if model.showJoining, let counts = model.counts { joiningRow(counts) }
        }
    }

    private var tierRow: some View {
        chips {
            FilterChip(title: String(localized: "All"), selected: model.tier == .all) { model.tier = .all }
            FilterChip(title: String(localized: "Loyal, no tier"), selected: model.tier == .loyalNoTier) {
                model.tier = .loyalNoTier
            }
            if model.canSetTier {
                FilterChip(title: String(localized: "Quiet members"), selected: model.tier == .quiet) { model.tier = .quiet }
            }
            ForEach(model.tiers) { tier in
                FilterChip(title: tier.displayName, selected: model.tier == .tier(tier.id)) { model.tier = .tier(tier.id) }
            }
        }
    }

    private func joiningRow(_ counts: JoiningBranchCounts) -> some View {
        chips {
            joiningChip(String(localized: "All"), count: counts.total, value: "")
            ForEach(counts.branches) { branch in joiningChip(branch.name, count: branch.count, value: branch.branchId) }
            joiningChip(String(localized: "Online"), count: counts.online, value: "online")
            joiningChip(String(localized: "Not recorded"), count: counts.notRecorded, value: "none")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Joining Branch"))
    }

    private func joiningChip(_ title: String, count: Int, value: String) -> some View {
        FilterChip(title: "\(title) \(count.formatted())", selected: model.joining == value) { model.joining = value }
    }

    private func chips<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) { content() }.padding(.horizontal, 16)
        }
    }
}
