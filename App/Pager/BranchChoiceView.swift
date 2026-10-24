import SwiftUI

/// Which Branch this person serves at today; remembered on the phone.
struct BranchChoiceView: View {
    let model: StaffPagerModel
    let gone: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Where are you working today?")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(Theme.text)
                Text("Choose the Branch you serve at. You can change it any time.").foregroundStyle(Theme.secondaryText)
                if gone {
                    Text("The Branch you were serving at is no longer available. Choose another.").foregroundStyle(Theme.warning)
                }
                ForEach(model.branches) { branch in
                    Button(branch.name) { model.choose(branch) }
                        .buttonStyle(.waffiTinted)
                }
            }
            .multilineTextAlignment(.center)
            .padding(24)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
    }
}
