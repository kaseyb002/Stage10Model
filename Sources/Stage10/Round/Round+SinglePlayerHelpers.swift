import Foundation

extension Round {
    public mutating func exchangeForWild(
        cardID: CardID,
        playerID: String
    ) throws {
        guard case .waitingForPlayerToAct(let currentPlayerID, _) = state else {
            throw Stage10Error.notWaitingForPlayerToAct
        }
        guard currentPlayerID == playerID else {
            throw Stage10Error.notCurrentPlayer
        }
        guard let playerIndex: Int = playerHands.firstIndex(where: { $0.player.id == playerID }),
            let cardIndex: Int = playerHands[playerIndex].cards.firstIndex(where: { $0 == cardID })
        else {
            throw Stage10Error.cardDoesNotExistInPlayersHand
        }
        guard let card = cardsMap[cardID] else {
            throw Stage10Error.cardDoesNotExistInPlayersHand
        }
        guard !card.cardType.isWild else {
            throw Stage10Error.cannotExchangeWildForWild
        }
        let discardedCardID: CardID = playerHands[playerIndex].cards.remove(at: cardIndex)
        discardPile.insert(discardedCardID, at: .zero)
        let newWild: Card = .init(
            id: (cardsMap.keys.max() ?? 0) + 1,
            cardType: .wild(
                .init(
                    color: .blue,
                    usedAs: nil
                )
            )
        )
        cardsMap[newWild.id] = newWild
        playerHands[playerIndex].cards.append(newWild.id)
    }
}
