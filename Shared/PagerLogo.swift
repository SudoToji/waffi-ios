import Foundation
import UIKit

/// The Business logo shared through the App Group container, written by the app or the App Clip before it starts the activity.
///
/// The writer (ticket #324) must save a PNG, about 120 x 120 px (a Live Activity has little memory), at
/// `PagerLogo.fileURL(forBusiness:)`, i.e. `<App Group>/logos/<percent-encoded Business name>.png`. It should call that function
/// itself (this file is compiled into every target) rather than rebuild the name, and create the `logos` folder first.
/// No file means the Waffi mark is shown.
enum PagerLogo {
    static let appGroup = "group.com.waffieg.app"

    static func fileURL(forBusiness name: String) -> URL? {
        let key = name.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "logo"
        return FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
            .appending(path: "logos/\(key.prefix(150)).png")
    }

    static func image(forBusiness name: String) -> UIImage? {
        fileURL(forBusiness: name).flatMap { UIImage(contentsOfFile: $0.path) }
    }
}
