import Foundation

extension Round {
    public struct Log: Equatable, Codable {
        public var actions: [PlayerAction] = []
        
        public struct PlayerAction: Equatable, Codable {
            public let playerID: String
            public let decision: Decision
            public let timestamp: Date
            
            public enum Decision: Equatable, Codable {
                case pickup(cardId: CardID, fromDiscardPile: Bool)
                case laydown([LogCompletedRequirement])
                case discard(cardId: CardID)
                case addCard(id: CardID, toCompletedRequirement: LogCompletedRequirement)
            }
            
            public init(
                playerID: String,
                decision: Decision,
                timestamp: Date = .now
            ) {
                self.playerID = playerID
                self.decision = decision
                self.timestamp = timestamp
            }
        }
        
        public struct LogCompletedRequirement: Equatable, Codable {
            public let completedRequirementID: String
            public let cardIDs: [CardID]
            
            public init(
                completedRequirementID: String,
                cardIDs: [CardID]
            ) {
                self.completedRequirementID = completedRequirementID
                self.cardIDs = cardIDs
            }
            
            public init(completedRequirement: CompletedRequirement) {
                self.completedRequirementID = completedRequirement.id
                self.cardIDs = completedRequirement.requirementType.cards.map { $0.id }
            }
        }
        
        public init(
            actions: [PlayerAction] = []
        ) {
            self.actions = actions
        }
    }
}
