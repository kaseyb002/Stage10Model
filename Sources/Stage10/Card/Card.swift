import Foundation

public typealias CardID = Int

public struct Card: Equatable, Codable {
    public let id: CardID
    public var cardType: CardType
    
    public var logValue: String {
        "ID: \(id) \(cardType.logValue)"
    }
    
    public mutating func setPlayerToSkip(playerID: String) throws {
        switch cardType {
        case .skip:
            self.cardType = .skip(playerID: playerID)
            
        case .wild, .number:
            throw Stage10Error.triedToSkipWithCardThatIsNotSkip
        }
    }
    
    public init(
        id: CardID,
        cardType: CardType
    ) {
        self.id = id
        self.cardType = cardType
    }
    
    public enum CardType: Equatable, Codable {
        case skip(playerID: String?)
        case wild(WildCard)
        case number(NumberCard)
        
        public var points: Int {
            switch self {
            case .skip, .wild:
                25
                
            case .number(let numberCard):
                switch numberCard.number {
                case .one, .two, .three, .four, .five, .six, .seven, .eight, .nine:
                    5
                    
                case .ten, .eleven, .twelve:
                    10
                }
            }
        }
        
        public var numberValue: CardNumber? {
            switch self {
            case .skip:
                nil
                
            case .wild(let wildCard):
                wildCard.usedAs?.number
                
            case .number(let numberCard):
                numberCard.number
            }
        }
        
        public var color: CardColor? {
            switch self {
            case .skip:
                nil
                
            case .wild(let wildCard):
                wildCard.resolvedColor
                
            case .number(let numberCard):
                numberCard.color
            }
        }
        
        public var isSkip: Bool {
            switch self {
            case .skip: true
            case .wild, .number: false
            }
        }
        
        public var logValue: String {
            switch self {
            case .skip:
                "S🟦"
                
            case .wild:
                "W🌈"
                
            case .number(let numberCard):
                "\(numberCard.number.rawValue)\(numberCard.color.logValue)"
            }
        }
    }
}
