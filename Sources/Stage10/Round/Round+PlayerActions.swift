import Foundation

extension Round {
    public mutating func setSkip(
        myPlayerID: String,
        cardID: Int,
        skipPlayerID: String
    ) throws {
        guard let myPlayerIndex: Int = playerHands.firstIndex(where: { $0.player.id == myPlayerID }),
              playerHands.contains(where: { $0.player.id == skipPlayerID })
        else {
            throw Stage10Error.playerNotFound
        }
        
        guard playerHands[myPlayerIndex].cards.contains(cardID) else {
            throw Stage10Error.cardDoesNotExistInPlayersHand
        }
        
        guard var card = cardsMap[cardID] else {
            throw Stage10Error.cardDoesNotExistInPlayersHand
        }
        
        switch card.cardType {
        case .skip:
            card.cardType = .skip(playerId: skipPlayerID)
            cardsMap[cardID] = card
            
        case .wild, .number:
            throw Stage10Error.triedToSkipWithCardThatIsNotSkip
        }
    }
    
    public mutating func useWildAs(
        myPlayerID: String,
        cardID: Int,
        usedAs: WildCard.UsedAs
    ) throws {
        guard let myPlayerIndex: Int = playerHands
            .firstIndex(where: { $0.player.id == myPlayerID })
        else {
            throw Stage10Error.playerNotFound
        }
        
        guard playerHands[myPlayerIndex].cards.contains(cardID) else {
            throw Stage10Error.cardDoesNotExistInPlayersHand
        }
        
        guard var card = cardsMap[cardID] else {
            throw Stage10Error.cardDoesNotExistInPlayersHand
        }
        
        switch card.cardType {
        case .wild:
            let newWild: WildCard = .init(
                color: card.cardType.color ?? .blue,
                usedAs: usedAs
            )
            card.cardType = .wild(newWild)
            cardsMap[cardID] = card

        case .skip, .number:
            throw Stage10Error.notAWild
        }
    }

    public mutating func discard(_ cardID: CardID) throws {
        guard case .waitingForPlayerToAct(_, .needsToDiscard) = state,
              let currentPlayerHandIndex: Int
        else {
            throw Stage10Error.notWaitingForPlayerToDiscard
        }
        let currentPlayerID: String = playerHands[currentPlayerHandIndex].player.id
        guard let cardIndex: Int = playerHands[currentPlayerHandIndex].cards
            .firstIndex(where: { $0 == cardID })
        else {
            throw Stage10Error.cardDoesNotExistInPlayersHand
        }
        let discardedCardID: CardID = playerHands[currentPlayerHandIndex].cards.remove(at: cardIndex)
        discardPile.append(discardedCardID)
        
        guard let discarded = cardsMap[discardedCardID] else {
            throw Stage10Error.cardDoesNotExistInPlayersHand
        }
        
        if checkIfCardsAreEmpty() {
            return
        }
        
        switch discarded.cardType {
        case .skip(let playerID):
            guard let playerID: String else {
                throw Stage10Error.discardedSkipWithoutSpecifyingPlayerToSkip
            }
            guard playerID != playerHands[currentPlayerHandIndex].player.id else {
                throw Stage10Error.triedToSkipYourself
            }
            skipQueue[playerID, default: .zero] += 1
            
        case .wild, .number:
            break
        }
        
        log.addAction(
            .init(
                playerID: currentPlayerID,
                decision: .discard(cardId: cardID)
            )
        )
        
        advanceCurrentPlayer(currentPlayerHandIndex: currentPlayerHandIndex)
    }
    
    private mutating func advanceCurrentPlayer(
        currentPlayerHandIndex: Int
    ) {
        let newPlayerIndex: Int = (currentPlayerHandIndex + 1) % playerHands.count
        if var skipPlayerCount: Int = skipQueue[playerHands[newPlayerIndex].player.id],
           skipPlayerCount > .zero {
            skipPlayerCount -= 1
            skipQueue[playerHands[newPlayerIndex].player.id] = skipPlayerCount
            advanceCurrentPlayer(currentPlayerHandIndex: newPlayerIndex)
            return
        }
        
        state = .waitingForPlayerToAct(
            playerId: playerHands[newPlayerIndex].player.id,
            discardState: .needsToPickUp
        )
    }
    
    private mutating func takePlayerCards(by ids: [CardID]) throws -> [Card] {
        guard let currentPlayerHandIndex else {
            throw Stage10Error.notWaitingForPlayerToAct
        }
        
        func removeCard(by id: CardID) throws -> Card {
            guard let index: Int = playerHands[currentPlayerHandIndex].cards
                .firstIndex(where: { id == $0 })
            else {
                throw Stage10Error.cardDoesNotExistInPlayersHand
            }
            let cardID = playerHands[currentPlayerHandIndex].cards.remove(at: index)
            guard let card = cardsMap[cardID] else {
                throw Stage10Error.cardDoesNotExistInPlayersHand
            }
            return card
        }
        
        return try ids.map { try removeCard(by: $0) }
    }
    
    public mutating func completeStage(
        form: CompleteStageForm
    ) throws {
        guard let currentPlayerHandIndex: Int else {
            throw Stage10Error.notWaitingForPlayerToAct
        }
        guard playerHands[currentPlayerHandIndex].isRequirementsComplete == false else {
            throw Stage10Error.requirementsAlreadyCompleted
        }
        var requirements: [StageRequirement] = playerHands[currentPlayerHandIndex].player.stage.requirements
        guard requirements.count == form.completionAttempts.count else {
            throw Stage10Error.completionAttemptsDoesNotMatchRequirements
        }
        var completedRequirements: [CompletedRequirement] = []

        for attempt in form.completionAttempts {
            let cards: [Card] = cardsMap.findCards(byIDs: attempt.cardIDs)
            let completedRequirement: CompletedRequirement = try .init(
                requirement: attempt.requirement,
                cards: cards
            )
            guard let index: Int = requirements.firstIndex(where: { $0 == attempt.requirement }) else {
                throw Stage10Error.requirementDoesNotExist
            }
            requirements.remove(at: index)
            completedRequirements.append(completedRequirement)
        }
        
        guard requirements.isEmpty else {
            throw Stage10Error.didNotCompleteAllRequirementsForStage
        }
        
        _ = try takePlayerCards(by: form.completionAttempts.flatMap { $0.cardIDs })

        playerHands[currentPlayerHandIndex].completed = completedRequirements
        
        log.addAction(
            .init(
                playerID: playerHands[currentPlayerHandIndex].player.id,
                decision: .laydown(completedRequirements.map { .init(completedRequirement: $0) })
            )
        )
        
        checkIfCardsAreEmpty()
    }
    
    public mutating func pickUpCard(fromDiscardPile: Bool) throws {
        guard case .waitingForPlayerToAct(let currentPlayerID, discardState: .needsToPickUp) = state,
              let currentPlayerHandIndex: Int
        else {
            throw Stage10Error.notWaitingForPlayerToPickUp
        }
        let cardID: CardID
        if fromDiscardPile,
           let topCardID = discardPile.last,
           let topCard = cardsMap[topCardID],
           topCard.cardType.isSkip == false {
            cardID = discardPile.removeLast()
        } else {
            guard deck.isEmpty == false else {
                endRoundBecauseDeckIsEmpty()
                return
            }
            cardID = deck.removeLast()
        }
        playerHands[currentPlayerHandIndex].cards.append(cardID)
        log.addAction(
            .init(
                playerID: playerHands[currentPlayerHandIndex].player.id,
                decision: .pickup(cardId: cardID, fromDiscardPile: fromDiscardPile)
            )
        )
        state = .waitingForPlayerToAct(
            playerId: currentPlayerID,
            discardState: .needsToDiscard
        )
    }
    
    public mutating func addCard(
        form: AddCardForm
    ) throws {
        guard let currentPlayerHandIndex: Int else {
            throw Stage10Error.attemptedToActWithNoCurrentPlayer
        }
        guard playerHands[currentPlayerHandIndex].isRequirementsComplete else {
            throw Stage10Error.didNotCompleteAllRequirementsForStage
        }
        guard playerHands[currentPlayerHandIndex].cards.contains(form.cardID),
              let card: Card = cardsMap[form.cardID]
        else {
            throw Stage10Error.cardDoesNotExistInPlayersHand
        }
        guard let belongingToPlayerIndex: Int = playerHands
            .firstIndex(where: { $0.player.id == form.belongingToPlayerID })
        else {
            throw Stage10Error.playerNotFound
        }
        guard let completedRequirementIndex: Int = playerHands[belongingToPlayerIndex]
            .completed.firstIndex(where: { $0.id == form.completedRequirementID })
        else {
            throw Stage10Error.completedRequirementDoesNotExist
        }
        
        var updatedCompletedRequirement: CompletedRequirement = playerHands[belongingToPlayerIndex].completed[completedRequirementIndex]
        let originalCompletedRequirement: CompletedRequirement = updatedCompletedRequirement
        switch playerHands[belongingToPlayerIndex].completed[completedRequirementIndex].requirementType {
        case .numberSet(var numberSet):
            try numberSet.add(card: card)
            updatedCompletedRequirement.requirementType = .numberSet(numberSet)
            
        case .colorSet(var colorSet):
            try colorSet.add(card: card)
            updatedCompletedRequirement.requirementType = .colorSet(colorSet)
            
        case .run(var run):
            switch form.attempt {
            case .addToRun(let position):
                try run.add(card: card, position: position)
                updatedCompletedRequirement.requirementType = .run(run)

            case .addToSet:
                throw Stage10Error.missingAddPositionForRun
            }
        }
        playerHands[belongingToPlayerIndex].completed[completedRequirementIndex] = updatedCompletedRequirement
        playerHands[currentPlayerHandIndex].cards.removeAll(where: { form.cardID == $0 })
        log.addAction(
            .init(
                playerID: playerHands[currentPlayerHandIndex].player.id,
                decision: .addCard(id: card.id, toCompletedRequirement: .init(completedRequirement: originalCompletedRequirement))
            )
        )
        checkIfCardsAreEmpty()
    }
    
    @discardableResult
    private mutating func checkIfCardsAreEmpty() -> Bool {
        // first check if player has already won
        let playersOnLastStageCount: Int = playerHands
            .filter({ $0.player.stage == .ten })
            .count
        if playersOnLastStageCount == 1,
           let winner: PlayerHand = playerHands
               .filter({ $0.player.stage == .ten })
               .filter({ $0.isRequirementsComplete })
               .first {
            state = .gameComplete(winner: winner.player)
            return true
        }
        
        let aPlayerHasNoMoreCards: Bool = playerHands.contains(where: { $0.cards.isEmpty })
        guard aPlayerHasNoMoreCards || deck.isEmpty else {
            return false
        }
        addUpPlayerPoints()
        if let winner: PlayerHand = playerHands
            .filter({ $0.player.stage == .ten })
            .filter({ $0.isRequirementsComplete })
            .sorted(by: { $0.player.points < $1.player.points })
            .first { // i dont care about ties
            state = .gameComplete(winner: winner.player)
        } else {
            state = .roundComplete
        }
        ended = .now
        return true
    }
    
    private mutating func addUpPlayerPoints() {
        for (index, playerHand) in playerHands.enumerated() {
            playerHands[index].player.points += playerHand.cards.totalPoints(cardsMap: cardsMap)
        }
    }
    
    private mutating func endRoundBecauseDeckIsEmpty() {
        addUpPlayerPoints()
        state = .roundComplete
        ended = .now
    }
}
