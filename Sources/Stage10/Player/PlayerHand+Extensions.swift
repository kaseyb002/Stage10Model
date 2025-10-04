import Foundation

extension PlayerHand {
    public var isRequirementsComplete: Bool {
        completed.count >= player.stage.requirements.count
    }
    
    public func logValue(cardsMap: [CardID: Card]) -> String {
        let resolvedCards: [Card] = cardsMap.findCards(byIDs: cards)
        return """
        \(player.logValue)
        Cards: \(resolvedCards.sortedForDisplay.logValue)
        Completed requirements: \(isRequirementsComplete ? "Completed" : "Incomplete")
        \(completed.logValue)
        """
    }
}

extension [PlayerHand] {
    public func logValue(cardsMap: [CardID: Card]) -> String {
        var text = ""
        for playerHand in self {
            text += playerHand.logValue(cardsMap: cardsMap)
            text += "\n\n"
        }
        return text
    }
}
