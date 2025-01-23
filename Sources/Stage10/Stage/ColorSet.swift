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
        card: Card
    ) throws {
        try cards.add(card: card, color: color)
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
            try validCards.add(card: card, color: color)
        }
        guard validCards.count >= requiredCount else {
            throw FailedObjectiveError.setNotBigEnough(countNeeded: requiredCount - validCards.count)
        }
        return validCards
    }
}

private extension [Card] {
    mutating func add(
        card: Card,
        color: CardColor
    ) throws {
        switch card.cardType {
        case .skip:
            throw FailedObjectiveError.invalidCard
            
        case .wild(let wildCard):
            var updatedWildCard: WildCard = wildCard
            try updatedWildCard.use(as: .color(color))
            var updatedCard: Card = card
            updatedCard.cardType = .wild(updatedWildCard)
            append(updatedCard)
            
        case .number(let numberCard):
            guard numberCard.color == color else {
                throw FailedObjectiveError.invalidCard
            }
            append(card)
        }
    }
}
