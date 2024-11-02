import Foundation

extension Stage {
    public var requirements: [StageRequirement] {
        switch self {
        case .one: .stage1
        case .two: .stage2
        case .three: .stage3
        case .four: .stage4
        case .five: .stage5
        case .six: .stage6
        case .seven: .stage7
        case .eight: .stage8
        case .nine: .stage9
        case .ten: .stage10
        }
    }
}
