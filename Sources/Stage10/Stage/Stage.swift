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
}
