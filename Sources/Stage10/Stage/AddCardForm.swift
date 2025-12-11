import Foundation

public struct AddCardForm: Equatable, Codable, Sendable {
    public let cardID: CardID
    public let completedRequirementID: String
    public let belongingToPlayerID: String
    public let attempt: Attempt
    
    public enum Attempt: Equatable, Codable, Sendable {
        case addToSet
        case addToRun(position: Run.AddPosition)
    }
    
    public enum CodingKeys: String, CodingKey {
        case cardID = "cardId"
        case completedRequirementID = "completedRequirementId"
        case belongingToPlayerID = "belongingToPlayerId"
        case attempt
    }
    
    public init(
        cardID: CardID,
        completedRequirementID: String,
        belongingToPlayerID: String,
        attempt: Attempt
    ) {
        self.cardID = cardID
        self.completedRequirementID = completedRequirementID
        self.belongingToPlayerID = belongingToPlayerID
        self.attempt = attempt
    }
}
