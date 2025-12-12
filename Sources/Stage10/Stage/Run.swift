import Foundation

public struct Run: Equatable, Codable, Sendable {
    public let requiredLength: Int
    public private(set) var cards: [Card]
    
    public init(
        requiredLength: Int,
        cards: [Card]
    ) throws {
        if requiredLength < 4 {
            throw Stage10Error.requiredLengthBelowMin
        }
        if requiredLength > 9 {
            throw Stage10Error.requiredLengthAboveMax
        }
        self.requiredLength = requiredLength
        self.cards = try Self.validated(
            cards: cards,
            requiredLength: requiredLength
        )
    }
    
    public enum AddPosition: Equatable, Codable, Sendable {
        case beginning
        case end
    }
    
    public mutating func add(
        card: Card,
        position: AddPosition
    ) throws {
        try cards.add(
            card: card,
            position: position
        )
    }
    
    private static func validated(
        cards: [Card],
        requiredLength: Int
    ) throws -> [Card] {
        guard cards.count >= requiredLength,
              let firstCard: Card = cards.first
        else {
            throw Stage10Error.insufficientCards
        }
        var validCards: [Card] = [firstCard]
        for card in cards.suffix(from: 1) {
            try validCards.add(card: card, position: .end)
        }
        return cards
    }
}

private extension [Card] {
    mutating func add(
        card: Card,
        position: Run.AddPosition
    ) throws {
        switch card.cardType {
        case .skip:
            throw Stage10Error.invalidCard
            
        case .wild(let wildCard):
            var updatedWild: WildCard = wildCard
            switch position {
            case .beginning:
                guard let nextMinValidCardNumber else {
                    throw Stage10Error.runReachedEnd
                }
                try updatedWild.use(as: .number(nextMinValidCardNumber))
                var updatedCard: Card = card
                updatedCard.cardType = .wild(updatedWild)
                insert(updatedCard, at: .zero)
                
            case .end:
                guard let nextMaxValidCardNumber else {
                    throw Stage10Error.runReachedEnd
                }
                try updatedWild.use(as: .number(nextMaxValidCardNumber))
                var updatedCard: Card = card
                updatedCard.cardType = .wild(updatedWild)
                append(updatedCard)
            }
            
        case .number(let numberCard):
            switch position {
            case .beginning:
                guard numberCard.number == nextMinValidCardNumber else {
                    throw Stage10Error.isNotValidNextCard
                }
                insert(card, at: .zero)
                
            case .end:
                guard numberCard.number == nextMaxValidCardNumber else {
                    throw Stage10Error.isNotValidNextCard
                }
                append(card)
            }
        }
    }
    
    var nextMinValidCardNumber: CardNumber? {
        guard let number: CardNumber = first?.cardType.numberValue,
              number > CardNumber.min
        else {
            return nil
        }
        return CardNumber(rawValue: number.rawValue - 1)
    }
    
    var nextMaxValidCardNumber: CardNumber? {
        guard let number: CardNumber = last?.cardType.numberValue,
              number < CardNumber.max
        else {
            return nil
        }
        return CardNumber(rawValue: number.rawValue + 1)
    }
}
