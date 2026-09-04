# SwiftUI + SwiftData research for the WOQ exercise queue (iOS 26 only)

Verified 2026-09-05 on this Mac: **Xcode 26.6 (17F113), Swift 6.3.3, iOS SDK 26.5, iOS 26.5 simulator**.
"[verified]" = compiled/run locally with `-swift-version 6 -default-isolation MainActor
-enable-upcoming-feature NonisolatedNonsendingByDefault` (macOS 26 host for SwiftData runtime tests,
iOS 26.5 simulator SDK for SwiftUI type-checks). "[source]" = documentation/blog only. "[unverified]" = flagged.
Compiler-verified sample code: `~/claude-files/woq/research/verified-samples/` (`patterns.swift` type-checks
for iOS 26 with all API names below; `swiftdata_test.swift`, `modelactor_test.swift`, `TestPkg/` ran green).

## 1. SwiftData on iOS 26

**(a) `@Model` and default MainActor isolation** [verified]
- `@Model` needs a class (make it `final`), an explicit `init`, stored properties of supported types
  (primitives, `Date`, `Data`, `Codable` value types/enums, arrays of those, relationships to other `@Model`s).
- Macro expansion (Swift 6.3.3 / SDK 26.5) emits `extension X: nonisolated PersistentModel`,
  `extension X: nonisolated Observable`, and an **unavailable** `Sendable` conformance whose message is:
  "PersistentModels are not Sendable, consider utilizing a ModelActor or use X's persistentModelID instead".
  `PersistentModel` itself inherits `SendableMetatype` (SDK interface).
- Under `SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor` a `@Model` class's init, stored/computed properties and
  methods compiled fine from `nonisolated` code, while a plain class in the same file errored with
  "main actor-isolated property 'name' can not be referenced from a nonisolated context". Mechanism not
  pinned down (not reproduced with `@Observable`, `nonisolated Identifiable`, or `SendableMetatype` alone),
  so **write `@Model nonisolated final class`** explicitly, as Apple DTS recommends
  (https://developer.apple.com/forums/thread/788262). Type-checked fine in `patterns.swift`.
- `ModelContainer` is `Sendable`; `ModelContext` is not; `container.mainContext` and all `Query` inits are `@MainActor`
  (SDK interface); `mainContext` autosaves, a hand-made `ModelContext(container)` has `autosaveEnabled == false`, so call `save()`.
- `@ModelActor actor Background { ... }` + `Background(modelContainer:)` compiled and ran under default
  MainActor with no annotations; move data across actors as `PersistentIdentifier` and re-fetch with
  `self[id, as: Item.self]` / `modelContext.model(for:)`. Sending a model instance to `Task.detached` fails:
  "sending value of non-Sendable type ... risks causing data races".

**(b) `#Predicate` limits** [verified at runtime, in-memory store]
- OK: `$0.name.localizedStandardContains(q)` (case/diacritic-insensitive; "NIL" matched "nil1"),
  `$0.lastPerformed == nil`, `($0.lastPerformed ?? past) < cutoff`, `$0.lastPerformed.flatMap { $0 < cutoff } == true`,
  optional relationship chain `$0.exercise?.name == "x" && $0.sideRaw == raw`, `$0.entries.count > 0`,
  `$0.entries.isEmpty`, `$0.entries.contains { $0.reps > 5 }`.
- `$0.name.contains(q)` is case-SENSITIVE (returned nothing for "NIL").
- Forced unwrap fails when `fetch` runs (not at compile time, so never `try!` a predicate fetch):
  `unsupportedPredicate "The 'Foundation.PredicateExpressions.ForcedUnwrap' operator is not supported"`.
- Comparing a stored enum property fails: `unsupportedPredicate "Captured/constant values of type 'Side' are
  not supported"` -> store `sideRaw: String` and expose `var side: Side` as a computed wrapper.
- Computed properties cannot appear in a predicate (they are not persisted keys) [source].
- iOS 27 (WWDC26) adds enum predicates and `Predicate(all:)/(any:)` -- not usable here.

**(c) Dynamic sort/filter from a parent** [verified type-check]. `@Query` is configured when the property
wrapper is created, so the parent passes values into a child view whose `init` builds the `Query`:
```swift
struct QueueList: View {
    @Query private var exercises: [Exercise]
    init(search: String) {
        let p: Predicate<Exercise>? = search.isEmpty ? nil
            : #Predicate<Exercise> { $0.name.localizedStandardContains(search) }
        _exercises = Query(filter: p,
                           sort: [SortDescriptor(\Exercise.lastPerformed, order: .forward),  // nil first
                                  SortDescriptor(\Exercise.name)],
                           animation: .default)
    }
    var body: some View { /* List over exercises */ }
}
```
SwiftUI re-runs the child's `init` when `search` changes, re-creating the query (https://www.hackingwithswift.com/quick-start/swiftdata/how-to-dynamically-change-a-querys-sort-order-or-predicate,
https://developer.apple.com/forums/thread/732575)

**(d) Optional `Date` sorting** [verified]: `SortDescriptor(\.lastPerformed, order: .forward)` puts **nil first**
both in a SwiftData fetch (SQLite) and in Foundation's in-memory `sorted(using:)`; `.reverse` puts nil last.
Result: `["nil1","nil2","b-old","a-recent"]`. Add `SortDescriptor(\.name)` as tie-breaker.
Denormalise `lastPerformed` on `Exercise` (update it when finalising) so the sort key lives on the queried model.

**(e) `@Attribute(.unique)` / `#Unique`** [verified]: inserting a second object with the same key and calling
`save()` upserted silently (one row, updated fields) for both `@Attribute(.unique)` and `#Unique<Exercise>([\.name])`.
Caveats [source]: until `save()` both objects exist in the context (duplicate-ID `ForEach` warnings, https://developer.apple.com/forums/thread/750839);
iOS 17-era crash reports on save (https://swiftdeveloper.ninja/swiftui-unique-attribute-bug/); unique constraints are incompatible with CloudKit.

**(f) Relationships** [verified cascade]: `@Relationship(deleteRule: .cascade, inverse: \PerformanceEntry.exercise)
var entries: [PerformanceEntry]` on the one side, `var exercise: Exercise?` on the many side; deleting the
exercise removed its entries. Default rule is `.nullify`. Declare `inverse:` on exactly one side; an explicit
inverse is required whenever either end is non-optional (https://fatbobman.com/en/posts/relationships-in-swiftdata-changes-and-considerations/,
https://www.hackingwithswift.com/quick-start/swiftdata/how-to-create-cascade-deletes-using-relationships).

**(g) Schema changes during development** [verified against an on-disk store]:
- Adding properties with inline defaults (`var notes = ""`, `var isUnilateral = false`, `var count = 0`): opened fine (automatic lightweight migration).
- Adding a non-optional property WITHOUT a default: `ModelContainer` init throws `SwiftDataError.loadIssueModelContainer`;
  CoreData log: 134110 "Validation error missing attribute values on mandatory destination attribute".
- Changing a property's type (`Date?` -> `String?`): throws `loadIssueModelContainer` (CoreData 134140, no mapping model).
- Simplest strategy: no `VersionedSchema` while iterating; give new fields defaults or make them optional;
  on failure delete the app / reset the simulator; use `isStoredInMemoryOnly: true` for previews/tests.
  In DEBUG you can catch the throw, delete `default.store*` and retry. Introduce `VersionedSchema` +
  `SchemaMigrationPlan` (`MigrationStage.lightweight(fromVersion:toVersion:)` / `.custom(...willMigrate:didMigrate:)`)
  only when shipping a change to users; a V2 for a change SwiftData handles automatically triggers
  "Duplicate version checksums across stages detected" (https://blakecrosley.com/blog/swiftdata-migrations-guide,
  https://developer.apple.com/videos/play/wwdc2025/291/).

**(h) What is new** [source]: iOS 18 / WWDC24 10137 added `#Index<Model>([\.a],[\.b])`, `#Unique`,
`@Attribute(.preserveValueOnDeletion)`, history API (https://developer.apple.com/videos/play/wwdc2024/10137/).
iOS 26 / WWDC25 291 "SwiftData: Dive into inheritance and schema migration": `@Model` class inheritance
(subclasses `@available(iOS 26, *)`), `#Predicate { $0 is PersonalTrip }`, `propertiesToFetch`,
`relationshipKeyPathsForPrefetching`, sorted/limited `HistoryDescriptor` (https://developer.apple.com/videos/play/wwdc2025/291/).
WWDC26 274 "What's new in SwiftData" = iOS 27 only: `@Query(sectionBy:)`, enum predicates, `Predicate(all:)/(any:)`,
`@Attribute(.codable)`, `ResultsObserver`, `HistoryObserver` (https://developer.apple.com/videos/play/wwdc2026/274/).
`#Index` on `lastPerformed` + `name` compiled and ran here.

**(i) Does `@Query` refresh on related-object changes?** [source + partial verification]
Models are `Observable` per instance: a row re-renders when a property of *its* object changes. `@Query` re-fetches
when the main context changes objects of the queried type. Inserting a `PerformanceEntry` and setting
`entry.exercise = ex` updated `ex.entries` (verified) and marks the exercise as changed, but the queue order only
changes when the sort key changes, so set `ex.lastPerformed` in the same `withAnimation` block. Changes made in
another context/`@ModelActor` are not observed until a save is merged; changes to nested child models are the classic
"UI does not update" case (https://developer.apple.com/forums/thread/761327, WWDC25 291 "not all changes are observable").

**(j) Store location / custom URL** [verified signatures]: default file is
`<app container>/Library/Application Support/default.store` (+ `-wal`, `-shm`). An in-memory config reports
`url == /dev/null`. Inits (SDK interface):
`ModelConfiguration(_ name: String? = nil, schema: Schema? = nil, isStoredInMemoryOnly: Bool = false, allowsSave: Bool = true, groupContainer: .automatic, cloudKitDatabase: .automatic)`
and `ModelConfiguration(_ name: String? = nil, schema: Schema? = nil, url: URL, allowsSave: Bool = true, cloudKitDatabase: .automatic)`.
```swift
let url = URL.applicationSupportDirectory.appending(path: "woq/woq.store")
let container = try ModelContainer(for: Exercise.self, PerformanceEntry.self,
                                   configurations: ModelConfiguration("woq", schema: nil, url: url))
```
For JSON export, fetch and encode DTOs rather than copying the SQLite file (WAL may hold unflushed data) (https://www.hackingwithswift.com/quick-start/swiftdata/how-to-change-swiftdatas-underlying-storage-filename).

## 2. SwiftUI Metal shaders

Names [verified type-check]: `ShaderLibrary.default` (main bundle `default.metallib`), `ShaderLibrary.bundle(_:)`
(use `.bundle(.module)` inside a Swift package), `@dynamicMemberLookup` -> `ShaderFunction`, calling it with
`Shader.Argument`s -> `Shader`. Modifiers: `.colorEffect(_:isEnabled:)`, `.distortionEffect(_:maxSampleOffset:isEnabled:)`,
`.layerEffect(_:maxSampleOffset:isEnabled:)` (all iOS 17+). `Shader.Argument`: `.float(_)`, `.float2(_:_:)`/`.float2(CGPoint)`,
`.float3`, `.float4`, `.color(Color)` -> `half4` premultiplied, `.boundingRect` -> `float4(x,y,w,h)`, `.floatArray`,
`.colorArray`, `.data`, `.image` (one per shader). Metal signatures (Apple docs):
`half4 f(float2 position, half4 color, args...)` for colorEffect, `float2 f(float2 position, args...)` for distortion,
`half4 f(float2 position, SwiftUI::Layer layer, args...)` for layerEffect; `layer.sample(float2)` is in the SDK header
`<SwiftUI/SwiftUI_Metal.h>` (`namespace SwiftUI { struct Layer { texture2d<half> tex; half4 sample(float2) const; } }`).
Gotchas:
- **Xcode 26 no longer bundles the Metal compiler.** This Mac lacks it: `xcrun metal` -> "cannot execute tool 'metal' due to
  missing Metal Toolchain; use: xcodebuild -downloadComponent MetalToolchain". Any target with a `.metal` file (and Previews)
  fails to build until Xcode > Settings > Components > Metal Toolchain is installed
  (https://developer.apple.com/forums/thread/805547). The shader below is therefore NOT compile-verified here [unverified].
- The `.metal` file must be in the app target's Compile Sources so it lands in `default.metallib`.
- Simulator + Previews + device all render SwiftUI shaders (https://developer.apple.com/forums/thread/764061); a UIKit-backed
  view inside the effect renders a placeholder and logs a warning (Apple docs).
- Argument order/types must match the Metal parameter list exactly; mismatches fail silently (view drawn unfiltered).
- Pass elapsed seconds, not `timeIntervalSinceReferenceDate` (~8e8 loses sub-second precision in `float`).
- Apply the shader to a background `Rectangle` (via `.listRowBackground` / `.background`), never to the row content
  with text fields: each shaded view is an extra offscreen raster pass every frame. `TimelineView(.animation)`
  redraws at display rate; use `minimumInterval: 1/30` and `paused:`; `isEnabled:` keeps the modifier tree stable.
```metal
#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;
// args after (position, color): bounds, time, phase, base, tint  -- must match the Swift call order
[[ stitchable ]] half4 waterFill(float2 position, half4 color, float4 bounds, float time, float phase,
                                 half4 base, half4 tint) {
    float2 uv = (position - bounds.xy) / max(bounds.zw, float2(1.0));
    float t = time * 0.35 + phase;
    float w = sin(uv.x * 4.0 + t)
            + sin((uv.x * 2.0 + uv.y * 3.0) * 1.7 - t * 1.3)
            + sin((uv.y * 5.0 - uv.x * 1.5) + t * 0.7 + phase * 2.0);
    half k = half(0.5 + 0.5 * (w / 3.0));                 // 0...1, slow caustic-like blend
    half4 c = mix(base, tint, k);
    return half4(c.rgb * color.a, color.a);               // stay premultiplied
}
```
```swift
struct WaterBackground: View {                 // [verified type-check]
    var reduceMotion: Bool
    @State private var start = Date()
    @State private var phase = Float.random(in: 0..<(2 * .pi))   // per-row random phase
    private let base = Color(red: 0.86, green: 0.93, blue: 0.98)
    private let tint = Color(red: 0.72, green: 0.86, blue: 0.97)
    var body: some View {
        if reduceMotion { Rectangle().fill(base) } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { ctx in
                let t = Float(ctx.date.timeIntervalSince(start))
                Rectangle().fill(base).colorEffect(
                    ShaderLibrary.default.waterFill(.boundingRect, .float(t), .float(phase), .color(base), .color(tint)))
            }
        }
    }
}
// usage: row.listRowBackground(WaterBackground(reduceMotion: reduceMotion)); reduceMotion from @Environment(\.accessibilityReduceMotion)
```
Sources: https://developer.apple.com/documentation/swiftui/view/coloreffect(_:isenabled:), https://developer.apple.com/documentation/swiftui/view/layereffect(_:maxsampleoffset:isenabled:),
https://developer.apple.com/documentation/swiftui/shader/argument, https://developer.apple.com/documentation/swiftui/shaderlibrary, https://www.createwithswift.com/custom-parameters-and-animation-with-metal-shaders/

## 3. iOS 26 and a flat, non-Liquid-Glass look

- `UIDesignRequiresCompatibility = YES` (Info.plist) restores the pre-26 look app-wide; Apple says it is for
  transition/debugging and will be removed in the next major SDK (Xcode 27) -- fine for an Xcode 26.6 build, but it
  cannot be applied per screen (https://www.donnywals.com/opting-your-app-out-of-the-liquid-glass-redesign-with-xcode-26/,
  https://developer.apple.com/forums/thread/799607).
- Per-view control (all names type-checked on SDK 26.5): `.scrollEdgeEffectStyle(.hard | .soft | .automatic, for: .top)`,
  `.scrollEdgeEffectHidden(true, for: .top)` (there is no `.hidden` style case), `.glassEffect()` /
  `.glassEffect(.regular.tint(.blue), in: .capsule)`, `GlassEffectContainer`, `.buttonStyle(.glass)` / `.glassProminent`,
  `.tabBarMinimizeBehavior(.onScrollDown)`, `.backgroundExtensionEffect()`, `.searchToolbarBehavior(.minimize | .automatic)`,
  `ToolbarSpacer`, `DefaultToolbarItem(kind: .search, placement: .bottomBar)`.
- Flat recipe: `.toolbar(.hidden, for: .navigationBar)` + your own header `VStack`; never call `glassEffect`;
  `.bordered`/`.borderedProminent` buttons become glass automatically on iOS 26, so use `.plain` or a custom `ButtonStyle`;
  `.scrollEdgeEffectStyle(.hard, for: .top)` (or hide it) under the custom header.
- Search: on iPhone, `.searchable` on a `NavigationStack` now lands in the **bottom** toolbar, or becomes a search tab
  in a `TabView` (WWDC25 323, https://nilcoalescing.com/blog/SwiftUISearchEnhancementsIniOSAndiPadOS26/). To keep it on
  top use `.searchable(text:placement: .navigationBarDrawer(displayMode: .always))` [source only:
  https://www.createwithswift.com/adapting-search-to-the-liquid-glass-design-system/]; for a plain field simply put a
  `TextField` + `magnifyingglass` in the custom header and pass the text to the child `@Query` view (what `patterns.swift` does).
- `List` on iOS 26 still supports `.listStyle(.plain)`, `.scrollContentBackground(.hidden)`, `.listRowBackground(_:)`,
  `.listRowSeparator(.hidden)`, `.listSectionSpacing(_:)` [type-checked]. Known 26.x issues: stray "ghost" separator lines
  in 26.1 even with separators hidden, `swipeActions` + `listRowBackground` corner styling
  (https://developer.apple.com/forums/thread/811328), Form row animations broken in 26 beta 3 (fixed in beta 4).
Sources: https://developer.apple.com/videos/play/wwdc2025/323/, https://developer.apple.com/documentation/swiftui/scrolledgeeffectstyle, https://developer.apple.com/documentation/swiftui/searchtoolbarbehavior

## 4. Numeric entry

- `TextField("kg", text:).keyboardType(.decimalPad)` and `.numberPad`; neither pad has a Return key, so `.onSubmit`
  never fires from them -- chain focus from a keyboard toolbar instead:
```swift
enum Field: Hashable { case weight(PersistentIdentifier), reps(PersistentIdentifier) }
@FocusState private var focus: Field?                       // owned by the List's parent view
TextField("kg", text: $weightText).keyboardType(.decimalPad)
    .focused($focus, equals: .weight(ex.persistentModelID))
.toolbar { ToolbarItemGroup(placement: .keyboard) {
    Button("Next") { focus = .reps(ex.persistentModelID) }; Spacer(); Button("Done") { focus = nil } } }
```
  Pass the focus binding down as `FocusState<Field?>.Binding` (verified). iOS 26 bug: `.keyboard` toolbar items add an
  extra gap above the keyboard (https://developer.apple.com/forums/thread/799692), and `@FocusState` fails for text fields
  placed inside a toolbar (https://developer.apple.com/forums/thread/797948).
- Locale parsing [verified with `Decimal.FormatStyle(locale: nl_NL)`]: `"12,5"` -> 12.5, `"1.234,5"` -> 1234.5, but
  `"12.5"` -> **12** (the dot is the Dutch grouping separator and the fraction is silently dropped); `Decimal(string:locale:)`
  behaves the same. The decimal-pad key follows the active keyboard/region and can differ from
  `Locale.current.decimalSeparator` (https://developer.apple.com/forums/thread/107269). Therefore keep a `String`
  binding and normalise:
```swift
nonisolated func parseDecimal(_ raw: String) -> Decimal? {
    let s = raw.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
    return Decimal(string: s, locale: Locale(identifier: "en_US_POSIX"))     // "12,5" and "12.5" -> 12.5
}
```
- `TextField("kg", value: $weight, format: .number)` type-checks and parses with the current locale (comma works in
  nl_NL), but the binding is only written on submit / focus loss, not per keystroke, and "12.5" in nl_NL becomes 12
  [source: https://www.hackingwithswift.com/quick-start/swiftui/how-to-format-a-textfield-for-numbers,
  https://developer.apple.com/forums/thread/715066]. Use it only for non-inline forms.
- `@FocusState` inside `List` rows: rows that scroll off screen are torn down (cell reuse), so per-row `@State` drafts
  and focus are lost; keep drafts keyed by `persistentModelID` in the parent (or on the model) and set focus only
  after `ScrollViewReader.scrollTo(id)`. `List` scrolls the focused field above the keyboard automatically
  (https://peterfriese.dev/blog/2021/swiftui-list-focus/, https://fatbobman.com/en/posts/textfield-event-focus-keyboard/).

## 5. Swift 6.3 + default MainActor isolation gotchas [verified]

- Every non-actor type/function in the module is MainActor unless marked. A helper called from a background task
  errors: "main actor-isolated static method 'key' cannot be called from outside of the actor" -> mark pure code
  `nonisolated func` / `nonisolated struct` (or a `nonisolated enum` namespace).
- Key paths of a MainActor-isolated value type are not `Sendable`: `SortDescriptor(\E.last)` on a plain
  `struct E` fails with "type 'KeyPath<E, Optional<Date>>' does not conform to the 'Sendable' protocol"; `nonisolated struct E`
  fixes it. Key paths on `@Model` classes worked without changes.
- `@Model` instances are non-Sendable (unavailable conformance, see 1a); capture them in `Task.detached` and you get
  "sending value of non-Sendable type ... risks causing data races". Send `PersistentIdentifier`s.
- With `NonisolatedNonsendingByDefault`, `nonisolated async` runs on the caller's actor; use `@concurrent` only for CPU-heavy work (SE-0461).
- Swift Testing under default MainActor (`swift test` with `.defaultIsolation(MainActor.self)`): `@Test` functions are
  MainActor-isolated and ran on the main thread (`Thread.isMainThread == true`); no explicit `@MainActor` needed; an
  in-memory container per test works:
```swift
@Suite struct QueueTests {
    @Test func neverPerformedFirst() throws {
        let container = try ModelContainer(for: Exercise.self, PerformanceEntry.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let ctx = ModelContext(container)                       // manual context: call save() yourself
        // insert..., try ctx.save()
        let fd = FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.lastPerformed, order: .forward)])
        #expect(try ctx.fetch(fd).map(\.name) == ["nil1", "nil2", "b-old", "a-recent"])
    }
}
```
  Tests run in parallel: never share a container across tests, or mark the suite `@Suite(.serialized)`.
  XCTest subclasses hit isolation errors under this setting (https://forums.swift.org/t/xctestcase-compiler-error-with-swift-6-2-default-actor-isolation-mainactor/83418);
  prefer Swift Testing. Xcode setting: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`
  (https://www.donnywals.com/setting-default-actor-isolation-in-xcode-26/, SE-0466 https://github.com/swiftlang/swift-evolution/blob/main/proposals/0466-control-default-actor-isolation.md).

## 6. Animating a row between two sections of one `List`

- `matchedGeometryEffect` across `List` rows is unreliable: rows are separate `UICollectionView` cells, reports show
  flicker/no morph, and the usual fix is `ScrollView` + `LazyVStack`
  (https://developer.apple.com/forums/thread/719835, https://developer.apple.com/forums/thread/681038) [unverified on device].
- What works: `@Query(..., animation: .default)` plus `withAnimation { ex.inProgress = false; ex.lastPerformed = .now }`.
  The List diff then animates: with two `ForEach`es it is a delete in one section + insert in the other (fade/slide);
  put both groups in ONE `ForEach` over a combined array (header rows as items) and the same identity becomes a
  real move animation. Keep identity stable: iterate the model objects (`Identifiable` via `persistentModelID`), never
  `.id(UUID())`; `.transition(...)` on rows only affects insert/remove. `ScrollViewReader.scrollTo(id, anchor: .top)`
  works with `List` rows carrying `.id(...)`.
- `List` vs `LazyVStack`: List = UICollectionView, cell reuse, `swipeActions`, `onDelete`, built-in keyboard avoidance,
  `listRowBackground` (fine for the shader). LazyVStack = pure SwiftUI, no reuse (per-row `@State` survives scrolling),
  free-form backgrounds/insets, better custom transitions/height animations, works with `matchedGeometryEffect`; costs: no
  swipe actions, manual separators, weaker fast-scroll estimation (https://fatbobman.com/en/posts/list-or-lazyvstack/).
  For a short queue with inline fields and shader backgrounds `List` is adequate; use `ScrollView { LazyVStack }` for a "flying" row morph.

## 7. Haptics [verified names]

`func sensoryFeedback<T: Equatable>(_ feedback: SensoryFeedback, trigger: T) -> some View` (iOS 17+), plus
`sensoryFeedback(_:trigger:condition:)` and `sensoryFeedback(trigger:_:)` (closure returns `SensoryFeedback?`).
Kinds: `.success .warning .error .selection .increase .decrease .start .stop .alignment .levelChange .impact .pathComplete`,
`.impact(weight: .light|.medium|.heavy, intensity:)`, `.impact(flexibility: .rigid|.solid|.soft, intensity:)`; new in iOS 26:
`.press(.button|.buttonIconOnly|.slider|.toggle|.tab)`, `.release(.slider)`, `.selection(.on|.off|.minimum|.maximum)`.
Plays when `trigger` changes; no-op on simulator/iPad. UIKit fallback: `UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.8)` (`prepare()` first).
(https://developer.apple.com/documentation/swiftui/view/sensoryfeedback(_:trigger:),
https://developer.apple.com/documentation/swiftui/sensoryfeedback, https://useyourloaf.com/blog/swiftui-sensory-feedback/)

## 8. SF Symbols [verified against macOS 26 CoreGlyphs `name_availability.plist`, latest release key 2025.1 = SF Symbols 7.1]

| name | since | | name | since |
|---|---|---|---|---|
| `plus`, `checkmark`, `magnifyingglass` | iOS 13 | | `figure.strengthtraining.traditional` | iOS 16 |
| `trash`, `xmark`, `chevron.right` | iOS 13 | | `dumbbell` / `dumbbell.fill` | iOS 16 |
| `calendar`, `clock` | iOS 13 | | `arrow.uturn.backward` | iOS 14 |
All exist on iOS 26 (`Image(systemName:)` calls type-checked); SF Symbols 7 adds none of these, so no availability checks needed.

## Uncertainties / not verified here
1. Why `@Model` classes escape default MainActor inference in Swift 6.3.3 (empirical only); use explicit `nonisolated`.
2. The Metal function is unverified because the Metal Toolchain is not installed on this Mac (install it before adding `.metal` files).
3. `.navigationBarDrawer(displayMode: .always)` keeping search on top on iOS 26 iPhone comes from a blog, not tested.
4. `TextField(value:format:)` commit-on-focus-loss behaviour is from HWS/forums, not re-tested on iOS 26.
5. Cross-section List move animation details and `matchedGeometryEffect` failure are from forum reports + experience.
6. `@Query` refresh semantics for relationship-only changes are inferred from docs/forums; keep the sort key on `Exercise`.
