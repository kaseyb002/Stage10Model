import Foundation

public struct WildCard: Equatable, Codable {
    public let color: CardColor
    public var usedAs: UsedAs?
    
    public var isUsed: Bool {
        usedAs != nil
    }
    
    public var isUsedAsNumber: Bool {
        switch usedAs {
        case .number: false
        case .color, nil: true
        }
    }
    
    public var isUsedAsColor: Bool {
        switch usedAs {
        case .number, nil: false
        case .color: true
        }
    }
    
    public var resolvedColor: CardColor {
        switch usedAs {
        case .color(let cardColor):
            cardColor
            
        case .number, .none:
            color
        }
    }
    
    public enum UsedAs: Equatable, Sendable, Codable {
        case number(CardNumber)
        case color(CardColor)
        
        public var number: CardNumber? {
            switch self {
            case .number(let cardNumber):
                cardNumber
                
            case .color:
                nil
            }
        }
        
        public var color: CardColor? {
            switch self {
            case .number:
                nil
                
            case .color(let cardColor):
                cardColor
            }
        }
    }
    
    public init(
        color: CardColor,
        usedAs: UsedAs? = nil
    ) {
        self.color = color
        self.usedAs = usedAs
    }
    
    public mutating func use(as usedAs: UsedAs) throws {
        self.usedAs = usedAs
    }
}
