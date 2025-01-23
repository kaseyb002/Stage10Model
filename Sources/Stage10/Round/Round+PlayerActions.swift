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
        
        guard let cardIndex: Int = playerHands[myPlayerIndex].cards.firstIndex(where: { $0.id == cardID }) else {
            throw Stage10Error.cardDoesNotExistInPlayersHand
        }
        
        switch playerHands[myPlayerIndex].cards[cardIndex].cardType {
        case .skip:
            playerHands[myPlayerIndex].cards[cardIndex].cardType = .skip(playerID: skipPlayerID)
            
        case .wild, .number:
            throw Stage10Error.triedToSkipWithCardThatIsNotSkip
        }
    }
    
    public mutating func useWildAs(
        myPlayerID: String,
        cardID: Int,
        usedAs: WildCard.UsedAs
    ) throws {
        guard let myPlayerIndex: Int = playerHands.firstIndex(where: { $0.player.id == myPlayerID }) else {
            throw Stage10Error.playerNotFound
        }
        
        guard let cardIndex: Int = playerHands[myPlayerIndex].cards.firstIndex(where: { $0.id == cardID }) else {
            throw Stage10Error.cardDoesNotExistInPlayersHand
        }
        
        let card: Card = playerHands[myPlayerIndex].cards[cardIndex]
        switch card.cardType {
        case .wild:
            var newWild: WildCard = .init(
                color: card.cardType.color ?? .blue,
                usedAs: usedAs
            )
            playerHands[myPlayerIndex].cards[cardIndex].cardType = .wild(newWild)

        case .skip, .number:
            throw Stage10Error.notAWild
        }
    }

    public mutating func discard(_ cardID: CardID) throws {
        guard case .waitingForPlayerToAct(let currentPlayerHandIndex, .needsToDiscard) = state else {
            throw Stage10Error.notWaitingForPlayerToDiscard
        }
        guard let cardIndex: Int = playerHands[currentPlayerHandIndex].cards.firstIndex(where: { $0.id == cardID }) else {
            throw Stage10Error.cardDoesNotExistInPlayersHand
        }
        let discarded: Card = playerHands[currentPlayerHandIndex].cards.remove(at: cardIndex)
        discardPile.append(discarded)
        
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
            playerIndex: newPlayerIndex,
            discardState: .needsToPickUp
        )
    }
    
    private mutating func takePlayerCards(by ids: [CardID]) throws -> [Card] {
        guard let currentPlayerHandIndex else {
            throw Stage10Error.notWaitingForPlayerToAct
        }
        
        func removeCard(by id: CardID) throws -> Card {
            guard let index: Int = playerHands[currentPlayerHandIndex].cards.firstIndex(where: { id == $0.id }) else {
                throw Stage10Error.cardDoesNotExistInPlayersHand
            }
            return playerHands[currentPlayerHandIndex].cards.remove(at: index)
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
        var requirements: [StageRequirement] = form.stage.requirements
        guard requirements.count == form.completionAttempts.count else {
            throw Stage10Error.completionAttemptsDoesNotMatchRequirements
        }
        var completedRequirements: [CompletedRequirement] = []

        for attempt in form.completionAttempts {
            let cards: [Card] = try takePlayerCards(by: attempt.cardIDs)
            let completedRequirement: CompletedRequirement
            switch attempt.requirement {
            case .numberSet(let count):
                let numberSet: NumberSet = try .init(
                    requiredCount: count,
                    number: cards.first?.cardType.numberValue ?? .one,
                    cards: cards
                )
                completedRequirement = .init(
                    requirementType: .numberSet(numberSet)
                )
                
            case .run(let length):
                let run: Run = try .init(
                    requiredLength: length,
                    cards: cards
                )
                completedRequirement = .init(
                    requirementType: .run(run)
                )
                
            case .colorSet(let count):
                let colorSet: ColorSet = try .init(
                    requiredCount: count,
                    color: cards.first?.cardType.color ?? .blue,
                    cards: cards
                )
                completedRequirement = .init(
                    requirementType: .colorSet(colorSet)
                )
            }
            
            guard let index: Int = requirements.firstIndex(where: { $0 == attempt.requirement }) else {
                throw Stage10Error.requirementDoesNotExist
            }
            requirements.remove(at: index)
            completedRequirements.append(completedRequirement)
        }
        
        guard requirements.isEmpty else {
            throw Stage10Error.didNotCompleteAllRequirementsForStage
        }
        
        playerHands[currentPlayerHandIndex].completed = completedRequirements
        
        checkIfCardsAreEmpty()
    }
    
    public mutating func pickUpCard(fromDiscardPile: Bool) throws {
        guard case .waitingForPlayerToAct(
            let currentPlayerHandIndex,
            discardState: .needsToPickUp
        ) = state else {
            throw Stage10Error.notWaitingForPlayerToPickUp
        }
        let card: Card
        if fromDiscardPile,
           let topCardOfDiscardPile: Card = discardPile.last,
           topCardOfDiscardPile.cardType.isSkip == false {
            card = discardPile.removeLast()
        } else {
            guard deck.isEmpty == false else {
                endRoundBecauseDeckIsEmpty()
                return
            }
            card = deck.removeLast()
        }
        playerHands[currentPlayerHandIndex].cards.append(card)
        state = .waitingForPlayerToAct(
            playerIndex: currentPlayerHandIndex,
            discardState: .needsToDiscard
        )
    }
    
    public mutating func addCard(
        form: AddCardForm
    ) throws {
        guard let currentPlayerHandIndex: Int else {
            throw Stage10Error.attemptedToActWithNoCurrentPlayer
        }
        guard let card: Card = playerHands[currentPlayerHandIndex].cards
            .first(where: { $0.id == form.cardID })
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
                throw FailedObjectiveError.missingAddPositionForRun
            }
        }
        playerHands[belongingToPlayerIndex].completed[completedRequirementIndex] = updatedCompletedRequirement
        playerHands[currentPlayerHandIndex].cards.removeAll(where: { form.cardID == $0.id })
        checkIfCardsAreEmpty()
    }
    
    @discardableResult
    private mutating func checkIfCardsAreEmpty() -> Bool {
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
            playerHands[index].player.points = playerHand.cards.totalPoints
        }
    }
    
    private mutating func endRoundBecauseDeckIsEmpty() {
        addUpPlayerPoints()
        state = .roundComplete
        ended = .now
    }
}
