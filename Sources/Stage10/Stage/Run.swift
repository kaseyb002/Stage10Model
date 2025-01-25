import Foundation

public struct Run: Equatable, Codable {
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
    
    public enum AddPosition: Equatable, Codable {
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
        guard cards.count >= requiredLength else {
            throw Stage10Error.insufficientCards
        }
        let sortedCards: [Card] = cards.sorted(by: { ($0.cardType.numberValue ?? .max) < ($1.cardType.numberValue ?? .max) })
        guard let firstCard: Card = sortedCards.first else {
            throw Stage10Error.invalidCard
        }
        var validCards: [Card] = [firstCard]
        for card in sortedCards.suffix(from: 1) {
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
                switch wildCard.usedAs {
                case .number(let cardNumber):
                    guard cardNumber == nextMinValidCardNumber else {
                        throw Stage10Error.invalidCard
                    }
                    
                case .color:
                    throw Stage10Error.invalidCard

                case nil:
                    try updatedWild.use(as: .number(nextMinValidCardNumber))
                }
                var updatedCard: Card = card
                updatedCard.cardType = .wild(updatedWild)
                insert(updatedCard, at: .zero)
                
            case .end:
                guard let nextMaxValidCardNumber else {
                    throw Stage10Error.runReachedEnd
                }
                switch wildCard.usedAs {
                case .number(let cardNumber):
                    guard cardNumber == nextMaxValidCardNumber else {
                        throw Stage10Error.invalidCard
                    }
                    
                case .color:
                    throw Stage10Error.invalidCard

                case nil:
                    try updatedWild.use(as: .number(nextMaxValidCardNumber))
                }
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
