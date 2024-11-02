import Foundation

public enum CardColor: Equatable, CaseIterable, Sendable {
    case red
    case blue
    case green
    case yellow
    
    public var logValue: String {
        switch self {
        case .red: "🔴"
        case .blue: "🔵"
        case .green: "🟢"
        case .yellow: "🟡"
        }
    }
}
