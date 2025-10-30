import Foundation

extension Round {
    public mutating func exchangeForWild(
        cardID: CardID,
        playerID: String
    ) throws {
        guard let playerIndex: Int = playerHands.firstIndex(where: { $0.player.id == playerID }),
            let cardIndex: Int = playerHands[playerIndex].cards.firstIndex(where: { $0 == cardID })
        else {
            throw Stage10Error.cardDoesNotExistInPlayersHand
        }
        let discardedCardID: CardID = playerHands[playerIndex].cards.remove(at: cardIndex)
        discardPile.insert(discardedCardID, at: .zero) // bottom of the deck
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
