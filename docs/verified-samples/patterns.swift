import SwiftUI
import SwiftData
import UIKit

// MARK: - Models
enum Side: String, Codable, CaseIterable, Sendable { case left, right, both }

@Model nonisolated final class Exercise {
    #Index<Exercise>([\.lastPerformed])
    var name: String
    var isUnilateral: Bool
    var lastPerformed: Date?          // denormalised "last performed" -> sort key
    var inProgress: Bool
    @Relationship(deleteRule: .cascade, inverse: \PerformanceEntry.exercise)
    var entries: [PerformanceEntry]
    init(name: String, isUnilateral: Bool = false) {
        self.name = name; self.isUnilateral = isUnilateral
        self.lastPerformed = nil; self.inProgress = false; self.entries = []
    }
}

@Model nonisolated final class PerformanceEntry {
    var date: Date
    var weight: Double
    var reps: Int
    var sideRaw: String               // enum stored as rawValue so it can be used in #Predicate
    var side: Side { get { Side(rawValue: sideRaw) ?? .both } set { sideRaw = newValue.rawValue } }
    var exercise: Exercise?
    init(date: Date, weight: Double, reps: Int, side: Side) {
        self.date = date; self.weight = weight; self.reps = reps; self.sideRaw = side.rawValue
    }
}

// MARK: - 1(c) dynamic @Query needs a child view
struct QueueList: View {
    @Query private var exercises: [Exercise]
    var focus: FocusState<Field?>.Binding
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.modelContext) private var context
    @State private var hapticTick = 0

    init(search: String, focus: FocusState<Field?>.Binding) {
        let predicate: Predicate<Exercise>? = search.isEmpty ? nil
            : #Predicate<Exercise> { $0.name.localizedStandardContains(search) }
        _exercises = Query(filter: predicate,
                           sort: [SortDescriptor(\Exercise.lastPerformed, order: .forward),   // nil first
                                  SortDescriptor(\Exercise.name)],
                           animation: .default)
        self.focus = focus
    }

    var body: some View {
        List {
            Section("In progress") {
                ForEach(exercises.filter(\.inProgress)) { ex in
                    InProgressRow(exercise: ex, focus: focus) { weight, reps, side in
                        finalize(ex, weight: weight, reps: reps, side: side)
                    }
                    .listRowBackground(WaterBackground(reduceMotion: reduceMotion))
                    .listRowSeparator(.hidden)
                }
            }
            Section("Queue") {
                ForEach(exercises.filter { !$0.inProgress }) { ex in
                    HStack {
                        Image(systemName: "figure.strengthtraining.traditional")
                        Text(ex.name)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { withAnimation { ex.inProgress = true }; hapticTick += 1 }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .listSectionSpacing(12)
        .background(Color(red: 0.98, green: 0.97, blue: 0.94))   // "paper"
        .sensoryFeedback(.impact(weight: .medium, intensity: 0.8), trigger: hapticTick)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focus.wrappedValue = nil }
            }
        }
    }

    private func finalize(_ ex: Exercise, weight: Double, reps: Int, side: Side) {
        withAnimation {
            let entry = PerformanceEntry(date: .now, weight: weight, reps: reps, side: side)
            entry.exercise = ex
            context.insert(entry)
            ex.lastPerformed = entry.date     // touch the sort key on the parent
            ex.inProgress = false
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.8)  // UIKit fallback
    }
}

enum Field: Hashable { case weight(PersistentIdentifier), reps(PersistentIdentifier) }

// MARK: - 4 numeric entry
struct InProgressRow: View {
    let exercise: Exercise
    var focus: FocusState<Field?>.Binding
    var onFinalize: (Double, Int, Side) -> Void
    @State private var weightText = ""
    @State private var repsText = ""
    @State private var side: Side = .both

    var body: some View {
        HStack {
            Text(exercise.name)
            TextField("kg", text: $weightText)
                .keyboardType(.decimalPad)
                .focused(focus, equals: .weight(exercise.persistentModelID))
                .onSubmit { focus.wrappedValue = .reps(exercise.persistentModelID) }
            TextField("reps", text: $repsText)
                .keyboardType(.numberPad)
                .focused(focus, equals: .reps(exercise.persistentModelID))
            Button { 
                if let w = parseDecimal(weightText), let r = Int(repsText) {
                    onFinalize(NSDecimalNumber(decimal: w).doubleValue, r, side)
                }
            } label: { Image(systemName: "checkmark") }
            .buttonStyle(.plain)
        }
    }
}

/// Accept both "," and "." regardless of keyboard/region; pure helper opted out of MainActor.
nonisolated func parseDecimal(_ raw: String) -> Decimal? {
    let s = raw.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
    return Decimal(string: s, locale: Locale(identifier: "en_US_POSIX"))
}

// MARK: - 2 shader background
struct WaterBackground: View {
    var reduceMotion: Bool
    @State private var start = Date()
    @State private var phase = Float.random(in: 0..<(2 * .pi))
    private let base = Color(red: 0.86, green: 0.93, blue: 0.98)
    private let tint = Color(red: 0.72, green: 0.86, blue: 0.97)

    var body: some View {
        if reduceMotion {
            Rectangle().fill(base)
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { ctx in
                let t = Float(ctx.date.timeIntervalSince(start))      // small number -> float precision OK
                Rectangle().fill(base)
                    .colorEffect(
                        ShaderLibrary.default.waterFill(.boundingRect, .float(t), .float(phase), .color(base), .color(tint)),
                        isEnabled: true)
            }
        }
    }
}

// MARK: - 3 root with custom header, flat look
struct ContentView: View {
    @State private var search = ""
    @FocusState private var focus: Field?
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search exercises", text: $search).textFieldStyle(.plain)
                    if !search.isEmpty { Button { search = "" } label: { Image(systemName: "xmark") } }
                }
                .padding()
                QueueList(search: search, focus: $focus)
            }
            .toolbar(.hidden, for: .navigationBar)
            .scrollEdgeEffectStyle(.hard, for: .top)
        }
    }
}

// MARK: - iOS 26 API name checks (not used by the app, only to prove the names compile)
struct NamesCheck: View {
    @State private var q = ""
    @Namespace private var ns
    var body: some View {
        TabView {
            Tab("A", systemImage: "plus") {
                NavigationStack {
                    ScrollView { Text("x").matchedGeometryEffect(id: "t", in: ns) }
                        .searchable(text: $q, placement: .navigationBarDrawer(displayMode: .always))
                        .searchToolbarBehavior(.minimize)
                        .scrollEdgeEffectHidden(true, for: .top)
                        .backgroundExtensionEffect()
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .overlay {
            VStack {
                Button("Glass") {}.buttonStyle(.glass)
                Button("Prominent") {}.buttonStyle(.glassProminent)
                Text("g").glassEffect()
                Text("g2").glassEffect(.regular.tint(.blue), in: .capsule)
                Image(systemName: "arrow.uturn.backward"); Image(systemName: "trash"); Image(systemName: "calendar"); Image(systemName: "clock"); Image(systemName: "dumbbell")
            }
            .sensoryFeedback(.selection, trigger: q)
            .sensoryFeedback(.press(.button), trigger: q)   // iOS 26+
        }
    }
}

// MARK: - 5 TextField(value:format:) variant
struct FormatFieldCheck: View {
    @State private var weight: Double?
    var body: some View { TextField("kg", value: $weight, format: .number).keyboardType(.decimalPad) }
}
