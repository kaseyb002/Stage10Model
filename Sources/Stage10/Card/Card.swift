import Foundation

public enum Card: Equatable, Codable {
    case skip
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
    
    public var logValue: String {
        switch self {
        case .skip:
            "S🟦"
            
        case .wild(let wildCard):
            "W🌈"
            
        case .number(let numberCard):
            "\(numberCard.number.rawValue)\(numberCard.color.logValue)"
        }
    }
}
