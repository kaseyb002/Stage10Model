import Foundation

public enum CardNumber: Int, Equatable, Comparable, CaseIterable, Sendable {
    case one = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    case six = 6
    case seven = 7
    case eight = 8
    case nine = 9
    case ten = 10
    case eleven = 11
    case twelve = 12
    
    public static var min: CardNumber { .allCases.first! }
    public static var max: CardNumber { .allCases.last! }

    public static func < (
        lhs: CardNumber,
        rhs: CardNumber
    ) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
