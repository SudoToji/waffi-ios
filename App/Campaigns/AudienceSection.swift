import SwiftUI

/// Who gets the message: the audience, its own choice, and the live count of Customers who agreed to marketing.
struct AudienceSection: View {
    @Bindable var model: ComposerModel

    /// The audiences on offer: tiers need the Customer Tiers switch and the Branch audience a Business with several open Branches;
    /// a draft already aimed there keeps it.
    private var audiences: [String] {
        let openBranches = model.branches.filter { $0.status != "closed" }.count
        return MessageForm.audiences.filter { audience in
            (audience != "tiers" || model.tiersOn || model.form.audience == "tiers")
                && (audience != "joining_branch" || openBranches > 1 || model.form.audience == "joining_branch")
        }
    }

    var body: some View {
        ComposerCard {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Audience").font(.headline).foregroundStyle(Theme.text).accessibilityAddTraits(.isHeader)
                    Text("Agreed to marketing only").font(.footnote).foregroundStyle(Theme.secondaryText)
                }
                Spacer(minLength: 8)
                count
            }
            Picker("Audience", selection: $model.form.audience) {
                ForEach(audiences, id: \.self) { audience in Text(AudienceLabel.name(audience)).tag(audience) }
            }
            .pickerStyle(.menu)
            .tint(Theme.accent)
            details
            AudienceLabel.rule(model.form.audience, days: model.form.inactiveDays)
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
            if let counts = model.counts, counts.optedIn > 0 {
                Text("\(counts.walletPasses) with a wallet pass")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
            }
            if let error = model.countError {
                Text(error.message).font(.footnote).foregroundStyle(Theme.warning)
            }
        }
    }

    @ViewBuilder private var count: some View {
        if let counts = model.counts {
            VStack(alignment: .trailing, spacing: 0) {
                Text(counts.optedIn.formatted())
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                    .foregroundStyle(Theme.accent)
                    .contentTransition(.numericText())
                    .opacity(model.countLoading ? 0.5 : 1)
                Text("Customers").font(.footnote.weight(.semibold)).foregroundStyle(Theme.secondaryText)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(counts.optedIn) Customers will get this"))
        } else if model.countLoading {
            ProgressView()
        }
    }

    @ViewBuilder private var details: some View {
        switch model.form.audience {
        case "inactive":
            Stepper(value: $model.form.inactiveDays, in: 1...365) {
                Text("Days without activity: \(model.form.inactiveDays)")
            }
        case "tiers": tierChoice
        case "customer": CustomerCodeField(api: model.api, code: $model.form.customerCode)
        case "joining_branch": branchChoice
        case "birthday_range":
            MonthDayPicker(title: "Birthday from", value: $model.form.birthdayFrom)
            MonthDayPicker(title: "Birthday to", value: $model.form.birthdayTo)
        default: EmptyView()
        }
    }

    @ViewBuilder private var tierChoice: some View {
        Text("Select tiers").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text)
        if model.tiers.isEmpty {
            Text("Create customer tiers on the Customers page first.").font(.footnote).foregroundStyle(Theme.secondaryText)
        }
        ForEach(model.tiers) { tier in
            let chosen = model.form.tierIds.contains(tier.id)
            Button {
                if chosen { model.form.tierIds.removeAll { $0 == tier.id } } else { model.form.tierIds.append(tier.id) }
            } label: {
                HStack {
                    Text(verbatim: tier.displayName).foregroundStyle(Theme.text)
                    Spacer()
                    Image(systemName: chosen ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(chosen ? Theme.accent : Theme.secondaryText)
                }
                .frame(minHeight: 44)
                .contentShape(.rect)
            }
            .accessibilityAddTraits(chosen ? .isSelected : [])
        }
    }

    @ViewBuilder private var branchChoice: some View {
        let saved = model.branches.first { $0.id == model.form.branchId && $0.status != "working" }
        Picker("Branch", selection: $model.form.branchId) {
            Text("Select a Branch").tag("")
            ForEach(model.branches.filter { $0.status == "working" }) { branch in Text(verbatim: branch.name).tag(branch.id) }
            // A saved Branch that has since closed or been Locked stays visible, marked, until another is chosen.
            if let saved {
                let label = saved.status == "locked"
                    ? String(localized: "\(saved.name) (Locked)") : String(localized: "\(saved.name) (closed)")
                Text(verbatim: label).tag(saved.id)
            }
        }
        .pickerStyle(.menu)
        .tint(Theme.accent)
    }
}
