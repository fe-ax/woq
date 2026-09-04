# WOQ ("Workout Queue") — Xcode 26.6 toolchain research (verified 2026-09-05)

Environment verified locally: Xcode 26.6 (17F113) at /Applications/Xcode.app, iOS 26.5 SDK (iphoneos26.5 / iphonesimulator26.5),
Swift 6.3.3, macOS 26.6.2 (25G83, Darwin 25.6.0), `security find-identity -v -p codesigning` -> 0 valid identities,
no Xcode account signed in (no `IDEProvisioningTeams`, no provisioning profiles), XcodeGen not installed.
Legend: [L] = verified by a local read-only command, [W] = verified from a web source, [?] = could not verify.

## 1. XcodeGen

- [L] `brew info xcodegen`: stable **2.46.0** (bottled, `arm64_tahoe` bottle), no deps. Install later with `brew install xcodegen`.
- [W] 2.46.0 released 2026-07-16; its only changelog entry is "Update to XcodeProj 9.14.0 (#1629)". Neither CHANGELOG nor README
  contains an explicit "Xcode 26 support" statement. 2.44.0 added "Basic support for Xcode 16's synchronized folders".
- [W] Project format: `options.projectFormat` defaults to `xcode16_0` -> `objectVersion = 77` (also `xcode16_3` -> 90, `xcode15_3` -> 63,
  `xcode15_0` -> 60, `xcode14_0` -> 56; source `Sources/XcodeGenKit/ProjectFormat.swift`). Xcode 26.6 opens Xcode 16-format projects;
  there is no separate "Xcode 26" pbxproj format. Xcode-26-related open issues: #1556 (.icon Icon Composer bundles are added as loose
  files; irrelevant when using a classic appiconset) and #1577 (`supportedDestinations` deployment target defaults to 26; irrelevant when
  using `platform: iOS` + `deploymentTarget`). #1578 (objectVersion 77 unreadable by Xcode 15.0.1) is closed and irrelevant.
- [W] `.metal` files map to the Compile Sources phase automatically (`Sources/ProjectSpec/FileType.swift`: `"metal": FileType(buildPhase: .sources)`),
  so a `.metal` file inside the `sources` folder needs no extra config. Xcode's Debug preset sets `MTL_ENABLE_DEBUG_INFO: INCLUDE_SOURCE`.
- [W] `info:` writes an Info.plist and sets `INFOPLIST_FILE` (auto-generating CFBundleIdentifier/Executable/Name/Version keys). `settings:` is
  either a flat map or `{groups, base, configs}` (do not mix; a flat map is silently ignored next to `base`). Lists are YAML lists,
  booleans plain `YES`/`NO`. Presets applied automatically: iOS platform -> `SDKROOT: iphoneos`, `TARGETED_DEVICE_FAMILY: '1,2'`,
  `LD_RUNPATH_SEARCH_PATHS`; iOS application -> `CODE_SIGN_IDENTITY: iPhone Developer`, `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon`;
  unit/UI test bundles -> `BUNDLE_LOADER: $(TEST_HOST)`; XcodeGen auto-sets `TEST_HOST` (unit) and `TEST_TARGET_NAME` (UI) from an app-target dependency.
- [L] Exact Xcode 26.6 build-setting names (from Xcode's `Swift.xcspec` and Apple's Build Settings Reference):
  `SWIFT_APPROACHABLE_CONCURRENCY` (Boolean, default NO; enables DisableOutwardActorInference, GlobalActorIsolatedTypesUsability,
  InferIsolatedConformances, InferSendableFromCaptures, NonisolatedNonsendingByDefault), `SWIFT_DEFAULT_ACTOR_ISOLATION`
  (enum `nonisolated` | `MainActor`, default nonisolated, emits `-default-isolation=MainActor`), `SWIFT_STRICT_CONCURRENCY`
  (`minimal` | `targeted` | `complete`). Xcode 26.6's own templates set `SWIFT_APPROACHABLE_CONCURRENCY = YES` (project),
  `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (app target), but still `SWIFT_VERSION = 5.0`.
  Nuance [L]: the xcspec marks `SWIFT_STRICT_CONCURRENCY` and `SWIFT_APPROACHABLE_CONCURRENCY` with `Condition = EFFECTIVE_SWIFT_VERSION in (4, 4.2, 5)`
  (hidden in Swift 6 mode, where strict checking is implied). The two sub-features not already in Swift 6 mode
  (`SWIFT_UPCOMING_FEATURE_NONISOLATED_NONSENDING_BY_DEFAULT`, `..._INFER_ISOLATED_CONFORMANCES`) default to `$(SWIFT_APPROACHABLE_CONCURRENCY)` with no
  version condition, so keeping `SWIFT_APPROACHABLE_CONCURRENCY: YES` under `SWIFT_VERSION: 6.0` still enables them [?: confirm in a build log
  that `-enable-upcoming-feature NonisolatedNonsendingByDefault` is passed].
- [L] Info.plist build settings: `INFOPLIST_KEY_UILaunchScreen_Generation = YES` writes `UILaunchScreen = {}` (Apple: "sets the value of the
  UILaunchScreen key ... to an empty dictionary"); `INFOPLIST_KEY_UISupportedInterfaceOrientations[_iPhone|_iPad]` exist. With
  `GENERATE_INFOPLIST_FILE = YES` Xcode *merges* an `INFOPLIST_FILE` with the `INFOPLIST_KEY_*` values (Apple doc), so XcodeGen's `info:`
  can carry keys that have no `INFOPLIST_KEY_` equivalent (e.g. `UIDesignRequiresCompatibility`).

Minimal `project.yml` (all keys verified against Docs/ProjectSpec.md; replace the bundle id / team):

```yaml
name: WOQ
options:
  bundleIdPrefix: com.marcostuurman        # any unique reverse-DNS prefix (see section 6)
  deploymentTarget: { iOS: "26.0" }
  xcodeVersion: "26.6"
  createIntermediateGroups: true
configs: { Debug: debug, Release: release }
settings:
  base:
    SWIFT_VERSION: "6.0"                    # Swift 6 language mode
    SWIFT_APPROACHABLE_CONCURRENCY: YES
    SWIFT_DEFAULT_ACTOR_ISOLATION: MainActor
    SWIFT_STRICT_CONCURRENCY: complete
    SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY: YES
    ENABLE_USER_SCRIPT_SANDBOXING: YES
    CODE_SIGN_STYLE: Automatic
    # DEVELOPMENT_TEAM: ABCDE12345           # personal-team ID, only needed for device builds
targets:
  WOQ:
    type: application
    platform: iOS
    sources: [WOQ]                          # contains *.swift, Shaders.metal, Assets.xcassets (AppIcon)
    info:
      path: WOQ/Info.plist
      properties:
        UILaunchScreen: {}
        UISupportedInterfaceOrientations: [UIInterfaceOrientationPortrait]
        # UIDesignRequiresCompatibility: false   # see section 2
    settings:
      base:
        PRODUCT_NAME: "Workout Queue"
        INFOPLIST_KEY_CFBundleDisplayName: "Workout Queue"
        GENERATE_INFOPLIST_FILE: YES
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
        INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
        TARGETED_DEVICE_FAMILY: "1"
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
        ENABLE_PREVIEWS: YES
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: "1"
        MTL_FAST_MATH: YES
      configs:
        Debug: { MTL_ENABLE_DEBUG_INFO: INCLUDE_SOURCE }
    scheme:
      testTargets: [WOQTests, WOQUITests]
      gatherCoverageData: true
  WOQTests:                                 # Swift Testing needs no extra dependency in Xcode 16+ (import Testing)
    type: bundle.unit-test
    platform: iOS
    sources: [WOQTests]
    dependencies: [{ target: WOQ }]
    settings: { base: { GENERATE_INFOPLIST_FILE: YES } }
  WOQUITests:
    type: bundle.ui-testing
    platform: iOS
    sources: [WOQUITests]
    dependencies: [{ target: WOQ }]
    settings: { base: { GENERATE_INFOPLIST_FILE: YES } }
```
Generate with `xcodegen generate` (in the folder holding project.yml). If `PRODUCT_NAME` contains a space, the product is `Workout Queue.app`;
keep `PRODUCT_NAME: WOQ` and use only `INFOPLIST_KEY_CFBundleDisplayName` if you prefer a space-free bundle name.
Sources: https://github.com/yonaskolb/XcodeGen/blob/master/CHANGELOG.md , https://github.com/yonaskolb/XcodeGen/releases ,
https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md , https://github.com/yonaskolb/XcodeGen/blob/master/Sources/XcodeGenKit/ProjectFormat.swift ,
https://github.com/yonaskolb/XcodeGen/issues/1556 , https://github.com/yonaskolb/XcodeGen/issues/1577 , https://developer.apple.com/documentation/xcode/build-settings-reference ,
https://developer.apple.com/documentation/bundleresources/information-property-list/managing-your-app-s-information-property-list

## 2. Liquid Glass opt-out and orientation keys

- [W] `UIDesignRequiresCompatibility`: exists; **Boolean**; available iOS 26.0+, iPadOS 26.0+, macOS 26.0+, tvOS 26.0+. Apple: "Temporarily use
  this key while reviewing and refining your app's UI"; YES = compatibility mode (app looks as when built with previous SDKs); absent/NO = new
  design. **"The system ignores this key when you build for iOS 27 or later"** - i.e. removal is tied to the iOS 27 SDK / Xcode 27, not to an
  iOS 26.x point release, so it is still honored on iOS 26.5 when built with the iOS 26.5 SDK (Xcode 26.6).
  [L] Corroboration: the string `UIDesignRequiresCompatibility` is present in the iOS 26.5 simulator runtime binaries SwiftUICore, SpringBoard
  and UnifiedMessagingKit (not in the on-disk UIKitCore stub). [?] Not verified empirically by running an app. Note: for a brand-new
  iOS-26-only SwiftUI app this key is pointless (it will be ignored by the next SDK); leave it out unless you need to freeze the old look.
- [W] Portrait-only: `UISupportedInterfaceOrientations` (array of strings; value `UIInterfaceOrientationPortrait`). Device qualifiers use the
  `key~device` syntax (`UISupportedInterfaceOrientations~iphone`, `~ipad`); the unqualified key is enough for a TARGETED_DEVICE_FAMILY=1 app.
- [W] `UIRequiresFullScreen` (Boolean, iOS 9+) is documented purely as "puts an **iPad** app into a compatibility mode that opts out of
  multitasking and dynamic resizing" (iPadOS 26 Windowed Apps / Stage Manager behavior). It has no effect on iPhone and is not needed for an
  iPhone-only, portrait-only app.
Sources: https://developer.apple.com/documentation/bundleresources/information-property-list/uidesignrequirescompatibility ,
https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass , https://developer.apple.com/documentation/bundleresources/information-property-list/uisupportedinterfaceorientations ,
https://developer.apple.com/documentation/bundleresources/information-property-list/uirequiresfullscreen , https://developer.apple.com/forums/thread/801712

## 3. App icon in Xcode 26.6

- [W] Classic `AppIcon.appiconset` with a single 1024x1024 PNG still works: Apple's current "Configuring your app icon using an asset catalog"
  says iOS apps "auto-generate all icon variations from a single 1024x1024 pixel image" and that this is the default for new iOS apps.
  Icon Composer `.icon` files are optional ("If you add an Icon Composer file ... it replaces any existing icon asset catalog").
- [L] Xcode 26.6's own iOS template still ships `AppIcon.appiconset/Contents.json` with `universal`/`ios`/`1024x1024` entries (Any, dark, tinted).
  On iOS 26 the system renders a flat icon inside the Liquid Glass treatment automatically. Known issue (Xcode 26.0 notes, 158698677): actool
  may warn "Failed to generate flattened icon stack for icon named..." - safe to ignore.
- Exact minimal `WOQ/Assets.xcassets/AppIcon.appiconset/Contents.json` (PNG must be 1024x1024, opaque/no alpha for App Store uploads):
```json
{
  "images" : [
    { "filename" : "AppIcon-1024.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```
  Optional dark/tinted slots: add entries with `"appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ]` (or `"tinted"`).
  Also add `Assets.xcassets/Contents.json` = `{ "info" : { "author" : "xcode", "version" : 1 } }` and an `AccentColor.colorset` if referenced.
Sources: https://developer.apple.com/documentation/xcode/configuring-your-app-icon , https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer ,
https://developer.apple.com/documentation/xcode-release-notes/xcode-26-release-notes , https://useyourloaf.com/blog/adding-icon-composer-icons-to-xcode/

## 4. Command sequences (flags verified with `xcodebuild -help`, `xcrun simctl help <cmd>`, `man xcodebuild`) [L]

```bash
SIM=37A71D41-C28A-4777-9A2F-0DE39F55DA9F     # existing "marco" = iPhone 13 Pro Max, iOS 26.5 (see section 5)
DD=build/DerivedData; BID=com.marcostuurman.WOQ
# build for simulator by name / by UDID  (name= matches the simulator's display name, OS= optional)
xcodebuild -project WOQ.xcodeproj -scheme WOQ -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 13 Pro Max,OS=26.5' -derivedDataPath "$DD" build
xcodebuild -project WOQ.xcodeproj -scheme WOQ -configuration Debug -destination "platform=iOS Simulator,id=$SIM" -derivedDataPath "$DD" build
# generic (no specific device): -destination 'generic/platform=iOS Simulator'   (physical: 'generic/platform=iOS' or 'platform=iOS,id=<UDID>')
APP="$DD/Build/Products/Debug-iphonesimulator/WOQ.app"     # verified layout: <derivedDataPath>/Build/Products/<Config>-iphonesimulator/
xcrun simctl boot "$SIM"; open -a Simulator                 # boot is headless; `open -a Simulator` shows the window
xcrun simctl install "$SIM" "$APP"
xcrun simctl launch --console-pty --terminate-running-process "$SIM" "$BID"   # blocks; prints stdout/stderr (print/debugPrint) via a PTY
xcrun simctl launch --stdout=app.out --stderr=app.err "$SIM" "$BID"           # non-blocking alternative
xcrun simctl spawn "$SIM" log stream --level debug --style compact --predicate 'subsystem == "com.marcostuurman.WOQ"'   # Logger/os_log
xcrun simctl spawn "$SIM" log show --last 10m --predicate 'process == "WOQ"'   # after the fact
xcrun simctl terminate "$SIM" "$BID"; xcrun simctl uninstall "$SIM" "$BID"
xcrun simctl get_app_container "$SIM" "$BID" data            # app sandbox path (e.g. to inspect a SwiftData store)
xcrun simctl io "$SIM" screenshot --type=png shot.png        # `booted` works instead of the UDID when one device is booted
xcrun simctl io "$SIM" recordVideo --codec=h264 --force demo.mp4   # Ctrl+C stops; default codec is hevc
xcrun simctl status_bar "$SIM" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 --dataNetwork wifi
xcrun simctl status_bar "$SIM" clear
# tests (Swift Testing identifiers: Target/SuiteType/function() - the trailing "()" is REQUIRED in Xcode 26.6; verified: without it 0 tests run)
xcodebuild test -project WOQ.xcodeproj -scheme WOQ -destination "platform=iOS Simulator,id=$SIM" -derivedDataPath "$DD" \
  -only-testing:WOQTests -only-testing:'WOQTests/QueueTests/appendWorks()' -only-testing:WOQUITests/WOQUITests/testLaunch -resultBundlePath build/Tests.xcresult
xcodebuild -resolvePackageDependencies -project WOQ.xcodeproj -scheme WOQ           # SPM; add -onlyUsePackageVersionsFromResolvedFile for CI
xcodebuild ... -skipMacroValidation build   # only needed when an SPM *package* provides macros; #Preview/@Observable/@Model/@Test are toolchain-builtin
```
- Console vs log: `--console-pty` shows stdout/stderr (`print`); `Logger`/`os_log` goes to unified logging -> use `log stream` (both can run together).
- [L] Crash reports: simulator app crashes are written by macOS to `~/Library/Logs/DiagnosticReports/<Process>-<YYYY-MM-DD-HHMMSS>.ips`
  (directory verified on macOS 26.6.2). Symbolicate: `python3 /Applications/Xcode.app/Contents/SharedFrameworks/CoreSymbolicationDT.framework/Resources/CrashSymbolicator.py -d WOQ.app.dSYM -o out.crash in.ips`
  (script path verified). Per-simulator logs: `~/Library/Logs/CoreSimulator/<UDID>/system.log`, `CrashReporter/DiagnosticLogs/`; `xcrun simctl diagnose` bundles everything.
- `-showdestinations -scheme WOQ` lists valid destination ids. `-quiet` suppresses non-error output; `-json` implies `-quiet`.
Sources: local `xcodebuild -help` / `xcrun simctl help launch|io|status_bar|spawn` / `man xcodebuild`; https://support.circleci.com/hc/en-us/articles/360037683373-iOS-Simulator-Crash-Reports ;
https://trinhngocthuyen.com/posts/tech/swift-testing-and-xcodebuild/ (its "()()" workaround is obsolete in 26.6) ; https://forums.swift.org/t/ignore-macro-validation-using-xcodebuild-command/68125

## 5. Simulator: iPhone 13 Pro Max [L]

- `xcrun simctl list devicetypes | grep -i iphone` lists `iPhone 13 Pro Max (com.apple.CoreSimulator.SimDeviceType.iPhone-13-Pro-Max)` (42 iPhone types, 6s..17 Pro Max/Air/17e).
- Runtimes installed: iOS 18.6 (22G86) and **iOS 26.5 (23F77)** `com.apple.CoreSimulator.SimRuntime.iOS-26-5`; its `supportedDeviceTypes` (65 entries) includes
  iPhone 13 Pro Max (device-type profile: minRuntimeVersion 15.0).
- **A matching device already exists and was Booted at check time:** `marco (37A71D41-C28A-4777-9A2F-0DE39F55DA9F)`, type iPhone-13-Pro-Max, iOS 26.5.
  If you still want a fresh one (not executed):
  `xcrun simctl create "iPhone 13 Pro Max" com.apple.CoreSimulator.SimDeviceType.iPhone-13-Pro-Max com.apple.CoreSimulator.SimRuntime.iOS-26-5`
- Point sizes (from Xcode 26.6 device-type `profile.plist`, mainScreenWidth/Height/Scale):
  iPhone 13 Pro Max **428x926 pt @3x** (1284x2778) = iPhone 14 Plus; iPhone 16 Plus **430x932 @3x** (1290x2796) = 14 Pro Max;
  iPhone 17 Pro Max **440x956 @3x** (1320x2868) = 16 Pro Max; iPhone 17 402x874; iPhone Air 420x912. (useyourloaf's table mislabels 13 Pro Max as 430x932.)
Sources: local `xcrun simctl list devicetypes|runtimes|devices -j`; https://useyourloaf.com/blog/iphone-17-screen-sizes/

## 6. Physical iPhone 13 Pro Max with a free Apple Account (Personal Team)

- [W] iPhone 13 Pro Max supports iOS 26 (Apple's compatibility list); it must run iOS 26.x for a 26.0 deployment target.
- Xcode GUI prerequisites (no CLI equivalent): Xcode > Settings... > Accounts > "+" > Apple Account > sign in; the team appears as
  "<Name> (Personal Team)". Click Manage Certificates... > "+" > Apple Development (or let the first signed build create it). `-allowProvisioningUpdates`
  explicitly "Requires a developer account to have been added in Xcode's Accounts settings" (xcodebuild -help) [L].
- Team ID for `DEVELOPMENT_TEAM` (10 chars): after the certificate exists,
  `security find-certificate -c "Apple Development" -p | openssl x509 -noout -subject` -> the `OU=` value; or pick the team once in any project's
  Signing & Capabilities pane and copy `DEVELOPMENT_TEAM` from that pbxproj. [?] Xcode 26 Accounts pane may not display the ID directly.
- project.yml: `CODE_SIGN_STYLE: Automatic`, `DEVELOPMENT_TEAM: <ID>`; keep XcodeGen's default `CODE_SIGN_IDENTITY: iPhone Developer` (alias of
  Apple Development) or set `"Apple Development"`. Bundle ID must be globally unique across all teams (`com.example.*`-style ids fail with
  "The app identifier cannot be registered to your development team because it is not available"), and capabilities needing entitlements
  (iCloud, push, etc.) are unavailable to personal teams [W].
- Developer Mode (iOS 16+): Settings > Privacy & Security > Developer Mode (only visible after the phone was connected/paired with Xcode) > on > Restart >
  confirm > passcode [W, Apple doc]. Pairing: connect by cable, tap Trust This Computer, then Xcode > Open Developer Tool > Device Hub (pair). Wireless
  *initial* pairing requires iOS 27+; after a cable pairing you may unplug and run over Wi-Fi (IPv6, same network) [W, Apple Device Hub doc].
- [W] Apple's free-provisioning limits (developer.apple.com/support/compare-memberships, verbatim): "You can register up to **10 App IDs, which expire after 7 days**",
  "up to **3 devices**, which expire after 7 days", "up to **3 apps per device**", "Provisioning profiles ... will expire **7 days from issuance**" (rebuild + reinstall).
  So the numbers in the task ("3 app IDs per week, 10 devices") are inverted.
- Commands [L flags]:
```bash
xcrun devicectl list devices                                   # USB and Wi-Fi; add --json-output devices.json for the stable schema (UDID lives in the JSON;
                                                               #   the table's Identifier column is a CoreDevice UUID) [? field name unverified: no device attached]
xcodebuild -project WOQ.xcodeproj -scheme WOQ -configuration Debug -destination 'platform=iOS,id=<UDID>' \
  -derivedDataPath build/DerivedData -allowProvisioningUpdates -allowProvisioningDeviceRegistration build      # creates app ID + profile, registers device
xcrun devicectl device install app --device <UDID-or-name> build/DerivedData/Build/Products/Debug-iphoneos/WOQ.app
xcrun devicectl device process launch --device <UDID-or-name> --terminate-existing --console com.marcostuurman.WOQ   # --console streams stdout/stderr
xcrun devicectl device info apps --device <UDID>;  xcrun devicectl device process terminate --device <UDID> --pid <pid>
xcrun devicectl device uninstall app --device <UDID> com.marcostuurman.WOQ
```
- [?] Whether xcodebuild alone can create the *certificate* for a personal team without one GUI-driven build was not verifiable here (no account).
  [?] First launch may show "Untrusted Developer" -> Settings > General > VPN & Device Management > trust the developer app (documented for personal-team apps; not re-verified on iOS 26).
Sources: https://developer.apple.com/support/compare-memberships/ , https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device ,
https://developer.apple.com/documentation/xcode/managing-your-simulated-and-physical-devices-in-device-hub , https://support.apple.com/guide/iphone/iphone-models-compatible-with-ios-26-iphe3fa5df43/ios ,
https://gist.github.com/Francesco149/a050b4637d8ea1b4e76ccccda68490b2 , https://developer.apple.com/forums/thread/707297 , https://praeclarum.org/2025/10/21/many-ways-to-deploy-ios.html

## 7. Xcode 26.6 release notes - known issues [W]

- Xcode 26.6 notes: Swift 6.3, iOS/iPadOS/tvOS/watchOS/macOS/visionOS 26.5 SDKs, requires macOS 26.2+. The page has only two sections
  (Coding Intelligence, Organizer) and lists **no Known Issues** for SwiftUI previews, Simulator, SwiftData or xcodebuild.
- Still-listed known issues in earlier 26.x notes that may apply: Simulators may fail to boot during the first build after upgrading macOS (26.0/26.1, 152328794);
  Swift Testing exit tests may write crash logs into /Library/ (26.0, 47982238); Swift Testing may crash under a Rosetta run destination (26.4, 170347005);
  actool "flattened icon stack" warning (26.0, 158698677); Background Assets dev-override eligibility in simulators (26.5, 173742496);
  Swift 6.3.2 changed isolation inference of closures passed to `nonisolated(nonsending)` parameters (26.5, relevant to approachable concurrency).
  No SwiftData items appear in any 26.x notes. Useful fixes: unit-test runner cwd is now `/tmp` (26.4, 162549425); simulator dyld shared caches auto-created again (26.4);
  Simulator pasteboard sync fixed (26.5, 173403967).
Sources: https://developer.apple.com/documentation/xcode-release-notes/xcode-26_6-release-notes , https://developer.apple.com/documentation/xcode-release-notes/xcode-26_5-release-notes ,
https://developer.apple.com/documentation/xcode-release-notes/xcode-26_4-release-notes , https://developer.apple.com/documentation/xcode-release-notes/xcode-26-release-notes
