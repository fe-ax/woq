# WOQ — Workout Queue

A personal workout logger for iPhone. One user, no account, no analytics, no network code and no third-party
libraries: everything lives on the device, and a JSON backup is written to a folder of your choice after every
change.

The idea is a *queue*, not a plan. Every exercise you know sits in one list, sorted by how long ago you last did it
(never done first). Tap the top one, log your sets, finish, and it drops to the bottom. Over time the queue itself
tells you what is due.

## What it does

- **Queue** of exercises with front/back muscle thumbnails, the relative date and the last peak set
  ("40 kg × 10 · 3 sets"). Drawn as a git graph: a yellow lane with a node per exercise.
- **One exercise in progress at a time.** Tapping a row moves it into a blue card at the top, prefilled with the
  last peak set. Log several sets with the plus, finish with the checkmark; the sets are saved as one *execution*.
  The pending sets branch off the lane in red and merge back, git style.
- **Peak rule.** The best set of an execution is the highest estimated one-rep max (Epley, `kg × (1 + reps/30)`);
  it drives the row text, the prefill and the chart.
- **Detail sheet** (long-press a row): large figures, muscles by intensity, equipment and notes, a **progress
  chart** of the estimated 1RM per execution (a lane graph with the personal record marked), and the history
  grouped per execution with per-set edit, delete and "Add set".
- **Add sheet** with a name, a left/right toggle for unilateral exercises, 18 muscles with three intensities on a
  live figure, an optional first set, equipment and notes — or switch to a list of 39 presets and add several at
  once.
- **Search** by name, muscle or equipment, plus a tap-the-figure muscle filter.
- **Settings** behind a long-press on the title: appearance (system/light/dark), the water ripple on the card, the
  text font (SF Pro, SF Mono, Menlo, Courier New), and backups.
- **Backups**: silent, automatic JSON snapshots to `Documents/Backups` (visible in Files) and to a folder you
  pick once, for example in iCloud Drive; daily snapshots are kept for two weeks; restore merges without deleting.

## How it looks

Paper white (or dark paper) background, ink outlines, a pastel palette borrowed from git graphs: yellow for the
queue lane, blue for what is in progress or selected, red for pending sets and primary muscles, green for the
finish flash. No system navigation bars, no Liquid Glass: every control is drawn by the app. The in-progress card
sits on a Metal water shader. The body figure is a hand-built SVG with 21 regions, rendered in a `Canvas`.

## Requirements

- Xcode 26.6 with the iOS 26 SDK and the Metal toolchain
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- An iPhone running iOS 26 (portrait, iPhone only) or the simulator

## Build and run

The Xcode project is generated from `project.yml` and not committed:

```bash
xcodegen generate
```

Build for a simulator and install it:

```bash
xcodebuild -project WOQ.xcodeproj -scheme WOQ -configuration Debug \
  -destination "platform=iOS Simulator,id=<UDID>" -derivedDataPath build/dd build
xcrun simctl install <UDID> build/dd/Build/Products/Debug-iphonesimulator/WOQ.app
xcrun simctl launch <UDID> nl.feax.woq
```

Debug builds accept launch arguments: `--gallery` shows every component, `--preview add|edit|detail|entry|addset|presets|chart`
opens one screen on sample data, and the Developer page in the settings menu inserts 21 sample exercises with two
months of sets.

Run the tests (Swift Testing, `WOQTests`, in-memory SwiftData):

```bash
xcodebuild -project WOQ.xcodeproj -scheme WOQ -configuration Debug \
  -destination "platform=iOS Simulator,id=<UDID>" -derivedDataPath build/dd test
```

For a device, a Release build signed with a personal team works with free provisioning (`-allowProvisioningUpdates`,
`xcrun devicectl device install app`); the profile then expires after seven days and needs renewing from Xcode.

## Under the hood

- SwiftUI with `@Observable`, SwiftData with a versioned schema (V1 → V2 → V3, lightweight migrations), Swift 6
  language mode with strict concurrency and main-actor default isolation.
- `QueueStore` is the only type that mutates the store. Sets are `Entry` rows; an execution is a read-time grouping
  by `executionID`, never a query.
- Weights are stored as integer half-kilos (0.5 kg grid, `nil` = bodyweight). Reps 1–999.
- The figure pipeline: `Design/figure/generator/build.py` writes the SVGs, `Scripts/svg2swift.py` turns them into
  `WOQ/Figure/FigurePaths.swift`.

```
project.yml           XcodeGen spec (app target WOQ, test bundle WOQTests)
WOQ/App               entry point, model container, debug previews
WOQ/Model             schema versions, Exercise/Entry, QueueStore, drafts, presets, progress series
WOQ/Backup            backup document, writer, folder bookmark, scheduler, importer
WOQ/Design            tokens, fonts, components, the water shader
WOQ/Figure            generated figure paths and the Canvas renderer
WOQ/Screens           main screen, sheets, menu pages, the progress chart
WOQTests              Swift Testing suites (parsing, peak rule, ordering, store rules, backup merge, series)
Design/figure, icon   SVG sources and generators
docs/                 toolchain and SwiftUI/SwiftData research notes
```

## Licence

Private project, all rights reserved.

---

This application was built by Claude, Anthropic's AI model, working in Claude Code under the direction of
Marco Stuurman, in September 2026.
