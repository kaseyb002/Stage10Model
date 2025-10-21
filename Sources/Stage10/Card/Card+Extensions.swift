import Foundation

extension [Card] {
    public static func deck() -> [Card] {
        let placeholderIndex: Int = .zero
        let numbers: [Card] = CardColor.allCases.map { color in
            CardNumber.allCases.map { number in
                return Card(
                    id: placeholderIndex,
                    cardType: .number(NumberCard(number: number, color: color))
                )
            }
        }.flatMap { $0 }
        let wilds: [Card] = CardColor.allCases.map { color in
            return Card(
                id: placeholderIndex,
                cardType: .wild(WildCard(color: color))
            )
        }
        let skips: [Card] = [
            Card(
                id: placeholderIndex,
                cardType: .skip(playerId: nil)
            ),
            Card(
                id: placeholderIndex,
                cardType: .skip(playerId: nil)
            ),
            Card(
                id: placeholderIndex,
                cardType: .skip(playerId: nil)
            ),
            Card(
                id: placeholderIndex,
                cardType: .skip(playerId: nil)
            ),
        ]
        let allCards = numbers + numbers + wilds + wilds + skips
        // Shuffle IDs separately to prevent card ID from revealing card value
        // This is critical for network multiplayer where card IDs are exposed
        let shuffledIDs: [Int] = (0..<allCards.count).shuffled()
        return zip(allCards, shuffledIDs).map { card, cardID in
            Card(
                id: cardID,
                cardType: card.cardType
            )
        }
    }
    
    public static func randomSet(of count: Int) -> [Card] {
        Array([Card].deck().shuffled().prefix(count))
    }
    
    public static func allSkips(count: Int) -> [Card] {
        var cards: [Card] = []
        for id in 0 ..< count {
            cards.append(
                .init(
                    id: id,
                    cardType: .skip(playerId: nil)
                )
            )
        }
        return cards
    }

    public var totalPoints: Int {
        reduce(.zero, { $0 + $1.cardType.points })
    }
    
    public var sortedForDisplay: [Card] {
        sorted(by: {
            if $0.sortDisplayValue == $1.sortDisplayValue {
                switch ($0.cardType, $1.cardType) {
                case (.number(let lhs), .number(let rhs)):
                    return lhs.color.sortDisplayValue < rhs.color.sortDisplayValue
                default:
                    return true
                }
            } else {
                return $0.sortDisplayValue < $1.sortDisplayValue
            }
        })
    }
    
    public var logValue: String {
        map { $0.cardType.logValue }.joined(separator: ", ")
    }
    
    public func contains(other cards: [Card]) -> Bool {
        var theseCards: [Card] = self
        for card in cards {
            if let index: Int = theseCards.firstIndex(of: card) {
                theseCards.remove(at: index)
            } else {
                return false
            }
        }
        return true
    }
    
    public mutating func remove(other cards: [Card]) {
        var theseCards: [Card] = self
        for card in cards {
            if let index: Int = theseCards.firstIndex(of: card) {
                theseCards.remove(at: index)
            }
        }
        self = theseCards
    }
}

extension [CardID] {
    public static func randomSet(of count: Int) -> [CardID] {
        Array([Card].deck().map(\.id).shuffled().prefix(count))
    }
    
    public func totalPoints(cardsMap: [CardID: Card]) -> Int {
        reduce(.zero, { $0 + (cardsMap[$1]?.cardType.points ?? 0) })
    }
}

extension [CardID: Card] {
    public func findCards(byIDs cardIDs: [CardID]) -> [Card] {
        cardIDs.compactMap { self[$0] }
    }
}

private extension Card {
    var sortDisplayValue: Int {
        switch cardType {
        case .skip:
            return 14
            
        case .wild(let wildCard):
            switch wildCard.usedAs {
            case .color, .none:
                return 13
                
            case .number(let cardNumber):
                return cardNumber.rawValue
            }
            
        case .number(let numberCard):
            return numberCard.number.rawValue
        }
    }
}

private extension CardColor {
    var sortDisplayValue: Int {
        switch self {
        case .red: 1
        case .blue: 2
        case .green: 3
        case .yellow: 4
        }
    }
}
