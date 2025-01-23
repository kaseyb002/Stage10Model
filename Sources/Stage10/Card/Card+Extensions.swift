import Foundation

extension [Card] {
    public static func deck() -> [Card] {
        var index: Int = .zero
        let numbers: [Card] = CardColor.allCases.map { color in
            CardNumber.allCases.map { number in
                defer {
                    index += 1
                }
                return Card(
                    id: index,
                    cardType: .number(NumberCard(number: number, color: color))
                )
            }
        }.flatMap { $0 }
        let wilds: [Card] = CardColor.allCases.map { color in
            defer {
                index += 1
            }
            return Card(
                id: index,
                cardType: .wild(WildCard(color: color))
            )
        }
        let skips: [Card] = [
            Card(
                id: index,
                cardType: .skip(playerID: nil)
            ),
            Card(
                id: index + 1,
                cardType: .skip(playerID: nil)
            ),
            Card(
                id: index + 2,
                cardType: .skip(playerID: nil)
            ),
            Card(
                id: index + 3,
                cardType: .skip(playerID: nil)
            ),
        ]
        return numbers + numbers + wilds + wilds + skips
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
                    cardType: .skip(playerID: nil)
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

private extension Card {
    var sortDisplayValue: Int {
        switch cardType {
        case .skip:
            14
            
        case .wild:
            13
            
        case .number(let numberCard):
            numberCard.number.rawValue
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
