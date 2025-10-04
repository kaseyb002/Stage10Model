import Foundation

extension PlayerHand {
    public static func fake(
        player: Player = .fake(),
        cards: [CardID] = .randomSet(of: 10),
        completed: [CompletedRequirement] = []
    ) -> PlayerHand {
        .init(
            player: player,
            cards: cards,
            completed: completed
        )
    }
}
