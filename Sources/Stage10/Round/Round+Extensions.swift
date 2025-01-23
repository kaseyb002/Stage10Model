import Foundation

extension Round {
    public var currentPlayerHandIndex: Int? {
        switch state {
        case .waitingForPlayerToAct(let playerIndex, _):
            return playerIndex
            
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
        Discard top card: \(discardPile.last?.cardType.logValue ?? "None")
        Current player: \(currentPlayerHand?.player.name ?? "None") \(currentPlayerHand?.player.id ?? "")
        
        \(playerHands.logValue)
        """
    }
}
