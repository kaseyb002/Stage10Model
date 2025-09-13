import Foundation

extension CompletedRequirement {
    public var logValue: String {
        switch requirementType {
        case .numberSet(let numberSet):
            "Number Set - \(numberSet.cards.sortedForDisplay.logValue)"
            
        case .colorSet(let colorSet):
            "Color Set - \(colorSet.cards.sortedForDisplay.logValue)"
            
        case .run(let run):
            "Run - \(run.cards.sortedForDisplay.logValue)"
        }
    }
}

extension CompletedRequirement.RequirementType {
    public var cards: [Card] {
        switch self {
        case .numberSet(let numberSet):
            numberSet.cards
            
        case .colorSet(let colorSet):
            colorSet.cards
            
        case .run(let run):
            run.cards
        }
    }
}

extension [CompletedRequirement] {
    public var logValue: String {
        var text = ""
        for (index, c) in self.enumerated() {
            text += "(\(index + 1)) \(c.logValue)\n"
        }
        return text
    }
}
