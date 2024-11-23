import Foundation

public struct Run: Equatable, Codable {
    public let requiredLength: Int
    public private(set) var cards: [Card]
    private var firstCard: Card { cards.first! }
    private var lastCard: Card { cards.last! }
    private var nextMinValidCardNumber: CardNumber? {
        guard let number: CardNumber = firstCard.numberValue,
              number > CardNumber.min
        else {
            return nil
        }
        return CardNumber(rawValue: number.rawValue - 1)
    }
    private var nextMaxValidCardNumber: CardNumber? {
        guard let number: CardNumber = lastCard.numberValue,
              number < CardNumber.max
        else {
            return nil
        }
        return CardNumber(rawValue: number.rawValue + 1)
    }
    
    public init(
        requiredLength: Int,
        cards: [Card]
    ) throws {
        if requiredLength < 4 {
            throw FailedObjectiveError.requiredLengthBelowMin
        }
        if requiredLength > 9 {
            throw FailedObjectiveError.requiredLengthAboveMax
        }
        self.requiredLength = requiredLength
        self.cards = try Self.validated(
            cards: cards,
            requiredLength: requiredLength
        )
    }
    
    public enum AddPosition: Equatable {
        case beginning
        case end
    }
    
    public mutating func add(
        numberCard: NumberCard
    ) throws {
        if numberCard.number == nextMinValidCardNumber {
            cards.append(.number(numberCard))
        } else if numberCard.number == nextMaxValidCardNumber {
            cards.append(.number(numberCard))
        } else {
            throw FailedObjectiveError.isNotValidNextCard
        }
    }
    
    public mutating func add(
        wildCard: WildCard,
        position: AddPosition
    ) throws {
        switch position {
        case .beginning:
            guard let nextMinValidCardNumber else {
                throw FailedObjectiveError.runReachedEnd
            }
            guard wildCard.usedAs?.number == nextMinValidCardNumber else {
                throw FailedObjectiveError.cardsDoNotMakeRun
            }
            cards.insert(.wild(wildCard), at: .zero)
            
        case .end:
            guard let nextMaxValidCardNumber else {
                throw FailedObjectiveError.runReachedEnd
            }
            guard wildCard.usedAs?.number == nextMaxValidCardNumber else {
                throw FailedObjectiveError.cardsDoNotMakeRun
            }
            cards.append(.wild(wildCard))
        }
    }
    
    private static func validated(
        cards: [Card],
        requiredLength: Int
    ) throws -> [Card] {
        guard cards.count >= requiredLength else {
            throw FailedObjectiveError.insufficientCards
        }
        guard var currentNumber: CardNumber = cards.first?.numberValue else {
            throw FailedObjectiveError.invalidCard
        }
        for card in cards.suffix(from: 1) {
            guard let number: CardNumber = card.numberValue else {
                throw FailedObjectiveError.invalidCard
            }
            if number.rawValue == currentNumber.rawValue + 1 {
                currentNumber = number
                continue
            } else {
                throw FailedObjectiveError.cardsDoNotMakeRun
            }
        }
        return cards
    }
}
