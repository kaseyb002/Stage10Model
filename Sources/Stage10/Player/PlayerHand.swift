import Foundation

public struct PlayerHand: Equatable, Codable, Sendable {
    public var player: Player
    public var cards: [CardID]
    public var completed: [CompletedRequirement]
    
    public init(
        player: Player,
        cards: [CardID],
        completed: [CompletedRequirement]
    ) {
        self.player = player
        self.cards = cards
        self.completed = completed
    }
}
