import Foundation

public struct NumberSet: Equatable, Codable {
    public let requiredCount: Int
    public let number: CardNumber
    public private(set) var cards: [Card]
    
    public init(
        requiredCount: Int,
        number: CardNumber,
        cards: [Card]
    ) throws {
        self.cards = try Self.validated(
            cards: cards,
            number: number,
            requiredCount: requiredCount
        )
        self.requiredCount = requiredCount
        self.number = number
    }
    
    public mutating func add(
        card: Card
    ) throws {
        try cards.add(card: card, number: number)
    }

    private static func validated(
        cards: [Card],
        number: CardNumber,
        requiredCount: Int
    ) throws -> [Card] {
        if cards.count < requiredCount {
            throw Stage10Error.insufficientCards
        }
        var validCards: [Card] = []
        for card in cards {
            try validCards.add(card: card, number: number)
        }
        guard validCards.count >= requiredCount else {
            throw Stage10Error.setNotBigEnough(countNeeded: requiredCount - validCards.count)
        }
        return validCards
    }
}

private extension [Card] {
    mutating func add(
        card: Card,
        number: CardNumber
    ) throws {
        switch card.cardType {
        case .skip:
            throw Stage10Error.invalidCard
            
        case .wild(let wild):
            var updatedWild: WildCard = wild
            try updatedWild.use(as: .number(number))
            var updatedCard: Card = card
            updatedCard.cardType = .wild(updatedWild)
            append(updatedCard)
            
        case .number(let numberCard):
            guard numberCard.number == number else {
                throw Stage10Error.invalidCard
            }
            append(card)
        }
    }
}
