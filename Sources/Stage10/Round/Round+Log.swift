import Foundation

extension Round {
    public struct Log: Equatable, Codable, Sendable {
        public var actions: [PlayerAction] = []
        
        /// Maximum number of actions to keep in the log to prevent unbounded growth
        private static let maxActions = 200
        
        public struct PlayerAction: Equatable, Codable, Sendable {
            public let playerID: String
            public let decision: Decision
            public let timestamp: Date
            
            public enum Decision: Equatable, Codable, Sendable {
                case pickup(cardId: CardID, fromDiscardPile: Bool)
                case laydown([LogCompletedRequirement])
                case discard(cardId: CardID)
                case addCard(id: CardID, toCompletedRequirement: LogCompletedRequirement)
            }
            
            public enum CodingKeys: String, CodingKey {
                case playerID = "playerId"
                case decision
                case timestamp
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
        
        public struct LogCompletedRequirement: Equatable, Codable, Sendable {
            public let completedRequirementID: String
            public let cardIDs: [CardID]
            
            public enum CodingKeys: String, CodingKey {
                case completedRequirementID = "completedRequirementId"
                case cardIDs = "cardIds"
            }

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
        
        /// Adds an action to the log, keeping only the most recent maxActions entries
        public mutating func addAction(_ action: PlayerAction) {
            actions.append(action)
            if actions.count > Self.maxActions {
                actions.removeFirst(actions.count - Self.maxActions)
            }
        }
    }
}
