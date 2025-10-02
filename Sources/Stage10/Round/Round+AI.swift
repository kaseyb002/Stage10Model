import Foundation

extension Round {
    public func makeAIMoveIfNeeded() -> Round {
        guard case .waitingForPlayerToAct(_, let discardState) = self.state,
              let currentPlayerHand: PlayerHand = self.currentPlayerHand
        else {
            return self
        }

        var updatedRound = self
        
        do {
            switch discardState {
            case .needsToPickUp:
                try updatedRound.makeAIPickupDecision()
                
            case .needsToDiscard:
                // Try to complete stage first if possible
                if !currentPlayerHand.isRequirementsComplete {
                    try updatedRound.attemptToCompleteStage()
                }
                
                // Try to add cards to other players' completed requirements
                try updatedRound.attemptToAddCardsToOthers()
                
                // Finally discard a card
                try updatedRound.makeAIDiscardDecision()
            }
        } catch {
            // If AI encounters an error, just pick up from deck and discard first card
            // This ensures the game doesn't get stuck
            do {
                switch discardState {
                case .needsToDiscard:
                    try updatedRound.pickUpCard(fromDiscardPile: false)

                case .needsToPickUp:
                    if let firstCardID = updatedRound.currentPlayerHand?.cards.first?.id {
                        try updatedRound.discard(firstCardID)
                    }
                }
            } catch {
                // Last resort - return original round if everything fails
                return self
            }
        }
        
        return updatedRound
    }
    
    // MARK: - AI Decision Making
    
    private mutating func makeAIPickupDecision() throws {
        // Check if the top card of discard pile is useful
        guard let topDiscardCard = discardPile.last,
              !topDiscardCard.cardType.isSkip,
              let currentPlayerHand = self.currentPlayerHand
        else {
            // Pick up from deck if discard pile is empty or top card is skip
            try pickUpCard(fromDiscardPile: false)
            return
        }
        
        let shouldPickFromDiscard = evaluateCardUsefulness(topDiscardCard, for: currentPlayerHand)
        try pickUpCard(fromDiscardPile: shouldPickFromDiscard)
    }
    
    private func evaluateCardUsefulness(_ card: Card, for playerHand: PlayerHand) -> Bool {
        // If player hasn't completed requirements, check if card helps with stage
        if !playerHand.isRequirementsComplete {
            for requirement in playerHand.player.stage.requirements {
                if canCardHelpWithRequirement(card, requirement: requirement, hand: playerHand) {
                    return true
                }
            }
        }
        
        // Check if card can be added to any player's completed requirements
        // Only if current player has completed their own stage
        if playerHand.isRequirementsComplete {
            for otherPlayerHand in playerHands {
                if otherPlayerHand.player.id != playerHand.player.id {
                    for completedReq in otherPlayerHand.completed {
                        if canAddCardToCompletedRequirement(card, completedRequirement: completedReq) {
                            return true
                        }
                    }
                }
            }
        }
        
        return false
    }
    
    private func canCardHelpWithRequirement(_ card: Card, requirement: StageRequirement, hand: PlayerHand) -> Bool {
        switch requirement {
        case .numberSet(let count):
            // Check if we have cards of the same number
            if let cardNumber = card.cardType.numberValue {
                let matchingCards = hand.cards.filter { $0.cardType.numberValue == cardNumber }
                return matchingCards.count >= count - 1 // Need count-1 more cards
            }
            return card.cardType.isWild
            
        case .colorSet(let count):
            // Check if we have cards of the same color
            if let cardColor = card.cardType.color {
                let matchingCards = hand.cards.filter { $0.cardType.color == cardColor }
                return matchingCards.count >= count - 1
            }
            return card.cardType.isWild
            
        case .run(_):
            // For runs, any number card or wild could potentially help
            return card.cardType.numberValue != nil || card.cardType.isWild
        }
    }
    
    private func canAddCardToCompletedRequirement(_ card: Card, completedRequirement: CompletedRequirement) -> Bool {
        switch completedRequirement.requirementType {
        case .numberSet(let numberSet):
            if let cardNumber = card.cardType.numberValue {
                return cardNumber == numberSet.number
            }
            return card.cardType.isWild
            
        case .colorSet(let colorSet):
            if let cardColor = card.cardType.color {
                return cardColor == colorSet.color
            }
            return card.cardType.isWild
            
        case .run:
            // Runs can potentially accept adjacent numbers or wilds
            return card.cardType.numberValue != nil || card.cardType.isWild
        }
    }
    
    private mutating func attemptToCompleteStage() throws {
        guard let currentPlayerHand = self.currentPlayerHand,
              !currentPlayerHand.isRequirementsComplete
        else { return }
        
        let requirements = currentPlayerHand.player.stage.requirements
        var completionAttempts: [CompleteStageForm.CompletionAttempt] = []
        var availableCards = currentPlayerHand.cards
        
        // Try to fulfill each requirement
        for requirement in requirements {
            if let attempt = findCardsForRequirement(requirement, from: availableCards) {
                completionAttempts.append(attempt)
                // Remove used cards from available pool
                for cardID in attempt.cardIDs {
                    availableCards.removeAll { $0.id == cardID }
                }
            } else {
                // Can't complete all requirements
                return
            }
        }
        
        // If we can complete all requirements, do it
        if completionAttempts.count == requirements.count {
            // First, set the usedAs property for any wild cards that will be used
            try setWildCardsUsedAs(for: completionAttempts)
            
            let form = CompleteStageForm(completionAttempts: completionAttempts)
            try completeStage(form: form)
        }
    }
    
    private mutating func setWildCardsUsedAs(for completionAttempts: [CompleteStageForm.CompletionAttempt]) throws {
        guard let currentPlayerHand = self.currentPlayerHand else { return }
        
        for attempt in completionAttempts {
            switch attempt.requirement {
            case .numberSet(_):
                // Find the target number from non-wild cards
                var targetNumber: CardNumber?
                for cardID in attempt.cardIDs {
                    if let card = currentPlayerHand.cards.first(where: { $0.id == cardID }),
                       let number = card.cardType.numberValue {
                        targetNumber = number
                        break
                    }
                }
                
                // If we found a target number, set wild cards to use that number
                if let targetNumber = targetNumber {
                    for cardID in attempt.cardIDs {
                        if let card = currentPlayerHand.cards.first(where: { $0.id == cardID }),
                           case .wild = card.cardType {
                            try useWildAs(
                                myPlayerID: currentPlayerHand.player.id,
                                cardID: cardID,
                                usedAs: .number(targetNumber)
                            )
                        }
                    }
                }
                
            case .colorSet(_):
                // Find the target color from non-wild cards
                var targetColor: CardColor?
                for cardID in attempt.cardIDs {
                    if let card = currentPlayerHand.cards.first(where: { $0.id == cardID }),
                       let color = card.cardType.color {
                        targetColor = color
                        break
                    }
                }
                
                // If we found a target color, set wild cards to use that color
                if let targetColor = targetColor {
                    for cardID in attempt.cardIDs {
                        if let card = currentPlayerHand.cards.first(where: { $0.id == cardID }),
                           case .wild = card.cardType {
                            try useWildAs(
                                myPlayerID: currentPlayerHand.player.id,
                                cardID: cardID,
                                usedAs: .color(targetColor)
                            )
                        }
                    }
                }
                
            case .run(let length):
                // For runs, we need to determine the position of each wild card
                // and set it to the appropriate number
                try setWildCardsForRun(attempt: attempt, length: length)
            }
        }
    }
    
    private mutating func setWildCardsForRun(attempt: CompleteStageForm.CompletionAttempt, length: Int) throws {
        guard let currentPlayerHand = self.currentPlayerHand else { return }
        
        // Create a sorted array of cards to determine positions
        var cards: [Card] = []
        for cardID in attempt.cardIDs {
            if let card = currentPlayerHand.cards.first(where: { $0.id == cardID }) {
                cards.append(card)
            }
        }
        
        // Sort cards to determine their positions in the run
        cards.sort { card1, card2 in
            let num1 = card1.cardType.numberValue?.rawValue ?? Int.max
            let num2 = card2.cardType.numberValue?.rawValue ?? Int.max
            return num1 < num2
        }
        
        // Find the starting number for this run
        var startNumber: CardNumber?
        for card in cards {
            if let number = card.cardType.numberValue {
                startNumber = number
                break
            }
        }
        
        guard let startNumber = startNumber else { return }
        
        // Set wild cards to appropriate numbers based on their position
        for (index, card) in cards.enumerated() {
            if case .wild = card.cardType {
                let targetNumber = CardNumber(rawValue: startNumber.rawValue + index) ?? startNumber
                try useWildAs(
                    myPlayerID: currentPlayerHand.player.id,
                    cardID: card.id,
                    usedAs: .number(targetNumber)
                )
            }
        }
    }
    
    private mutating func findCardsForRequirement(_ requirement: StageRequirement, from cards: [Card]) -> CompleteStageForm.CompletionAttempt? {
        switch requirement {
        case .numberSet(let count):
            return findCardsForNumberSet(count: count, from: cards)
        case .colorSet(let count):
            return findCardsForColorSet(count: count, from: cards)
        case .run(let length):
            return findCardsForRun(length: length, from: cards)
        }
    }
    
    private mutating func findCardsForNumberSet(count: Int, from cards: [Card]) -> CompleteStageForm.CompletionAttempt? {
        // Group cards by number
        var numberGroups: [CardNumber: [Card]] = [:]
        var wilds: [Card] = []
        
        for card in cards {
            if let number = card.cardType.numberValue {
                numberGroups[number, default: []].append(card)
            } else if card.cardType.isWild {
                wilds.append(card)
            }
        }
        
        // Find the best number group to complete
        for (_, groupCards) in numberGroups {
            let totalAvailable = groupCards.count + wilds.count
            if totalAvailable >= count {
                var selectedCards: [Card] = []
                let nonWildCardsNeeded = min(count, groupCards.count)
                let wildsNeeded = count - nonWildCardsNeeded
                
                // Add non-wild cards first so the initializer can determine the correct number
                selectedCards.append(contentsOf: Array(groupCards.prefix(nonWildCardsNeeded)))
                
                // Add wild cards last
                for i in 0..<min(wildsNeeded, wilds.count) {
                    selectedCards.append(wilds[i])
                }
                
                return CompleteStageForm.CompletionAttempt(
                    requirement: .numberSet(count: count),
                    cardIDs: selectedCards.map { $0.id }
                )
            }
        }
        
        return nil
    }
    
    private mutating func findCardsForColorSet(count: Int, from cards: [Card]) -> CompleteStageForm.CompletionAttempt? {
        // Group cards by color
        var colorGroups: [CardColor: [Card]] = [:]
        var wilds: [Card] = []
        
        for card in cards {
            if let color = card.cardType.color {
                colorGroups[color, default: []].append(card)
            } else if card.cardType.isWild {
                wilds.append(card)
            }
        }
        
        // Find the best color group to complete
        for (_, groupCards) in colorGroups {
            let totalAvailable = groupCards.count + wilds.count
            if totalAvailable >= count {
                var selectedCards: [Card] = []
                let nonWildCardsNeeded = min(count, groupCards.count)
                let wildsNeeded = count - nonWildCardsNeeded
                
                // Add non-wild cards first so the initializer can determine the correct color
                selectedCards.append(contentsOf: Array(groupCards.prefix(nonWildCardsNeeded)))
                
                // Add wild cards last
                for i in 0..<min(wildsNeeded, wilds.count) {
                    selectedCards.append(wilds[i])
                }
                
                return CompleteStageForm.CompletionAttempt(
                    requirement: .colorSet(count: count),
                    cardIDs: selectedCards.map { $0.id }
                )
            }
        }
        
        return nil
    }
    
    private mutating func findCardsForRun(length: Int, from cards: [Card]) -> CompleteStageForm.CompletionAttempt? {
        // Get all number cards and wilds
        var numberCards: [CardNumber: [Card]] = [:]
        var wilds: [Card] = []
        
        for card in cards {
            if let number = card.cardType.numberValue {
                numberCards[number, default: []].append(card)
            } else if card.cardType.isWild {
                wilds.append(card)
            }
        }
        
        // Try to find the best consecutive sequence
        let allNumbers = CardNumber.allCases.sorted()
        var bestRun: [Card] = []
        
        for startNumber in allNumbers {
            var currentRun: [Card] = []
            var wildsUsed = 0
            
            for i in 0..<length {
                if let targetNumber = CardNumber(rawValue: startNumber.rawValue + i) {
                    if let availableCard = numberCards[targetNumber]?.first {
                        currentRun.append(availableCard)
                    } else if wildsUsed < wilds.count {
                        currentRun.append(wilds[wildsUsed])
                        wildsUsed += 1
                    } else {
                        break
                    }
                } else {
                    break
                }
            }
            
            if currentRun.count == length && currentRun.count > bestRun.count {
                bestRun = currentRun
            }
        }
        
        if bestRun.count == length {
            return CompleteStageForm.CompletionAttempt(
                requirement: .run(length: length),
                cardIDs: bestRun.map { $0.id }
            )
        }
        
        return nil
    }
    
    private mutating func attemptToAddCardsToOthers() throws {
        guard let currentPlayerHand = self.currentPlayerHand else { return }
        
        // Only try to add cards to others if current player has completed their stage
        guard currentPlayerHand.isRequirementsComplete else { return }
        
        // Try to add cards to other players' completed requirements
        for card in currentPlayerHand.cards {
            for otherPlayerHand in playerHands {
                if otherPlayerHand.player.id != currentPlayerHand.player.id {
                    for completedReq in otherPlayerHand.completed {
                        if canAddCardToCompletedRequirement(card, completedRequirement: completedReq) {
                            let attempt: AddCardForm.Attempt
                            
                            switch completedReq.requirementType {
                            case .run:
                                attempt = .addToRun(position: .end) // Default to end
                            case .numberSet, .colorSet:
                                attempt = .addToSet
                            }
                            
                            let form = AddCardForm(
                                cardID: card.id,
                                completedRequirementID: completedReq.id,
                                belongingToPlayerID: otherPlayerHand.player.id,
                                attempt: attempt
                            )
                            
                            // Try to add the card - if it fails, continue to next option
                            try? addCard(form: form)
                            return // Only add one card per turn
                        }
                    }
                }
            }
        }
    }
    
    private mutating func makeAIDiscardDecision() throws {
        guard let currentPlayerHand = self.currentPlayerHand else { return }
        
        // Strategy: Discard the least useful card
        var cardScores: [(card: Card, score: Int)] = []
        
        for card in currentPlayerHand.cards {
            let score = calculateCardScore(card, for: currentPlayerHand)
            cardScores.append((card: card, score: score))
        }
        
        // Sort by score (lowest first) and discard the worst card
        cardScores.sort { $0.score < $1.score }
        
        if let worstCard = cardScores.first {
            // If it's a skip card, try to target the player with the fewest cards
            if case .skip(nil) = worstCard.card.cardType {
                if let targetPlayerID = findBestSkipTarget() {
                    try setSkip(
                        myPlayerID: currentPlayerHand.player.id,
                        cardID: worstCard.card.id,
                        skipPlayerID: targetPlayerID
                    )
                }
            }
            
            try discard(worstCard.card.id)
        }
    }
    
    private func calculateCardScore(_ card: Card, for playerHand: PlayerHand) -> Int {
        var score = 0
        
        // Lower score = more likely to discard
        switch card.cardType {
        case .skip:
            score = 10 // Moderately useful for disruption
            
        case .wild:
            score = 50 // Very useful, keep
            
        case .number:
            // Check if this card helps with current stage requirements
            if !playerHand.isRequirementsComplete {
                for requirement in playerHand.player.stage.requirements {
                    if canCardHelpWithRequirement(card, requirement: requirement, hand: playerHand) {
                        score += 30
                    }
                }
            }
            
            // Check if card can be added to others' completed requirements
            // Only if current player has completed their own stage
            if playerHand.isRequirementsComplete {
                for otherPlayerHand in playerHands {
                    if otherPlayerHand.player.id != playerHand.player.id {
                        for completedReq in otherPlayerHand.completed {
                            if canAddCardToCompletedRequirement(card, completedRequirement: completedReq) {
                                score += 10
                            }
                        }
                    }
                }
            }
            
            // Base score for number cards
            score += 5
        }
        
        return score
    }
    
    private func findBestSkipTarget() -> String? {
        guard let currentPlayerHand = self.currentPlayerHand else { return nil }
        
        // Target the player with the fewest cards (most likely to go out soon)
        let otherPlayers = playerHands.filter { $0.player.id != currentPlayerHand.player.id }
        let targetPlayer = otherPlayers.min { $0.cards.count < $1.cards.count }
        
        return targetPlayer?.player.id
    }
}
