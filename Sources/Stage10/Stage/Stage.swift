import Foundation

public enum Stage: Equatable, CaseIterable, Codable {
    case one
    case two
    case three
    case four
    case five
    case six
    case seven
    case eight
    case nine
    case ten
    
    public var next: Stage?{
        switch self {
        case .one: .two
        case .two: .three
        case .three: .four
        case .four: .five
        case .five: .six
        case .six: .seven
        case .seven: .eight
        case .eight: .nine
        case .nine: .ten
        case .ten: nil
        }
    }
    
    public var numberValue: Int {
        switch self {
        case .one: 1
        case .two: 2
        case .three: 3
        case .four: 4
        case .five: 5
        case .six: 6
        case .seven: 7
        case .eight: 8
        case .nine: 9
        case .ten: 10
        }
    }
}
