import Foundation

public struct PlayerHand: Equatable {
    public var player: Player
    public var cards: [Card]
    public var completed: [CompletedRequirement]
    
    public init(
        player: Player,
        cards: [Card],
        completed: [CompletedRequirement]
    ) {
        self.player = player
        self.cards = cards
        self.completed = completed
    }
}
