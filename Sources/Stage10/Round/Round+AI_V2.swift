import Foundation

extension Round {
    public func makeAIMoveIfNeededV2() throws -> Round {
        guard case .waitingForPlayerToAct(_, let discardState) = self.state,
              let currentPlayerHand: PlayerHand = self.currentPlayerHand
        else {
            return self
        }
        
        var updatedRound = self
        
        do {
            switch discardState {
            case .needsToPickUp:
        try updatedRound.makeAIPickupDecision(playerHand: currentPlayerHand)
                
            case .needsToDiscard:
                // Try to complete stage first if possible
                if !currentPlayerHand.isRequirementsComplete {
        try updatedRound.attemptLaydownIfNeeded(playerHand: currentPlayerHand)
                }
                
                // Try to add cards to other players' completed requirements
        try updatedRound.attemptAddCardsIfNeeded(playerHand: currentPlayerHand)
                
                // Finally discard a card
        try updatedRound.makeAIDiscardDecision(playerHand: currentPlayerHand)
            }
        } catch {
            // If AI encounters an error, just pick up from deck and discard first card
            // This ensures the game doesn't get stuck
            do {
                if discardState == .needsToPickUp {
                    try updatedRound.pickUpCard(fromDiscardPile: false)
                }
                if case .waitingForPlayerToAct(_, .needsToDiscard) = updatedRound.state,
                   let firstCardID = updatedRound.currentPlayerHand?.cards.first?.id {
                    try updatedRound.discard(firstCardID)
                }
            } catch {
                // Last resort - return original round if everything fails
                return self
            }
        }
        
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
        // if possible, if the next player has their requirements complete, do not discard
        // a card that the player could add to his own completed requirements or another players compelted requirements
        
        guard let currentPlayerHandIndex = currentPlayerHandIndex else {
            throw Stage10Error.notWaitingForPlayerToAct
        }
        
        let availableCards = playerHand.cards.filter { !$0.cardType.isWild }
        
        // Rule 1: Never discard wild cards
        // Rule 2: Prioritize discarding skip cards first
        let skipCards = availableCards.filter { $0.cardType.isSkip }
        if !skipCards.isEmpty {
            // Find the best skip card to discard
            let bestSkipCard = findBestSkipCardToDiscard(skipCards: skipCards, currentPlayerHandIndex: currentPlayerHandIndex)
            
            if let cardToDiscard = bestSkipCard {
                // If it's an unconfigured skip, set a target
                if case .skip(nil) = cardToDiscard.cardType {
                    if let targetPlayerID = findBestSkipTarget() {
                        try setSkip(
                            myPlayerID: playerHand.player.id,
                            cardID: cardToDiscard.id,
                            skipPlayerID: targetPlayerID
                        )
                    }
                }
                try discard(cardToDiscard.id)
                return
            }
        }
        
        // Rule 3: Analyze requirements and find cards that don't help
        let requirements = playerHand.player.stage.requirements
        let cardsToAvoid = getCardsToAvoidDiscarding(playerHand: playerHand)
        
        // Find the best card to discard based on requirements
        let bestCardToDiscard = findBestCardToDiscard(
            availableCards: availableCards,
            requirements: requirements,
            cardsToAvoid: cardsToAvoid,
            playerHand: playerHand
        )
        
        try discard(bestCardToDiscard.id)
    }
    
    // MARK: - Helper Functions for Discard Decision
    
    private func getNextPlayerID(currentPlayerHandIndex: Int) -> String {
        let nextPlayerIndex = (currentPlayerHandIndex + 1) % playerHands.count
        return playerHands[nextPlayerIndex].player.id
    }
    
    private func getCardsToAvoidDiscarding(playerHand: PlayerHand) -> Set<CardID> {
        var cardsToAvoid: Set<CardID> = []
        
        // Check if next player has completed requirements and could use our cards
        let nextPlayerID = getNextPlayerID(currentPlayerHandIndex: currentPlayerHandIndex ?? 0)
        if let nextPlayerHand = playerHands.first(where: { $0.player.id == nextPlayerID }),
           nextPlayerHand.isRequirementsComplete {
            
            // Check if any of our cards could be added to their completed requirements
            for card in playerHand.cards {
                for otherPlayerHand in playerHands {
                    for completedRequirement in otherPlayerHand.completed {
                        do {
                            if try canAddCardToCompletedRequirement(
                                card: card,
                                cardNumber: card.cardType.numberValue ?? .one,
                                cardColor: card.cardType.color ?? .blue,
                                completedRequirement: completedRequirement,
                                belongingToPlayerID: otherPlayerHand.player.id,
                                for: playerHand
                            ) {
                                cardsToAvoid.insert(card.id)
                            }
                        } catch {
                            // Card can't be added, so it's safe to discard
                        }
                    }
                }
            }
        }
        
        return cardsToAvoid
    }
    
    private func findBestCardToDiscard(
        availableCards: [Card],
        requirements: [StageRequirement],
        cardsToAvoid: Set<CardID>,
        playerHand: PlayerHand
    ) -> Card {
        // Filter out cards we should avoid
        let safeCards = availableCards.filter { !cardsToAvoid.contains($0.id) }
        
        // If we have safe cards, analyze them by requirement
        if !safeCards.isEmpty {
            return analyzeCardsByRequirements(cards: safeCards, requirements: requirements, playerHand: playerHand)
        }
        
        // If all cards are unsafe, pick the least valuable one
        return analyzeCardsByRequirements(cards: availableCards, requirements: requirements, playerHand: playerHand)
    }
    
    private func analyzeCardsByRequirements(
        cards: [Card],
        requirements: [StageRequirement],
        playerHand: PlayerHand
    ) -> Card {
        var cardScores: [CardID: Int] = [:]
        
        for card in cards {
            var score = 0
            
            // Base score on card value (higher points = worse to keep)
            score += card.cardType.points
            
            // Analyze how this card helps with each requirement
            for requirement in requirements {
                let helpScore = evaluateCardForRequirement(card: card, requirement: requirement, playerHand: playerHand)
                score += helpScore
            }
            
            cardScores[card.id] = score
        }
        
        // Return the card with the highest score (least useful)
        return cards.max { cardScores[$0.id, default: 0] < cardScores[$1.id, default: 0] } ?? cards.first!
    }
    
    private func evaluateCardForRequirement(card: Card, requirement: StageRequirement, playerHand: PlayerHand) -> Int {
        let availableCards = playerHand.cards.filter { !$0.cardType.isSkip }
        let wildCards = availableCards.filter { $0.cardType.isWild }
        
        switch requirement {
        case .numberSet(let count):
            return evaluateCardForNumberSet(card: card, count: count, availableCards: availableCards, wildCards: wildCards)
            
        case .run(let length):
            return evaluateCardForRun(card: card, length: length, availableCards: availableCards, wildCards: wildCards)
            
        case .colorSet(let count):
            return evaluateCardForColorSet(card: card, count: count, availableCards: availableCards, wildCards: wildCards)
        }
    }
    
    private func evaluateCardForNumberSet(card: Card, count: Int, availableCards: [Card], wildCards: [Card]) -> Int {
        guard let cardNumber = card.cardType.numberValue else { return 0 }
        
        // Count how many cards match this number (including wilds)
        let matchingCards = availableCards.filter { card in
            card.cardType.numberValue == cardNumber || card.cardType.isWild
        }
        
        // If we already have enough for the set, this card is less valuable
        if matchingCards.count >= count {
            return 10
        }
        
        // If this card helps complete the set, it's valuable (negative score)
        if matchingCards.count + 1 >= count {
            return -5
        }
        
        // If this card doesn't help much, it's less valuable
        return 5
    }
    
    private func evaluateCardForRun(card: Card, length: Int, availableCards: [Card], wildCards: [Card]) -> Int {
        guard let cardNumber = card.cardType.numberValue else { return 0 }
        
        // Collect all unique numbers in hand
        var numbersInHand = Set<Int>()
        for card in availableCards {
            if let number = card.cardType.numberValue {
                numbersInHand.insert(number.rawValue)
            }
        }
        
        // Add this card's number
        numbersInHand.insert(cardNumber.rawValue)
        
        // Find longest potential run including wilds
        let sortedNumbers = numbersInHand.sorted()
        let wildcardCount = wildCards.count + (card.cardType.isWild ? 1 : 0)
        
        if canFormRun(numbers: sortedNumbers, wildcardsAvailable: wildcardCount, requiredLength: length) {
            return -5 // This card helps with the run
        }
        
        // Check for duplicate numbers (bad for runs)
        let duplicateCount = availableCards.filter { $0.cardType.numberValue == cardNumber }.count
        if duplicateCount > 0 {
            return 10 // Duplicates are bad for runs
        }
        
        return 5 // Neutral value
    }
    
    private func evaluateCardForColorSet(card: Card, count: Int, availableCards: [Card], wildCards: [Card]) -> Int {
        guard let cardColor = card.cardType.color else { return 0 }
        
        // Count how many cards match this color (including wilds)
        let matchingCards = availableCards.filter { card in
            card.cardType.color == cardColor || card.cardType.isWild
        }
        
        // If we already have enough for the set, this card is less valuable
        if matchingCards.count >= count {
            return 10
        }
        
        // If this card helps complete the set, it's valuable (negative score)
        if matchingCards.count + 1 >= count {
            return -5
        }
        
        // If this card doesn't help much, it's less valuable
        return 5
    }
}

// MARK: - Laydown Decision
extension Round {
    private mutating func attemptLaydownIfNeeded(playerHand: PlayerHand) throws {
        // attempt to complete the requirements with your current set of cards
        // this will be very difficult, because you can use wilds
        // that increases the computational complexity massively
        // i heard somewhere you can use a greedy algorithm to help solve this
        // but i dont know if that's true or not, just an idea i'll throw out there
        
        // Only proceed if the player hasn't completed their requirements yet
        guard !playerHand.isRequirementsComplete else {
            return
        }
        
        let requirements = playerHand.player.stage.requirements
        let availableCards = playerHand.cards
        
        // Try to find a valid combination of cards for all requirements
        if let validCombination = findValidRequirementCombination(
            requirements: requirements,
            availableCards: availableCards
        ) {
            // Pre-configure wild cards before completion
            try setWildCardsUsedAs(for: validCombination)
            
            // Create the completion form
            let form = CompleteStageForm(completionAttempts: validCombination)
            try completeStage(form: form)
        }
    }
    
    // MARK: - Helper Functions for Laydown Decision
    
    private func findValidRequirementCombination(
        requirements: [StageRequirement],
        availableCards: [Card]
    ) -> [CompleteStageForm.CompletionAttempt]? {
        // Use a greedy approach: try to fulfill each requirement optimally
        var remainingCards = availableCards
        var attempts: [CompleteStageForm.CompletionAttempt] = []
        
        for requirement in requirements {
            if let (cardIDs, usedCards) = findBestCardsForRequirement(
                requirement: requirement,
                availableCards: remainingCards
            ) {
                attempts.append(CompleteStageForm.CompletionAttempt(
                    requirement: requirement,
                    cardIDs: cardIDs
                ))
                // Remove used cards from remaining cards
                let usedCardIDs = Set(usedCards.map(\.id))
                remainingCards = remainingCards.filter { !usedCardIDs.contains($0.id) }
            } else {
                // Can't fulfill this requirement
                return nil
            }
        }
        
        return attempts
    }
    
    private func findBestCardsForRequirement(
        requirement: StageRequirement,
        availableCards: [Card]
    ) -> (cardIDs: [CardID], usedCards: [Card])? {
        switch requirement {
        case .numberSet(let count):
            return findBestCardsForNumberSet(count: count, availableCards: availableCards)
        case .run(let length):
            return findBestCardsForRun(length: length, availableCards: availableCards)
        case .colorSet(let count):
            return findBestCardsForColorSet(count: count, availableCards: availableCards)
        }
    }
    
    private func findBestCardsForNumberSet(
        count: Int,
        availableCards: [Card]
    ) -> (cardIDs: [CardID], usedCards: [Card])? {
        // Group cards by number value
        var numberGroups: [CardNumber: [Card]] = [:]
        var wildCards: [Card] = []
        
        for card in availableCards {
            if card.cardType.isWild {
                wildCards.append(card)
            } else if let number = card.cardType.numberValue {
                numberGroups[number, default: []].append(card)
            }
        }
        
        // Find the number with the most cards
        let bestNumber = numberGroups.max { $0.value.count < $1.value.count }?.key
        
        if let bestNumber = bestNumber,
           let cards = numberGroups[bestNumber],
           cards.count + wildCards.count >= count {
            var selectedCards: [Card] = Array(cards.prefix(count))
            let wildsNeeded = max(0, count - selectedCards.count)
            selectedCards.append(contentsOf: wildCards.prefix(wildsNeeded))
            
            return (selectedCards.map(\.id), selectedCards)
        }
        
        // If no number has enough cards, use wilds
        if wildCards.count >= count {
            let selectedWilds = Array(wildCards.prefix(count))
            return (selectedWilds.map(\.id), selectedWilds)
        }
        
        return nil
    }
    
    private func findBestCardsForRun(
        length: Int,
        availableCards: [Card]
    ) -> (cardIDs: [CardID], usedCards: [Card])? {
        // Extract numbers and wilds
        var numbers: [Int] = []
        var wildCards: [Card] = []
        
        for card in availableCards {
            if card.cardType.isWild {
                wildCards.append(card)
            } else if let number = card.cardType.numberValue {
                numbers.append(number.rawValue)
            }
        }
        
        let uniqueNumbers = Array(Set(numbers)).sorted()
        let wildCount = wildCards.count
        
        // Try to find the best run
        if let bestRun = findBestRun(
            numbers: uniqueNumbers,
            wildcardsAvailable: wildCount,
            requiredLength: length
        ) {
            var selectedCards: [Card] = []
            var wildsUsed = 0
            
            // Add number cards for the run
            for number in bestRun.numbers {
                if let card = availableCards.first(where: { 
                    $0.cardType.numberValue?.rawValue == number 
                }) {
                    selectedCards.append(card)
                }
            }
            
            // Add wild cards as needed
            let wildsNeeded = bestRun.wildsNeeded
            for i in 0..<wildsNeeded {
                if i < wildCards.count {
                    selectedCards.append(wildCards[i])
                    wildsUsed += 1
                }
            }
            
            return (selectedCards.map(\.id), selectedCards)
        }
        
        return nil
    }
    
    private func findBestCardsForColorSet(
        count: Int,
        availableCards: [Card]
    ) -> (cardIDs: [CardID], usedCards: [Card])? {
        // Group cards by color
        var colorGroups: [CardColor: [Card]] = [:]
        var wildCards: [Card] = []
        
        for card in availableCards {
            if card.cardType.isWild {
                wildCards.append(card)
            } else if let color = card.cardType.color {
                colorGroups[color, default: []].append(card)
            }
        }
        
        // Find the color with the most cards
        let bestColor = colorGroups.max { $0.value.count < $1.value.count }?.key
        
        if let bestColor = bestColor,
           let cards = colorGroups[bestColor],
           cards.count + wildCards.count >= count {
            var selectedCards: [Card] = Array(cards.prefix(count))
            let wildsNeeded = max(0, count - selectedCards.count)
            selectedCards.append(contentsOf: wildCards.prefix(wildsNeeded))
            
            return (selectedCards.map(\.id), selectedCards)
        }
        
        // If no color has enough cards, use wilds
        if wildCards.count >= count {
            let selectedWilds = Array(wildCards.prefix(count))
            return (selectedWilds.map(\.id), selectedWilds)
        }
        
        return nil
    }
    
    private struct RunResult {
        let numbers: [Int]
        let wildsNeeded: Int
    }
    
    private func findBestRun(
        numbers: [Int],
        wildcardsAvailable: Int,
        requiredLength: Int
    ) -> RunResult? {
        guard !numbers.isEmpty else { return nil }
        
        var bestRun: RunResult? = nil
        var maxLength = 0
        
        // Try starting from each number
        for startIndex in 0..<numbers.count {
            let startNumber = numbers[startIndex]
            var currentRun: [Int] = [startNumber]
            var wildsUsed = 0
            
            // Try to extend the run forward
            for i in (startIndex + 1)..<numbers.count {
                let nextNumber = numbers[i]
                let gap = nextNumber - currentRun.last!
                
                if gap == 1 {
                    // Consecutive number
                    currentRun.append(nextNumber)
                } else if gap > 1 && gap - 1 <= wildcardsAvailable - wildsUsed {
                    // Can fill gap with wilds
                    wildsUsed += (gap - 1)
                    currentRun.append(nextNumber)
                } else {
                    // Gap too large, stop extending
                    break
                }
            }
            
            // Try to extend backward with wilds
            let minNumber = currentRun.first!
            let backwardWilds = min(wildcardsAvailable - wildsUsed, max(0, minNumber - 1))
            wildsUsed += backwardWilds
            
            // Try to extend forward with remaining wilds
            let maxNumber = currentRun.last!
            let forwardWilds = min(wildcardsAvailable - wildsUsed, max(0, 12 - maxNumber))
            wildsUsed += forwardWilds
            
            let totalLength = currentRun.count + wildsUsed
            
            if totalLength >= requiredLength && totalLength > maxLength {
                maxLength = totalLength
                bestRun = RunResult(numbers: currentRun, wildsNeeded: wildsUsed)
            }
        }
        
        return bestRun
    }
    
    // MARK: - Skip Card Strategy
    
    private func findBestSkipCardToDiscard(skipCards: [Card], currentPlayerHandIndex: Int) -> Card? {
        let nextPlayerID = getNextPlayerID(currentPlayerHandIndex: currentPlayerHandIndex)
        
        // Prefer skip cards that don't target the next player
        let safeSkipCards = skipCards.filter { card in
            if case .skip(let targetPlayerID) = card.cardType {
                return targetPlayerID != nextPlayerID
            }
            return true
        }
        
        return safeSkipCards.first ?? skipCards.first
    }
    
    private func findBestSkipTarget() -> String? {
        guard let currentPlayerHand = self.currentPlayerHand else { return nil }
        
        // Target the player with the fewest cards (most likely to go out soon)
        let otherPlayers = playerHands.filter { $0.player.id != currentPlayerHand.player.id }
        let targetPlayer = otherPlayers.min { $0.cards.count < $1.cards.count }
        
        return targetPlayer?.player.id
    }
    
    // MARK: - Wild Card Pre-configuration
    
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
}

// MARK: - Add Cards
extension Round {
    private mutating func attemptAddCardsIfNeeded(playerHand: PlayerHand) throws {
        // if player's requirements are complete, try to add each of his cards
        // to every player's completed requirements, including his own
        
        // Only proceed if the current player has completed their requirements
        guard playerHand.isRequirementsComplete else {
            return
        }
        
        // Try to add each card in the player's hand to every completed requirement
        for card in playerHand.cards {
            for otherPlayerHand in playerHands {
                for completedRequirement in otherPlayerHand.completed {
                    // Determine the appropriate attempt type based on requirement type
                    let attempts: [AddCardForm.Attempt] = {
                        switch completedRequirement.requirementType {
                        case .numberSet, .colorSet:
                            return [.addToSet]
                        case .run:
                            return [.addToRun(position: .beginning), .addToRun(position: .end)]
                        }
                    }()
                    
                    // Try each possible attempt
                    for attempt in attempts {
                        let form = AddCardForm(
                            cardID: card.id,
                            completedRequirementID: completedRequirement.id,
                            belongingToPlayerID: otherPlayerHand.player.id,
                            attempt: attempt
                        )
                        
                        do {
                            try addCard(form: form)
                            // If successful, continue to next card
                            break
                        } catch {
                            // This attempt failed, try the next one
                            continue
                        }
                    }
                }
            }
        }
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
