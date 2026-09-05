import Foundation

/// What is wrong with a draft, in the order the UI should complain about it.
nonisolated enum DraftProblem: Error, Equatable {
    /// Weight is a number but not a multiple of 0.5.
    case weightNotHalfStep
    /// Weight is a multiple of 0.5 but outside 0.5...500 kg (so "0" lands here).
    case weightOutOfRange
    /// Weight is not a number at all.
    case weightNotANumber
    /// Reps (left side when unilateral) empty.
    case repsMissing
    /// Right-side reps empty on a unilateral exercise.
    case repsRightMissing
    /// Reps present but not an integer in 1...999.
    case repsInvalid
}

/// A validated set, ready for `QueueStore.finalize(_:with:at:)`.
nonisolated struct ValidatedSet: Sendable, Equatable {
    /// nil = bodyweight. 45 == 22.5 kg.
    let weightHalfKilos: Int?
    /// Bilateral reps, or LEFT reps when unilateral.
    let reps: Int
    /// Right-side reps, nil when bilateral.
    let repsRight: Int?

    init(weightHalfKilos: Int?, reps: Int, repsRight: Int?) {
        self.weightHalfKilos = weightHalfKilos
        self.reps = reps
        self.repsRight = repsRight
    }
}

/// In-progress form state for one exercise. Pure view state: never persisted, discarded
/// on put-back (PLAN.md 3.4 and 3.6).
///
/// Parsing follows PLAN.md pitfall 26: trim, replace "," with ".", then
/// `Decimal(string:locale: en_US_POSIX)`. Never a locale-aware format style — in nl_NL
/// "12.5" silently becomes 12.
nonisolated struct SetDraft: Equatable, Sendable {
    var weightText = ""
    var repsText = ""
    var repsRightText = ""

    init(weightText: String = "", repsText: String = "", repsRightText: String = "") {
        self.weightText = weightText
        self.repsText = repsText
        self.repsRightText = repsRightText
    }

    // MARK: - Limits

    /// 0.5 kg in half-kilos.
    static let minWeightHalfKilos = 1
    /// 500 kg in half-kilos.
    static let maxWeightHalfKilos = 1000
    static let minReps = 1
    static let maxReps = 999

    // MARK: - Validation

    /// True when nothing has been typed at all (used by "add exercise" to decide between
    /// starting the exercise and queueing it, PLAN.md section 2 "New exercise").
    var isEmpty: Bool {
        Self.trimmed(weightText).isEmpty
            && Self.trimmed(repsText).isEmpty
            && Self.trimmed(repsRightText).isEmpty
    }

    /// The weight problem only, for the inline red hint under the weight field.
    /// nil means the weight is acceptable (including empty = bodyweight).
    func weightProblem() -> DraftProblem? {
        switch Self.parseWeight(weightText) {
        case .success: nil
        case .failure(let problem): problem
        }
    }

    /// True when `validate(isUnilateral:)` would succeed.
    func isComplete(isUnilateral: Bool) -> Bool {
        switch validate(isUnilateral: isUnilateral) {
        case .success: true
        case .failure: false
        }
    }

    /// Weight first (so its inline hint appears while reps are still empty), then reps,
    /// then the right side.
    func validate(isUnilateral: Bool) -> Result<ValidatedSet, DraftProblem> {
        let weight: Int?
        switch Self.parseWeight(weightText) {
        case .success(let value): weight = value
        case .failure(let problem): return .failure(problem)
        }

        let reps: Int
        switch Self.parseReps(repsText, missing: .repsMissing) {
        case .success(let value): reps = value
        case .failure(let problem): return .failure(problem)
        }

        var repsRight: Int?
        if isUnilateral {
            switch Self.parseReps(repsRightText, missing: .repsRightMissing) {
            case .success(let value): repsRight = value
            case .failure(let problem): return .failure(problem)
            }
        }

        return .success(ValidatedSet(weightHalfKilos: weight, reps: reps, repsRight: repsRight))
    }

    // MARK: - Parsing

    /// Trims whitespace and normalises the decimal comma to a dot.
    static func normalised(_ raw: String) -> String {
        trimmed(raw).replacingOccurrences(of: ",", with: ".")
    }

    private static func trimmed(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Empty text is a valid bodyweight set (`.success(nil)`).
    /// Otherwise the value must be a multiple of 0.5 within 0.5...500 kg.
    static func parseWeight(_ raw: String) -> Result<Int?, DraftProblem> {
        let text = normalised(raw)
        guard !text.isEmpty else { return .success(nil) }
        guard let decimal = Decimal(string: text, locale: Locale(identifier: "en_US_POSIX")),
              decimal.isFinite
        else { return .failure(.weightNotANumber) }

        var doubled = decimal * 2
        var rounded = Decimal()
        NSDecimalRound(&rounded, &doubled, 0, .plain)
        guard rounded == doubled else { return .failure(.weightNotHalfStep) }

        let halfKilos = NSDecimalNumber(decimal: rounded).intValue
        guard halfKilos >= minWeightHalfKilos, halfKilos <= maxWeightHalfKilos else {
            return .failure(.weightOutOfRange)
        }
        return .success(halfKilos)
    }

    /// Reps must be a plain integer in 1...999.
    static func parseReps(_ raw: String, missing: DraftProblem) -> Result<Int, DraftProblem> {
        let text = normalised(raw)
        guard !text.isEmpty else { return .failure(missing) }
        guard let value = Int(text), value >= minReps, value <= maxReps else {
            return .failure(.repsInvalid)
        }
        return .success(value)
    }

    // MARK: - Text helpers

    /// Text for the "same as last time" fill. nil (bodyweight) gives an empty field.
    /// 45 -> "22.5", 80 -> "40".
    static func weightText(fromHalfKilos halfKilos: Int?) -> String {
        guard let halfKilos else { return "" }
        let whole = halfKilos / 2
        return halfKilos % 2 == 0 ? "\(whole)" : "\(whole).5"
    }

    /// Text for a reps field.
    static func repsText(fromReps reps: Int?) -> String {
        guard let reps else { return "" }
        return "\(reps)"
    }

    // MARK: - Stepping (+/- buttons)

    /// Steps the weight text by `halfSteps` half-kilos (one tap = +/-1 = 0.5 kg).
    ///
    /// Rule (documented deviation, see the report): the value is first snapped to a
    /// half-kilo grid IN THE DIRECTION OF THE STEP (floor when stepping up, ceil when
    /// stepping down) and the snap counts as the first step. So "22.3" +1 -> "22.5" and
    /// "22.3" -1 -> "22", while a value already on the grid simply moves one step.
    /// Empty (or unparseable) text counts as 0: +1 -> "0.5"; stepping down from empty
    /// stays empty, because empty means bodyweight and stepping down must not invent a weight.
    /// The result is clamped to 0.5...500 kg.
    static func steppedWeightText(_ text: String, by halfSteps: Int) -> String {
        guard halfSteps != 0 else { return text }
        let normalisedText = normalised(text)
        let current = Decimal(string: normalisedText, locale: Locale(identifier: "en_US_POSIX"))
        let isBlank = normalisedText.isEmpty || current == nil || !(current?.isFinite ?? false)

        if isBlank && halfSteps < 0 { return "" }

        var doubled = (current ?? 0) * 2
        var snapped = Decimal()
        NSDecimalRound(&snapped, &doubled, 0, halfSteps > 0 ? .down : .up)

        let base = NSDecimalNumber(decimal: snapped).intValue
        let stepped = base + halfSteps
        let clamped = min(max(stepped, minWeightHalfKilos), maxWeightHalfKilos)
        return weightText(fromHalfKilos: clamped)
    }

    /// Steps the reps text by `steps`, clamped to 1...999. Empty counts as 0, so +1 -> "1"
    /// and -1 -> "1" (the minimum).
    static func steppedRepsText(_ text: String, by steps: Int) -> String {
        let current = Int(normalised(text)) ?? 0
        let clamped = min(max(current + steps, minReps), maxReps)
        return "\(clamped)"
    }
}
