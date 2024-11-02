import Foundation

extension PlayerHand {
    public var isRequirementsComplete: Bool {
        completed.count >= player.stage.requirements.count
    }
    
    public var logValue: String {
        """
        \(player.logValue)
        Cards: \(cards.sortedForDisplay.logValue)
        Completed requirements: \(isRequirementsComplete ? "Completed" : "Incomplete")
        \(completed.logValue)
        """
    }
}

extension [PlayerHand] {
    public var logValue: String {
        var text = ""
        for playerHand in self {
            text += playerHand.logValue
            text += "\n\n"
        }
        return text
    }
}
