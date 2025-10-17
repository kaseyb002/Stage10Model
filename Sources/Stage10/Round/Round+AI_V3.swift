import Foundation

extension Round {
    public func makeAIMoveIfNeededV3() throws -> Round {
        guard case .waitingForPlayerToAct(_, let discardState) = self.state,
              let currentPlayerHand: PlayerHand = self.currentPlayerHand
        else {
            return self
        }
        
        var updatedRound = self
        switch discardState {
        case .needsToPickUp:
            try updatedRound.makeAIPickupDecision(playerHand: currentPlayerHand)
            
        case .needsToDiscard:
            if let currentPlayerHand: PlayerHand = self.currentPlayerHand,
               !currentPlayerHand.isRequirementsComplete {
                try updatedRound.attemptLaydownIfNeeded(playerHand: self.currentPlayerHand!)
            }
            
            // Try to add cards to other players' completed requirements
            if let currentPlayerHand: PlayerHand = self.currentPlayerHand {
                try updatedRound.attemptAddCardsIfNeeded(playerHand: currentPlayerHand)
            }
            
            // Finally discard a card
            if let currentPlayerHand: PlayerHand = self.currentPlayerHand {
                try updatedRound.makeAIDiscardDecision(playerHand: currentPlayerHand)
            }
        }
        
        return updatedRound
    }
    
    private func findBestSkipCardToDiscard(
        skipCards: [Card],
        currentPlayerHandIndex: Int
    ) -> Card? {
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
    
    // MARK: - Discard Decision
    private mutating func makeAIDiscardDecision(playerHand: PlayerHand) throws {
        // Rule 1: Never discard wild cards
        let availableCards: [Card] = playerHand.cards.compactMap { cardID in
            guard let card = cardsMap[cardID] else { return nil }
            return card.cardType.isWild ? nil : card
        }
        // Rule 2: Prioritize discarding skip cards first
        let skipCards = availableCards.filter { $0.cardType.isSkip }
        if !skipCards.isEmpty {
            // Try to find a skip card we can safely discard
            for skipCard in skipCards {
                if case .skip(let targetPlayerID) = skipCard.cardType {
                    if targetPlayerID != nil {
                        // Skip card already has a target, safe to discard
                        try discard(skipCard.id)
                        return
                    }
                }
            }
            
            // If no skip cards have targets, try to configure one
            if let unconfiguredSkip = skipCards.first(where: {
                if case .skip(nil) = $0.cardType { return true }
                return false
            }) {
                if let targetPlayerID = findBestSkipTarget() {
                    try setSkip(
                        myPlayerID: playerHand.player.id,
                        cardID: unconfiguredSkip.id,
                        skipPlayerID: targetPlayerID
                    )
                    try discard(unconfiguredSkip.id)
                    return
                }
            }
        }
        
        // Rule 3: Analyze requirements and find cards that don't help
        let requirements = playerHand.player.stage.requirements
        let cardsToAvoid = getCardsToAvoidDiscarding(playerHand: playerHand)
        
        // Find the best card to discard based on requirements
        if playerHand.isRequirementsComplete {
            let safeCards = availableCards.filter { !cardsToAvoid.contains($0.id) }
            if safeCards.isEmpty {
                try discard(availableCards.first!.id)
            } else {
                try discard(safeCards.first!.id)
            }

        } else {
            let bestCardToDiscard = findBestCardToDiscard(
                availableCards: availableCards,
                cardsToAvoid: cardsToAvoid,
                playerHand: playerHand
            )
            try discard(bestCardToDiscard.id)
        }
    }
    
    private func findBestCardToDiscard(
        availableCards playerCards: [Card],
        cardsToAvoid: Set<CardID>,
        playerHand: PlayerHand
    ) -> Card {
        // Filter out cards we should avoid
        let safeCards = playerCards.filter { !cardsToAvoid.contains($0.id) }
        
        for card in safeCards {
            guard let cardNumber: CardNumber = card.cardType.numberValue,
                  let cardColor: CardColor = card.cardType.color
            else {
                continue
            }
            switch playerHand.player.stage {
            case .one, .seven, .nine, .ten: // multiple sets
                if shouldPickUpForSet(
                    card: card,
                    cardNumber: cardNumber,
                    playerCards: playerCards
                ) == false {
                    return card
                }
                
            case .two, .three: // mixed set + run
                if shouldPickUpForSet(
                    card: card,
                    cardNumber: cardNumber,
                    playerCards: playerCards
                ) == false &&
                    shouldPickUpForRun(
                        card: card,
                        cardNumber: cardNumber,
                        playerCards: playerCards
                    ) == false {
                    return card
                }

            case .eight: // colors
                if shouldPickUpForColor(
                    card: card,
                    cardColor: cardColor,
                    playerCards: playerCards
                ) == false {
                    return card
                }
                
            case .four, .five, .six: // pure run
                if shouldPickUpForRun(
                    card: card,
                    cardNumber: cardNumber,
                    playerCards: playerCards
                ) == false {
                    return card
                }
            }
        }
        
        return safeCards.sortedForDisplay.last!
    }
    
    private func getCardsToAvoidDiscarding(playerHand: PlayerHand) -> Set<CardID> {
        var cardsToAvoid: Set<CardID> = []
        
        // Check if next player has completed requirements and could use our cards
        let nextPlayerID = getNextPlayerID(currentPlayerHandIndex: currentPlayerHandIndex ?? 0)
        if let nextPlayerHand = playerHands.first(where: { $0.player.id == nextPlayerID }),
           nextPlayerHand.isRequirementsComplete {
            
            // Check if any of our cards could be added to their completed requirements
            for cardID in playerHand.cards {
                guard let card = cardsMap[cardID] else { continue }
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
    
    private func findBestSkipTarget() -> String? {
        guard let currentPlayerHand = self.currentPlayerHand else { return nil }
        
        // Target the player with the fewest cards (most likely to go out soon)
        let otherPlayers = playerHands.filter { $0.player.id != currentPlayerHand.player.id }
        let targetPlayer = otherPlayers.min { $0.cards.count < $1.cards.count }
        
        return targetPlayer?.player.id
    }

    // MARK: - Laydown Decision
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
        let availableCards = playerHand.cards.compactMap { cardID in cardsMap[cardID] }
        
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

    // MARK: - Pickup Decision
    private mutating func makeAIPickupDecision(playerHand: PlayerHand) throws {
        guard let topDiscardCardID = discardPile.last,
              let topDiscardCard = cardsMap[topDiscardCardID] else {
            try pickUpCard(fromDiscardPile: false)
            return
        }
        
        switch topDiscardCard.cardType {
        case .skip:
            try pickUpCard(fromDiscardPile: false)
            
        case .wild:
            try pickUpCard(fromDiscardPile: true)
            
        case .number(let numberCard):
            if playerHand.isRequirementsComplete {
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
            } else {
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
        let playerCards: [Card] = cardsMap.findCards(byIDs: playerHand.cards)
        
        switch playerHand.player.stage {
        case .one, .seven, .nine, .ten: // multiple sets
            return shouldPickUpForSet(
                card: card,
                cardNumber: cardNumber,
                playerCards: playerCards
            )
            
        case .two, .three: // mixed set + run
            if shouldPickUpForSet(
                card: card,
                cardNumber: cardNumber,
                playerCards: playerCards
            ) {
                return true
            } else {
                return shouldPickUpForRun(
                    card: card,
                    cardNumber: cardNumber,
                    playerCards: playerCards
                )
            }
            
        case .eight: // colors
            return shouldPickUpForColor(
                card: card,
                cardColor: cardColor,
                playerCards: playerCards
            )
            
        case .four, .five, .six: // pure run
            return shouldPickUpForRun(
                card: card,
                cardNumber: cardNumber,
                playerCards: playerCards
            )
        }
    }
    
    private func shouldPickUpForColor(
        card: Card,
        cardColor: CardColor,
        playerCards: [Card]
    ) -> Bool {
        var colorCounts: [CardColor: Int] = [:]
        for playerCard in playerCards {
            guard playerCard.cardType.isNumber,
                  let color: CardColor = playerCard.cardType.color
            else {
                continue
            }
            colorCounts[color, default: .zero] += 1
        }
        guard let highestCount: Int = colorCounts.values.max() else {
            return false
        }
        return colorCounts[cardColor] == highestCount
    }
    
    private func shouldPickUpForSet(
        card: Card,
        cardNumber: CardNumber,
        playerCards: [Card]
    ) -> Bool {
        var numberCounts: [CardNumber: Int] = [:]
        for playerCard in playerCards {
            guard playerCard.cardType.isNumber,
                  let number: CardNumber = playerCard.cardType.numberValue
            else {
                continue
            }
            numberCounts[number, default: .zero] += 1
        }
        guard //let maxCount: Int = numberCounts.values.max(),
              let setCount: Int = numberCounts[cardNumber]
        else {
            return false
        }
        let pairCount: Int = numberCounts.values.count(where: { $0 > 1 })
        switch setCount {
        case 2:
            return pairCount < 4
            
        case 1:
            return pairCount < 3

        default:
            return true
        }
    }
    
    private func shouldPickUpForRun(
        card: Card,
        cardNumber: CardNumber,
        playerCards: [Card]
    ) -> Bool {
        if playerCards.contains(where: { $0.cardType.isNumber && $0.cardType.numberValue == cardNumber }) {
            return false
        }
        
        switch card.cardType.numberValue {
        case .three, .four, .five, .six, .seven, .eight, .nine, .ten:
            return true
            
        case .one, .two:
            return uniqueCardNumbersCount(matching: { $0 <= .six }, in: playerCards) > uniqueCardNumbersCount(matching: { $0 > .six }, in: playerCards)
            
        case .eleven, .twelve:
            return uniqueCardNumbersCount(matching: { $0 > .six }, in: playerCards) > uniqueCardNumbersCount(matching: { $0 <= .six }, in: playerCards)

        case .none:
            return false
        }
    }
    
    private func uniqueCardNumbersCount(
        matching: (CardNumber) -> Bool,
        in cards: [Card]
    ) -> Int {
        var usedNumbers: Set<CardNumber> = []
        var count: Int = .zero
        for card in cards where card.cardType.isNumber {
            guard let numberValue: CardNumber = card.cardType.numberValue,
                card.cardType.isNumber,
                usedNumbers.contains(numberValue) == false else {
                continue
            }
            if matching(numberValue) {
                count += 1
                usedNumbers.insert(numberValue)
            }
        }
        return count
    }
    
    // MARK: - Add Cards
    private mutating func attemptAddCardsIfNeeded(
        playerHand: PlayerHand
    ) throws {
        // if player's requirements are complete, try to add each of his cards
        // to every player's completed requirements, including his own
        
        // Only proceed if the current player has completed their requirements
        guard playerHand.isRequirementsComplete else {
            return
        }
        
        // Try to add each card in the player's hand to every completed requirement
        for cardID in playerHand.cards {
            guard let card = cardsMap[cardID] else { continue }
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
    
    // MARK: - Helper Funcs
    private func getNextPlayerID(currentPlayerHandIndex: Int) -> String {
        let nextPlayerIndex = (currentPlayerHandIndex + 1) % playerHands.count
        return playerHands[nextPlayerIndex].player.id
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
    
    // MARK: - Laydown Helpers
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
    
    // MARK: - Wild Card Pre-configuration
    
    private mutating func setWildCardsUsedAs(for completionAttempts: [CompleteStageForm.CompletionAttempt]) throws {
        guard let currentPlayerHand = self.currentPlayerHand else { return }
        
        for attempt in completionAttempts {
            switch attempt.requirement {
            case .numberSet(_):
                // Find the target number from non-wild cards
                var targetNumber: CardNumber?
                for cardID in attempt.cardIDs {
                    if let card = cardsMap[cardID],
                       let number = card.cardType.numberValue {
                        targetNumber = number
                        break
                    }
                }
                
                // If we found a target number, set wild cards to use that number
                if let targetNumber = targetNumber {
                    for cardID in attempt.cardIDs {
                        if let card = cardsMap[cardID],
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
                    if let card = cardsMap[cardID],
                       let color = card.cardType.color {
                        targetColor = color
                        break
                    }
                }
                
                // If we found a target color, set wild cards to use that color
                if let targetColor = targetColor {
                    for cardID in attempt.cardIDs {
                        if let card = cardsMap[cardID],
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
            if let card = cardsMap[cardID] {
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
