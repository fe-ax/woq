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

    /// True while either reps field holds text. The card's checkmark rule since
    /// 2026-09-13: reps typed = "add this set and finish", reps empty = "finish with the
    /// pending sets". Whether the typed reps are *valid* is a separate question
    /// (`isComplete`); this only decides which of the two the button is.
    var hasReps: Bool {
        !Self.trimmed(repsText).isEmpty || !Self.trimmed(repsRightText).isEmpty
    }

    /// Empties both reps fields and keeps the weight: the state after a set was committed
    /// with the plus (2026-09-13), so the next set's reps are typed or stepped fresh and the
    /// checkmark falls back to plain "finish". The weight stays because the next set is
    /// usually the same weight.
    mutating func clearReps() {
        repsText = ""
        repsRightText = ""
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
        // `Decimal(string:)` parses a PREFIX ("40kg" -> 40, "--" -> 0), so the shape is
        // checked first: digits with at most one decimal point, nothing else (found by the
        // first test suite, 2026-09-12). The decimal pad cannot type anything else, but a
        // paste can.
        guard isPlainDecimal(text),
              let decimal = Decimal(string: text, locale: Locale(identifier: "en_US_POSIX")),
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

    /// "40", "40.", "40.5", ".5", "-5": an optional leading "-", ASCII digits with at most one
    /// "." and at least one digit. No exponent, no second point, no letters. A negative number
    /// is well formed and then fails the RANGE check, which is the more honest message.
    static func isPlainDecimal(_ text: String) -> Bool {
        var sawDigit = false
        var sawPoint = false
        for (offset, character) in text.enumerated() {
            if character.isASCII, character.isNumber {
                sawDigit = true
            } else if character == "." && !sawPoint {
                sawPoint = true
            } else if character == "-" && offset == 0 {
                continue
            } else {
                return false
            }
        }
        return sawDigit
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

    /// The fields for repeating a set (the card's prefill): its numbers as text, an empty
    /// weight for bodyweight, and the right side only on a unilateral exercise — falling back
    /// to the left reps for a set logged before the exercise was switched to L/R.
    static func prefilled(weightHalfKilos: Int?, reps: Int, repsRight: Int?, isUnilateral: Bool) -> SetDraft {
        SetDraft(
            weightText: weightText(fromHalfKilos: weightHalfKilos),
            repsText: repsText(fromReps: reps),
            repsRightText: isUnilateral ? repsText(fromReps: repsRight ?? reps) : ""
        )
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

/// A set committed with the card's plus button, waiting for the checkmark
/// (PLAN.md "Multi-set executions", 2026-09-12).
///
/// View state, never persisted: the whole list is written as ONE execution when the checkmark
/// is tapped (`QueueStore.finalize(_:with:at:)`), so a session is one store write and one
/// debounced backup. Quitting the app loses pending sets, exactly like a half-typed draft.
///
/// `id` is a fresh UUID per pending row, not the future `Entry.id`: two identical sets
/// ("40 kg × 10" twice) must stay two distinct rows in the list and in `ForEach`.
/// `loggedAt` is when the plus was tapped, and becomes that set's `Entry.date`, so the
/// history keeps the real per-set timing instead of stamping them all at the checkmark.
///
/// Since 2026-09-13 a pending set can also come the other way: "Continue" on the last
/// finished row takes an execution back out of the store (`QueueStore.reopenLastExecution`)
/// and its entries become pending sets again, keeping their dates and their notes.
nonisolated struct PendingSet: Identifiable, Sendable, Equatable {
    let id: UUID
    var set: ValidatedSet
    var loggedAt: Date
    /// The set's note, carried through a reopen so the second checkmark writes it back.
    /// Always nil for a set committed with the plus: notes are only typed afterwards, in the
    /// detail sheet, and the card never shows them.
    var notes: String?

    init(set: ValidatedSet, loggedAt: Date = .now, notes: String? = nil) {
        self.id = UUID()
        self.set = set
        self.loggedAt = loggedAt
        self.notes = notes
    }
}

/// Everything the in-progress card holds for one exercise: the fields the user is typing in
/// and the sets already committed with the plus button.
///
/// This is the unit `MainScreen` keeps per exercise — the live card, and the kept draft that
/// put-back stores and the next start restores (PLAN.md 3.6). Pure view state; `QueueStore`
/// only ever sees the validated result.
nonisolated struct CardDraft: Equatable, Sendable {
    /// The weight / reps fields, i.e. the set being typed right now.
    var fields: SetDraft = SetDraft()
    /// Sets already committed with the plus button, in the order they were logged.
    var pending: [PendingSet] = []

    init(fields: SetDraft = SetDraft(), pending: [PendingSet] = []) {
        self.fields = fields
        self.pending = pending
    }

    /// The plus: the validated fields join the pending list and the reps are cleared
    /// (2026-09-13). `set` is the validated form of `fields` — the caller validates, so the
    /// draft strings stay the single source of truth for what is in the boxes.
    mutating func addPendingSet(_ set: ValidatedSet, loggedAt: Date = .now) {
        pending.append(PendingSet(set: set, loggedAt: loggedAt))
        fields.clearReps()
    }

    /// What the card's checkmark does right now — the two-mode checkmark Marco asked for on
    /// 2026-09-13 after "+" next to "+✓" kept confusing. With reps typed the button is "+✓":
    /// the fields become the last set, so they have to validate. With the reps empty it is a
    /// plain "✓": the pending list is saved as it is (the weight box is not even read) and
    /// needs at least one set — an execution without sets does not exist.
    func finishAction(isUnilateral: Bool) -> FinishAction {
        if fields.hasReps {
            guard case .success(let set) = fields.validate(isUnilateral: isUnilateral) else {
                return .disabled
            }
            return .addAndFinish(set)
        }
        return pending.isEmpty ? .disabled : .finishPending
    }
}

/// What the in-progress card's checkmark will do, from `CardDraft.finishAction(isUnilateral:)`.
nonisolated enum FinishAction: Equatable, Sendable {
    /// Nothing to save (reps typed but invalid, or reps empty and nothing pending).
    case disabled
    /// Reps empty, pending sets present: save the pending list as the execution.
    case finishPending
    /// Reps typed and valid: the fields become the last set, then save.
    case addAndFinish(ValidatedSet)
}
