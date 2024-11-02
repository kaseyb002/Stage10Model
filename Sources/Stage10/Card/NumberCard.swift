import Foundation

public struct NumberCard: Equatable, Comparable {
    public let number: CardNumber
    public let color: CardColor
    
    public static func < (
        lhs: NumberCard,
        rhs: NumberCard
    ) -> Bool {
        lhs.number < rhs.number
    }
    
    public init(
        number: CardNumber,
        color: CardColor
    ) {
        self.number = number
        self.color = color
    }
}
