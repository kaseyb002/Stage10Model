import Foundation

public enum StageRequirement: Equatable, Sendable {
    case numberSet(count: Int)
    case run(length: Int)
    case colorSet(count: Int)
}
