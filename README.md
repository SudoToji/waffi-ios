# waffi-ios

The iPhone side of Waffi's Pager: the **Waffi** app (staff), the **App Clip** a person waiting opens from the QR, and the **Live Activity** on the lock screen and Dynamic Island. Built entirely on GitHub's macOS runners; no Mac needed. Tracked in SudoToji/waffi issues (map #318).

## Folders

| Folder | What it is |
|---|---|
| `project.yml` | [XcodeGen](https://github.com/yonaskolb/XcodeGen) spec. The Xcode project, Info.plists and entitlements are generated from it by CI and are not committed. |
| `App/` | `Waffi` app target (`com.waffieg.app`): staff sign-in (bearer tokens in the Keychain, `Auth/`), the staff Pager (`Pager/`), About, and the ticket screen for a `/p/<token>` link. A Debug or TestFlight build shows a Server field on the sign-in screen (https only); App Store builds always use https://waffieg.com. |
| `AppLiveActivity/` | Widget extension inside the app (`com.waffieg.app.LiveActivity`), Live Activity only. |
| `Clip/` | `WaffiClip` App Clip target (`com.waffieg.app.Clip`). |
| `ClipLiveActivity/` | Widget extension inside the Clip (`com.waffieg.app.Clip.LiveActivity`), Live Activity only. |
| `Shared/` | Swift compiled into all four targets: the ticket model and screen (`PagerTicketModel`, `PagerTicketView`; the app and the Clip each pass their own `PagerHost`), the Live Activity attributes, its UI (the four Card style layouts, one file each, in `Shared/PagerStyles/`), the logo helper (`PagerLogo`: the App Clip writes the Business logo to the App Group at `PagerLogo.fileURL(forBusiness:)`) and `Localizable.xcstrings` (en, ar). |
| `Resources/` | Asset catalog (app icon) for the app and the Clip. `scripts/make_icon.py` regenerates the placeholder icon. |
| `.github/workflows/` | `build.yml` (every push and PR: unsigned simulator build) and `testflight.yml` (signed build uploaded to TestFlight). |

## No secrets in this repo

The repository is public. Never commit a key, `.p8`, certificate, provisioning profile, IPA or team id, and never print or upload one from a workflow. Signing uses the App Store Connect API key from the repository secrets `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8` and `APPLE_TEAM_ID`; the workflow writes the key to the runner's temp folder and deletes it at the end. No build artifacts are uploaded.

## Cut a TestFlight build

Push to `main`, or run **Actions > testflight > Run workflow**. The workflow archives with automatic signing, checks the App Clip is under 15 MB, then exports and uploads to App Store Connect. The build number is the run number; the version is `MARKETING_VERSION` in `project.yml`.

To install it, add yourself to an **Internal Testing** group in App Store Connect (TestFlight tab of the Waffi app) once, then open TestFlight on the iPhone. Processing in App Store Connect takes a few minutes after the upload.

## Prerequisite: one registered device

Automatic signing makes development profiles during the archive, and Apple only makes them when the team has at least one registered device. Register your iPhone once under Certificates, Identifiers & Profiles > Devices on developer.apple.com; without it the archive fails with "Your team has no devices from which to generate a provisioning profile".
