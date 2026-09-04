import Foundation

nonisolated struct E { let name: String; let last: Date? }
let now = Date()
let items = [
    E(name: "b-old", last: now.addingTimeInterval(-864000)),
    E(name: "nil1", last: nil),
    E(name: "a-recent", last: now),
    E(name: "nil2", last: nil),
]
print("Foundation SortDescriptor forward:", items.sorted(using: SortDescriptor(\E.last, order: .forward)).map(\.name))
print("Foundation SortDescriptor reverse:", items.sorted(using: SortDescriptor(\E.last, order: .reverse)).map(\.name))

let nl = Locale(identifier: "nl_NL")
print("nl_NL decimalSep:", nl.decimalSeparator ?? "nil", "grouping:", nl.groupingSeparator ?? "nil")
let style = Decimal.FormatStyle(locale: nl)
func p(_ s: String) -> String { (try? Decimal(s, format: style)).map { "\($0)" } ?? "nil" }
for s in ["12,5", "12.5", "1.234,5", "1,234.5", "12", "", "abc", "12,5,3", "12,"] { print("Decimal(\"\(s)\", format nl_NL) =", p(s)) }
let dstyle = FloatingPointFormatStyle<Double>(locale: nl)
print("Double(\"12,5\", format nl):", (try? Double("12,5", format: dstyle)) as Any)
print("Double(\"12.5\", format nl):", (try? Double("12.5", format: dstyle)) as Any)
print("Decimal(string:\"12,5\", locale: nl):", Decimal(string: "12,5", locale: nl) as Any)
print("Decimal(string:\"12.5\", locale: nl):", Decimal(string: "12.5", locale: nl) as Any)
print("Decimal(string:\"12.5\") no locale:", Decimal(string: "12.5") as Any)
print("Decimal(string:\"12,5\") no locale:", Decimal(string: "12,5") as Any)
print("formatted 12.5 nl:", Decimal(12.5).formatted(style))
