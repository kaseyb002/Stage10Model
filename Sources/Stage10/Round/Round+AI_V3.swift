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
            if let currentPlayerHand: PlayerHand = updatedRound.currentPlayerHand,
               !currentPlayerHand.isRequirementsComplete {
                try? updatedRound.attemptLaydownIfNeeded(playerHand: currentPlayerHand)
            }
            
            // Try to add cards to other players' completed requirements
            if let currentPlayerHand: PlayerHand = updatedRound.currentPlayerHand {
                try? updatedRound.attemptAddCardsIfNeeded(playerHand: currentPlayerHand)
            }
            
            // Finally discard a card
            if let currentPlayerHand: PlayerHand = updatedRound.currentPlayerHand {
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
        guard availableCards.isEmpty == false else {
            if let cardID: CardID = playerHand.cards.first {
                try discard(cardID)
            }
            return
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
                let numberCounts: [CardNumber: Int] = numberCounts(for: playerCards)
                let cardNumberWithLowestCount: CardNumber = numberCounts.keys
                    .max(by: { (numberCounts[$0] ?? 0) > (numberCounts[$1] ?? 0) })!
                if let card: Card = playerCards
                    .first(where: { $0.cardType.isNumber && $0.cardType.numberValue == cardNumberWithLowestCount }) {
                    return card
                }
                if shouldPickUpForSet(
                    card: card,
                    cardNumber: cardNumber,
                    playerCards: playerCards
                ) == false {
                    return card
                }
                
            case .two, .three: // mixed set + run
                // being lazy
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
                let colorCounts: [CardColor: Int] = colorCounts(for: playerCards)
                let cardColorWithLowestCount: CardColor = colorCounts.keys
                    .max(by: { (colorCounts[$0] ?? 0) > (colorCounts[$1] ?? 0) })!
                if let card: Card = playerCards
                    .first(where: { $0.cardType.isNumber && $0.cardType.color == cardColorWithLowestCount }) {
                    return card
                }
                if shouldPickUpForColor(
                    card: card,
                    cardColor: cardColor,
                    playerCards: playerCards
                ) == false {
                    return card
                }
                
            case .four, .five, .six: // pure run
                let numberCounts: [CardNumber: Int] = numberCounts(for: playerCards)
                let cardNumberWithHighestCount: CardNumber = numberCounts.keys
                    .max(by: { (numberCounts[$0] ?? 0) < (numberCounts[$1] ?? 0) })!
                if (numberCounts.values.max() ?? 0) > 1,
                   let card: Card = playerCards
                    .first(where: { $0.cardType.isNumber && $0.cardType.numberValue == cardNumberWithHighestCount }) {
                    return card
                }
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
        
        // Only proceed if the player hasn't completed their requirements yet
        guard !playerHand.isRequirementsComplete else {
            return
        }
        
        let requirements = playerHand.player.stage.requirements
        let availableCards = cardsMap.findCards(byIDs: playerHand.cards)
        
        // Try to find a valid combination of cards that satisfies all requirements
        if let completionAttempts = try findValidCompletion(
            requirements: requirements,
            availableCards: availableCards,
            playerHand: playerHand
        ) {
            // Pre-configure wild cards before completing the stage
            try setWildCardsUsedAs(for: completionAttempts)
            
            // Complete the stage with the found combination
            let form = CompleteStageForm(completionAttempts: completionAttempts)
            try completeStage(form: form)
        }
    }
    
    private mutating func findValidCompletion(
        requirements: [StageRequirement],
        availableCards: [Card],
        playerHand: PlayerHand
    ) throws -> [CompleteStageForm.CompletionAttempt]? {
        switch playerHand.player.stage {
        case .one:
            return try makeSetAttempts(
                firstCount: 3,
                secondCount: 3,
                availableCards: availableCards,
                playerHand: playerHand
            )
            
        case .two:
            var remainingCards: [Card] = availableCards
            guard let set: Set<CardID> = try makeSet(
                of: 3,
                with: remainingCards,
                playerID: playerHand.player.id
            ) else {
                return nil
            }
            remainingCards.removeAll(where: { set.contains($0.id) })
            guard let run: Array<CardID> = try makeRun(
                of: 4,
                with: remainingCards,
                playerID: playerHand.player.id
            ) else {
                return nil
            }
            return [
                .init(requirement: .numberSet(count: 3), cardIDs: Array(set)),
                .init(requirement: .run(length: 4), cardIDs: run),
            ]
            
        case .three:
            var remainingCards: [Card] = availableCards
            guard let set: Set<CardID> = try makeSet(
                of: 4,
                with: remainingCards,
                playerID: playerHand.player.id
            ) else {
                return nil
            }
            remainingCards.removeAll(where: { set.contains($0.id) })
            guard let run: Array<CardID> = try makeRun(
                of: 4,
                with: remainingCards,
                playerID: playerHand.player.id
            ) else {
                return nil
            }
            return [
                .init(requirement: .numberSet(count: 4), cardIDs: Array(set)),
                .init(requirement: .run(length: 4), cardIDs: run),
            ]
    
        case .four:
            return try makeRunAttempts(
                of: 7,
                with: availableCards,
                playerID: playerHand.player.id
            )
            
        case .five:
            return try makeRunAttempts(
                of: 8,
                with: availableCards,
                playerID: playerHand.player.id
            )
            
        case .six:
            return try makeRunAttempts(
                of: 9,
                with: availableCards,
                playerID: playerHand.player.id
            )
            
        case .seven:
            return try makeSetAttempts(
                firstCount: 4,
                secondCount: 4,
                availableCards: availableCards,
                playerHand: playerHand
            )
            
        case .eight:
            guard let set: Set<CardID> = try makeColorSet(
                of: 7,
                with: availableCards,
                playerID: playerHand.player.id
            ) else {
                return nil
            }
            return [
                .init(requirement: .colorSet(count: 7), cardIDs: Array(set))
            ]

        case .nine:
            return try makeSetAttempts(
                firstCount: 5,
                secondCount: 2,
                availableCards: availableCards,
                playerHand: playerHand
            )
            
        case .ten:
            return try makeSetAttempts(
                firstCount: 5,
                secondCount: 3,
                availableCards: availableCards,
                playerHand: playerHand
            )
        }
    }
    
    private mutating func makeSetAttempts(
        firstCount: Int,
        secondCount: Int,
        availableCards: [Card],
        playerHand: PlayerHand
    ) throws -> [CompleteStageForm.CompletionAttempt]? {
        var remainingCards: [Card] = availableCards
        guard let firstSet: Set<CardID> = try makeSet(
            of: firstCount,
            with: remainingCards,
            playerID: playerHand.player.id
        ) else {
            return nil
        }
        remainingCards.removeAll(where: { firstSet.contains($0.id) })
        guard let secondSet: Set<CardID> = try makeSet(
            of: secondCount,
            with: remainingCards,
            playerID: playerHand.player.id
        ) else {
            return nil
        }
        return [
            .init(requirement: .numberSet(count: firstCount), cardIDs: Array(firstSet)),
            .init(requirement: .numberSet(count: secondCount), cardIDs: Array(secondSet)),
        ]
    }
    
    private mutating func makeSet(
        of count: Int,
        with cards: [Card],
        playerID: String
    ) throws -> Set<CardID>? {
        guard cards.isEmpty == false else {
            return nil
        }
        let numberCounts: [CardNumber: Int] = numberCounts(for: cards)
        let cardNumberWithHighestCount: CardNumber = numberCounts.keys
            .max(by: { (numberCounts[$0] ?? 0) < (numberCounts[$1] ?? 0) })!
        // grab all the other cards
        var set: [Card] = Array(cards
            .filter({ $0.cardType.isNumber && $0.cardType.numberValue == cardNumberWithHighestCount })
            .prefix(count)) // AI will add cards later if needed. want to save to potential run cards
        if set.count >= count {
            return Set(set.map(\.id))
        }
        let wilds: [Card] = cards.filter({ $0.cardType.isWild })
        for wild in wilds {
            try useWildAs(
                myPlayerID: playerID,
                cardID: wild.id,
                usedAs: .number(cardNumberWithHighestCount)
            )
            set.append(wild)
            if set.count >= count {
                return Set(set.map(\.id))
            }
        }
        return nil
    }
    
    private mutating func makeColorSet(
        of count: Int,
        with cards: [Card],
        playerID: String
    ) throws -> Set<CardID>? {
        guard cards.isEmpty == false else {
            return nil
        }
        let colorCounts: [CardColor: Int] = colorCounts(for: cards)
        let cardColorWithHighestCount: CardColor = colorCounts.keys
            .max(by: { (colorCounts[$0] ?? 0) < (colorCounts[$1] ?? 0) })!
        // grab all the other cards
        var set: [Card] = Array(cards
            .filter({ $0.cardType.isNumber && $0.cardType.color == cardColorWithHighestCount })
            .prefix(count)) // AI will add cards later if needed. want to save to potential run cards
        if set.count >= count {
            return Set(set.map(\.id))
        }
        let wilds: [Card] = cards.filter({ $0.cardType.isWild })
        for wild in wilds {
            try useWildAs(
                myPlayerID: playerID,
                cardID: wild.id,
                usedAs: .color(cardColorWithHighestCount)
            )
            set.append(wild)
            if set.count >= count {
                return Set(set.map(\.id))
            }
        }
        return nil
    }
    
    private mutating func makeRunAttempts(
        of count: Int,
        with cards: [Card],
        playerID: String
    ) throws -> [CompleteStageForm.CompletionAttempt]? {
        if let run: Array<CardID> = try makeRun(of: count, with: cards, playerID: playerID) {
            return [
                .init(requirement: .run(length: count), cardIDs: run)
            ]
        } else {
            return nil
        }
    }

    private mutating func makeRun(
        of count: Int,
        with cards: [Card],
        playerID: String
    ) throws -> Array<CardID>? {
        guard cards.isEmpty == false else {
            return nil
        }
        
        // Separate wild cards from number cards
        var numberCards: [CardNumber: Card] = [:]
        var wildCards: [Card] = []
        
        for card in cards {
            if card.cardType.isWild {
                wildCards.append(card)
            } else if let number = card.cardType.numberValue {
                // Keep only one card per number (first occurrence)
                if numberCards[number] == nil {
                    numberCards[number] = card
                }
            }
        }
        
        // Try to find a run starting from each possible number
        var bestRun: [Card]?
        var bestNonWildCount = 0
        
        for startNumber in CardNumber.allCases {
            var cardsInRun: [Card] = []
            var currentNumber = startNumber
            var wildsUsedInThisRun = 0
            
            for _ in 0..<count {
                if let card = numberCards[currentNumber] {
                    cardsInRun.append(card)
                } else if wildsUsedInThisRun < wildCards.count {
                    cardsInRun.append(wildCards[wildsUsedInThisRun])
                    wildsUsedInThisRun += 1
                } else {
                    break
                }
                
                // Move to next number
                guard let nextNumber = CardNumber(rawValue: currentNumber.rawValue + 1) else {
                    break
                }
                currentNumber = nextNumber
            }
            
            if cardsInRun.count >= count {
                let nonWildCount = cardsInRun.filter { !$0.cardType.isWild }.count
                // Prefer runs with more non-wild cards
                if nonWildCount > bestNonWildCount {
                    bestNonWildCount = nonWildCount
                    bestRun = Array(cardsInRun.prefix(count))
                }
            }
        }
        
        guard var run = bestRun else {
            return nil
        }
        
        // Configure wild cards to the appropriate numbers in the run
        var startNumber: CardNumber?
        for card in run {
            if let number = card.cardType.numberValue {
                startNumber = number
                break
            }
        }
        
        if let startNumber = startNumber {
            for (index, card) in run.enumerated() {
                if card.cardType.isWild {
                    let targetNumber = CardNumber(rawValue: startNumber.rawValue + index) ?? startNumber
                    try useWildAs(
                        myPlayerID: playerID,
                        cardID: card.id,
                        usedAs: .number(targetNumber)
                    )
                    run[index] = .init(
                        id: card.id,
                        cardType: .wild(
                            .init(
                                color: card.cardType.color ?? .blue,
                                usedAs: .number(targetNumber)
                            )
                        )
                    )
                }
            }
        }
        
        return run.sorted(by: { $0.cardType.numberValue! < $1.cardType.numberValue! }).map(\.id)
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
        let numberCounts: [CardNumber: Int] = numberCounts(for: playerCards)
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
    
    private func numberCounts(for cards: [Card]) -> [CardNumber: Int] {
        var numberCounts: [CardNumber: Int] = [:]
        for playerCard in cards {
            guard playerCard.cardType.isNumber,
                  let number: CardNumber = playerCard.cardType.numberValue
            else {
                continue
            }
            numberCounts[number, default: .zero] += 1
        }
        return numberCounts
    }
    
    private func colorCounts(for cards: [Card]) -> [CardColor: Int] {
        var colorCounts: [CardColor: Int] = [:]
        for playerCard in cards {
            guard playerCard.cardType.isNumber,
                  let color: CardColor = playerCard.cardType.color
            else {
                continue
            }
            colorCounts[color, default: .zero] += 1
        }
        return colorCounts
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
