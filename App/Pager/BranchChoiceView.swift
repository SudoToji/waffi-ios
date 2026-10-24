import SwiftUI

/// Which Branch this person serves at today; remembered on the phone.
struct BranchChoiceView: View {
    let model: StaffPagerModel
    let gone: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Where are you working today?").font(.title2.bold())
                Text("Choose the Branch you serve at. You can change it any time.").foregroundStyle(.secondary)
                if gone {
                    Text("The Branch you were serving at is no longer available. Choose another.").foregroundStyle(.orange)
                }
                ForEach(model.branches) { branch in
                    Button(branch.name) { model.choose(branch) }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                }
            }
            .multilineTextAlignment(.center)
            .padding(24)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
    }
}
