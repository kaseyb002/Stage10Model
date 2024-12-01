import Foundation

extension Round {
    public static func fake(
        id: String,
        started: Date,
        state: State,
        deck: [Card],
        discardPile: [Card],
        playerHands: [PlayerHand],
        ended: Date?
    ) -> Round {
        .init(
            id: id,
            started: started,
            state: state,
            deck: deck,
            discardPile: discardPile,
            playerHands: playerHands,
            ended: ended
        )
    }
}
