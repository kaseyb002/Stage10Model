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
        numberCard: NumberCard
    ) throws {
        guard numberCard.number == number else {
            throw FailedObjectiveError.invalidCard
        }
        cards.append(.number(numberCard))
    }
    
    public mutating func add(
        wildCard: WildCard
    ) throws {
        var updatedWildCard: WildCard = wildCard
        try updatedWildCard.use(as: .number(number))
        cards.append(.wild(updatedWildCard))
    }

    private static func validated(
        cards: [Card],
        number: CardNumber,
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
                try updatedWild.use(as: .number(number))
                validCards.append(.wild(updatedWild))
                
            case .number(let numberCard):
                if numberCard.number == number {
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
