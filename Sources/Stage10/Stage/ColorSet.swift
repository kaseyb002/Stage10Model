import Foundation

public struct ColorSet: Equatable, Codable {
    public let requiredCount: Int
    public let color: CardColor
    public private(set) var cards: [Card]
    
    public init(
        requiredCount: Int,
        color: CardColor,
        cards: [Card]
    ) throws {
        self.cards = try Self.validated(
            cards: cards,
            color: color,
            requiredCount: requiredCount
        )
        self.requiredCount = requiredCount
        self.color = color
    }
    
    public mutating func add(
        numberCard: NumberCard
    ) throws {
        guard numberCard.color == color else {
            throw FailedObjectiveError.invalidCard
        }
        cards.append(.number(numberCard))
    }
    
    public mutating func add(
        wildCard: WildCard
    ) throws {
        var updatedWildCard: WildCard = wildCard
        try updatedWildCard.use(as: .color(color))
        cards.append(.wild(updatedWildCard))
    }

    private static func validated(
        cards: [Card],
        color: CardColor,
        requiredCount: Int
    ) throws -> [Card] {
        if cards.count < requiredCount {
            throw FailedObjectiveError.insufficientCards
        }
        var validCards: [Card] = []
        for card in cards {
            switch card {
            case .skip:
                continue
                
            case .wild(let wild):
                if wild.isUsed {
                    continue
                }
                var updatedWild: WildCard = wild
                try updatedWild.use(as: .color(color))
                validCards.append(.wild(updatedWild))
                
            case .number(let numberCard):
                if numberCard.color == color {
                    validCards.append(.number(numberCard))
                }
            }
        }
        
        guard validCards.count >= requiredCount else {
            throw FailedObjectiveError.setNotBigEnough(countNeeded: requiredCount - validCards.count)
        }
        
        return validCards
    }
}
