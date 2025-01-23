import Foundation

public struct AddCardForm: Equatable, Codable {
    public let cardID: CardID
    public let completedRequirementID: String
    public let belongingToPlayerID: String
    public let attempt: Attempt
    
    public enum Attempt: Equatable, Codable {
        case addToSet
        case addToRun(position: Run.AddPosition)
    }
}
