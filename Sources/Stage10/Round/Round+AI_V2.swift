import Foundation

extension Round {
    public func makeAIMoveIfNeededV2() throws -> Round {
        guard case .waitingForPlayerToAct(_, let discardState) = self.state,
              let currentPlayerHand: PlayerHand = self.currentPlayerHand
        else {
            return self
        }
        
        var updatedRound = self
        try updatedRound.makeAIPickupDecision(playerHand: currentPlayerHand)
        try updatedRound.attemptLaydownIfNeeded(playerHand: currentPlayerHand)
        try updatedRound.attemptAddCardsIfNeeded(playerHand: currentPlayerHand)
        try updatedRound.makeAIDiscardDecision(playerHand: currentPlayerHand)
        return updatedRound
    }
    
}

// MARK: - Discard Decision
extension Round {
    private mutating func makeAIDiscardDecision(playerHand: PlayerHand) throws {
        // never ever discard a wild
        // prioritize discarding skips first
        // then prioritize cards that do not help fulfill requirement
        // if seeking color set, then get rid of colors you don't need
        // if seeking a run, then get rid if any duplicate cards
        // if seeking a number set, then rid of cards that you don't have a pair for.
        // however, you have to consider that you have multiple requirements
        // so you may be seeking both a number set, and a run. figure it out
    }
}

// MARK: - Laydown Decision
extension Round {
    private mutating func attemptLaydownIfNeeded(playerHand: PlayerHand) throws {
        
    }
}

// MARK: - Add Cards
extension Round {
    private mutating func attemptAddCardsIfNeeded(playerHand: PlayerHand) throws {
        
    }
}

// MARK: - Pickup Decision
extension Round {
    private mutating func makeAIPickupDecision(playerHand: PlayerHand) throws {
        guard let topDiscardCard = discardPile.last else {
            try pickUpCard(fromDiscardPile: false)
            return
        }
        
        switch topDiscardCard.cardType {
        case .skip:
            try pickUpCard(fromDiscardPile: false)

        case .wild:
            try pickUpCard(fromDiscardPile: true)

        case .number(let numberCard):
            if playerHand.isRequirementsComplete == false {
                for requirement in playerHand.player.stage.requirements {
                    if try doesCardHelpFulfill(
                        card: topDiscardCard,
                        cardNumber: numberCard.number,
                        cardColor: numberCard.color,
                        requirement: requirement,
                        for: playerHand
                    ) {
                        try pickUpCard(fromDiscardPile: true)
                        return
                    }
                }
            } else {
                for playerHand in playerHands {
                    for completedRequirement in playerHand.completed {
                        if try canAddCardToCompletedRequirement(
                            card: topDiscardCard,
                            cardNumber: numberCard.number,
                            cardColor: numberCard.color,
                            completedRequirement: completedRequirement,
                            belongingToPlayerID: playerHand.player.id,
                            for: playerHand
                        ) {
                            try pickUpCard(fromDiscardPile: true)
                            return
                        }
                    }
                }
            }
            
            try pickUpCard(fromDiscardPile: false)
        }
    }
    
    private func doesCardHelpFulfill(
        card: Card,
        cardNumber: CardNumber,
        cardColor: CardColor,
        requirement: StageRequirement,
        for playerHand: PlayerHand
    ) throws -> Bool {
        let availableCards = playerHand.cards.filter { !$0.cardType.isSkip }
        let wildCards = availableCards.filter { $0.cardType.isWild }
        
        switch requirement {
        case .numberSet(let count):
            // Count how many cards match this number (including wilds as wildcards)
            let matchingCards = availableCards.filter { card in
                card.cardType.numberValue == cardNumber || card.cardType.isWild
            }
            // Adding this card, would we have enough for the set?
            return (matchingCards.count + 1) >= count

        case .run(let length):
            // Collect all unique numbers in hand (excluding the new card)
            var numbersInHand = Set<Int>()
            for card in availableCards {
                if let number = card.cardType.numberValue {
                    numbersInHand.insert(number.rawValue)
                }
            }
            // Add the new card's number
            numbersInHand.insert(cardNumber.rawValue)
            
            // Find longest potential run including wilds
            let sortedNumbers = numbersInHand.sorted()
            let wildcardCount = wildCards.count + 1 // +1 if new card is wild
            
            return canFormRun(
                numbers: sortedNumbers,
                wildcardsAvailable: wildcardCount,
                requiredLength: length
            )

        case .colorSet(let count):
            // Count how many cards match this color (including wilds as wildcards)
            let matchingCards = availableCards.filter { card in
                card.cardType.color == cardColor || card.cardType.isWild
            }
            // Adding this card, would we have enough for the set?
            return (matchingCards.count + 1) >= count
        }
    }
    
    /// Check if we can form a run of required length with given numbers and wildcards
    private func canFormRun(
        numbers: [Int],
        wildcardsAvailable: Int,
        requiredLength: Int
    ) -> Bool {
        guard !numbers.isEmpty else { return false }
        
        var maxRunLength = 0
        var currentRunLength = 1
        var wildcardsUsed = 0
        
        for i in 1..<numbers.count {
            let gap = numbers[i] - numbers[i-1]
            
            if gap == 0 {
                // Duplicate number, skip
                continue
            } else if gap == 1 {
                // Consecutive, extend run
                currentRunLength += 1
            } else if gap - 1 <= wildcardsAvailable - wildcardsUsed {
                // Gap can be filled with wildcards
                wildcardsUsed += (gap - 1)
                currentRunLength += gap
            } else {
                // Gap too large, start new run
                maxRunLength = max(maxRunLength, currentRunLength)
                currentRunLength = 1
                wildcardsUsed = 0
            }
        }
        
        maxRunLength = max(maxRunLength, currentRunLength)
        
        // Can we extend with remaining wildcards at either end?
        let remainingWilds = wildcardsAvailable - wildcardsUsed
        let minNumber = numbers.first!
        let maxNumber = numbers.last!
        
        // Extend at the beginning (down to 1)
        let canExtendBeginning = max(0, minNumber - 1)
        // Extend at the end (up to 12)
        let canExtendEnd = max(0, 12 - maxNumber)
        
        maxRunLength += min(remainingWilds, canExtendBeginning + canExtendEnd)
        
        return maxRunLength >= requiredLength
    }
    
    private func canAddCardToCompletedRequirement(
        card: Card,
        cardNumber: CardNumber,
        cardColor: CardColor,
        completedRequirement: CompletedRequirement,
        belongingToPlayerID: String,
        for playerHand: PlayerHand
    ) throws -> Bool {
        var testRound: Round = self
        try testRound.pickUpCard(fromDiscardPile: true)
        let attempts: [AddCardForm.Attempt] = {
            switch completedRequirement.requirementType {
            case .colorSet, .numberSet:
                return [.addToSet]
                
            case .run:
                return [.addToRun(position: .beginning), .addToRun(position: .end)]
            }
        }()
        for attempt in attempts {
            let form: AddCardForm = .init(
                cardID: card.id,
                completedRequirementID: completedRequirement.id,
                belongingToPlayerID: belongingToPlayerID,
                attempt: attempt
            )
            do {
                try testRound.addCard(form: form)
                return true
            } catch {
                continue
            }
        }
        return false
    }
}
