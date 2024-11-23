import Foundation

public struct WildCard: Equatable, Codable {
    public let color: CardColor
    public private(set) var usedAs: UsedAs?
    public var isUsed: Bool {
        usedAs != nil
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
        if let alreadyUsedAs: UsedAs = self.usedAs {
            throw WildCardError.alreadyUsedAs(alreadyUsedAs)
        }
        self.usedAs = usedAs
    }
    
    public enum WildCardError: Error {
        case alreadyUsedAs(UsedAs)
    }
}
