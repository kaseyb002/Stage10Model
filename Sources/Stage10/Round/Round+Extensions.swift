import Foundation

extension Round {
    public var currentPlayerHandIndex: Int? {
        switch state {
        case .waitingForPlayerToAct(let playerID, _):
            return playerHands.firstIndex(where: { $0.player.id == playerID })
            
        case .roundComplete, .gameComplete:
            return nil
        }
    }
    
    public var currentPlayerHand: PlayerHand? {
        guard let currentPlayerHandIndex else {
            return nil
        }
        return playerHands[currentPlayerHandIndex]
    }
    
    public var logValue: String {
        """
        State: \(state.logValue)
        Deck remaining: \(deck.count)
        Discard pile count: \(discardPile.count)
        Discard top card: \(cardsMap[discardPile.last ?? -1]?.cardType.logValue ?? "None")
        Current player: \(currentPlayerHand?.player.name ?? "None") \(currentPlayerHand?.player.id ?? "")
        
        \(String(describing: playerHands.logValue))
        """
    }
    
    public var allCards: [Card] {
        let allCardIDs = deck + discardPile + playerHands.flatMap(\.cards) + playerHands.flatMap(\.completed).flatMap { completed in
            completed.requirementType.cards.compactMap { card in card.id }
        }
        return allCardIDs.compactMap { cardID in cardsMap[cardID] }
    }
}
