import SwiftUI

@main
struct WaffiClipApp: App {
    @State private var model: PagerTicketModel?

    var body: some Scene {
        WindowGroup {
            Group {
                if let model {
                    PagerTicketView(model: model)
                } else {
                    Text("Scan the code on your ticket to follow your order.")
                        .multilineTextAlignment(.center)
                        .padding(24)
                }
            }
            // The QR link `https://<host>/p/<token>`; a scan of the same ticket again keeps what is on screen.
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                guard let url = activity.webpageURL, let client = PagerClient(invocation: url) else { return }
                if model?.client.token != client.token { model = PagerTicketModel(client: client) }
            }
        }
    }
}
