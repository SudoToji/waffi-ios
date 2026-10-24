import Foundation
import UIKit

/// The Business logo shared through the App Group container, written by the app or the App Clip before it starts the activity.
///
/// The writer (`save`, called by the App Clip) saves a PNG, about 120 x 120 px (a Live Activity has little memory), at
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

    /// Saves a downloaded logo as a 120 x 120 px PNG (whole logo, transparent margins), replacing the old file.
    static func save(_ data: Data, forBusiness name: String) {
        guard let url = fileURL(forBusiness: name), let image = UIImage(data: data), image.size.width > 0, image.size.height > 0 else { return }
        let side: CGFloat = 120
        let scale = min(side / image.size.width, side / image.size.height)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let png = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).pngData { _ in
            image.draw(in: CGRect(x: (side - size.width) / 2, y: (side - size.height) / 2, width: size.width, height: size.height))
        }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? png.write(to: url, options: .atomic)
    }

    static func image(forBusiness name: String) -> UIImage? {
        fileURL(forBusiness: name).flatMap { UIImage(contentsOfFile: $0.path) }
    }
}
