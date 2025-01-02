import Foundation

extension Game {
    public mutating func discard(_ card: Card) throws {
        guard let currentRoundIndex: Int else {
            throw Stage10Error.gameHasNoRounds
        }
        try rounds[currentRoundIndex].discard(card)
    }
    
    public mutating func complete(
        requirement: CompletedRequirement,
        with cards: [Card]
    ) throws {
        guard let currentRoundIndex: Int else {
            throw Stage10Error.gameHasNoRounds
        }
        try rounds[currentRoundIndex].complete(
            requirement: requirement,
            with: cards
        )
    }
    
    public mutating func pickUpCard(fromDiscardPile: Bool) throws {
        guard let currentRoundIndex: Int else {
            throw Stage10Error.gameHasNoRounds
        }
        try rounds[currentRoundIndex].pickUpCard(fromDiscardPile: fromDiscardPile)
    }
    
    public mutating func add(
        card: Card,
        to completedRequirement: CompletedRequirement,
        belongingToPlayerID playerID: String,
        runPosition: Run.AddPosition?
    ) throws {
        guard let currentRoundIndex: Int else {
            throw Stage10Error.gameHasNoRounds
        }
        try rounds[currentRoundIndex].add(
            card: card,
            to: completedRequirement,
            belongingToPlayerID: playerID,
            runPosition: runPosition
        )
    }
}
