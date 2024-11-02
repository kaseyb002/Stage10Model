import Foundation

extension Round {
    public mutating func discard(_ card: Card) throws {
        guard let currentPlayerHandIndex: Int else {
            throw Stage10Error.attemptedToActWithNoCurrentPlayer
        }
        guard let cardIndex: Int = playerHands[currentPlayerHandIndex].cards.firstIndex(of: card) else {
            throw Stage10Error.cardDoesNotExistInPlayersHand
        }
        let discarded: Card = playerHands[currentPlayerHandIndex].cards.remove(at: cardIndex)
        discardPile.append(discarded)
        
        func advanceCurrentPlayer(by amount: Int) {
            let newPlayerIndex: Int = (currentPlayerHandIndex + amount) % playerHands.count
            self.state = .waitingForPlayerToAct(
                playerIndex: newPlayerIndex,
                discardState: .needsToPickUp
            )
        }
        
        switch discarded {
        case .skip:
            advanceCurrentPlayer(by: 2)
            
        case .wild, .number:
            advanceCurrentPlayer(by: 1)
        }
        
        checkIfCardsAreEmpty()
    }
    
    public mutating func complete(
        requirement: CompletedRequirement,
        with cards: [Card]
    ) throws {
        guard let currentPlayerHandIndex: Int else {
            throw Stage10Error.attemptedToActWithNoCurrentPlayer
        }
        guard playerHands[currentPlayerHandIndex].isRequirementsComplete == false else {
            throw Stage10Error.requirementsAlreadyCompleted
        }
        // verify player actually has these cards
        guard playerHands[currentPlayerHandIndex].cards.contains(other: cards) else {
            throw Stage10Error.cardDoesNotExistInPlayersHand
        }
        let requirements: [StageRequirement] = playerHands[currentPlayerHandIndex].player.stage.requirements
        let completed: [CompletedRequirement] = playerHands[currentPlayerHandIndex].completed
        var remaining: [StageRequirement] = requirements
        for completedRequirement in completed {
            guard let index: Int = requirements.firstIndex(of: completedRequirement.stageRequirement) else {
                continue
            }
            remaining.remove(at: index)
        }
        guard remaining.contains(requirement.stageRequirement) else {
            throw Stage10Error.requirementDoesNotExist
        }
        playerHands[currentPlayerHandIndex].completed.append(requirement)
        playerHands[currentPlayerHandIndex].cards.remove(other: cards)
        checkIfCardsAreEmpty()
    }
    
    public mutating func pickUpCard(fromDiscardPile: Bool) throws {
        guard case .waitingForPlayerToAct(
            let currentPlayerHandIndex,
            discardState: .needsToPickUp
        ) = state else {
            throw Stage10Error.notWaitingForPlayerToPickUp
        }
        let card: Card =
        if fromDiscardPile,
           let topCardOfDiscardPile: Card = discardPile.last,
           topCardOfDiscardPile != .skip {
            discardPile.removeLast()
        } else {
            deck.removeLast()
        }
        playerHands[currentPlayerHandIndex].cards.append(card)
        state = .waitingForPlayerToAct(
            playerIndex: currentPlayerHandIndex,
            discardState: .needsToDiscard
        )
    }
    
    public mutating func add(
        card: Card,
        to completedRequirement: CompletedRequirement,
        belongingToPlayerID playerID: String,
        runPosition: Run.AddPosition?
    ) throws {
        guard let currentPlayerHandIndex: Int else {
            throw Stage10Error.attemptedToActWithNoCurrentPlayer
        }
        guard playerHands[currentPlayerHandIndex].cards.contains(card) else {
            throw Stage10Error.cardDoesNotExistInPlayersHand
        }
        guard let playerHandIndex: Int = playerHands.firstIndex(where: {
            playerID == $0.player.id
        }) else {
            throw Stage10Error.playerNotFound
        }
        guard let completedRequirementIndex: Int = playerHands[playerHandIndex].completed.firstIndex(of: completedRequirement) else {
            throw Stage10Error.completedRequirementDoesNotExist
        }
        let updatedCompletedRequirement: CompletedRequirement
        switch playerHands[playerHandIndex].completed[completedRequirementIndex] {
        case .numberSet(var numberSet):
            switch card {
            case .skip:
                throw FailedObjectiveError.invalidCard
                
            case .wild(let wildCard):
                try numberSet.add(wildCard: wildCard)
                
            case .number(let numberCard):
                try numberSet.add(numberCard: numberCard)
            }
            updatedCompletedRequirement = .numberSet(numberSet)
            
        case .colorSet(var colorSet):
            switch card {
            case .skip:
                throw FailedObjectiveError.invalidCard
                
            case .wild(let wildCard):
                try colorSet.add(wildCard: wildCard)
                
            case .number(let numberCard):
                try colorSet.add(numberCard: numberCard)
            }
            updatedCompletedRequirement = .colorSet(colorSet)
            
        case .run(var run):
            switch card {
            case .skip:
                throw FailedObjectiveError.invalidCard
                
            case .wild(let wildCard):
                guard let runPosition: Run.AddPosition else {
                    throw FailedObjectiveError.missingAddPositionForRun
                }
                try run.add(wildCard: wildCard, position: runPosition)
                
            case .number(let numberCard):
                try run.add(numberCard: numberCard)
            }
            updatedCompletedRequirement = .run(run)
        }
        playerHands[playerHandIndex].completed[completedRequirementIndex] = updatedCompletedRequirement
        if let index: Int = playerHands[currentPlayerHandIndex].cards.firstIndex(of: card) {
            playerHands[currentPlayerHandIndex].cards.remove(at: index)
        }
    }
    
    public mutating func checkIfCardsAreEmpty() {
        let aPlayerHasNoMoreCards: Bool = playerHands.contains(where: { $0.cards.isEmpty })
        guard aPlayerHasNoMoreCards || deck.isEmpty else {
            return
        }
        for (index, playerHand) in playerHands.enumerated() {
            playerHands[index].player.points = playerHand.cards.totalPoints
        }
        self.state = .roundComplete
        self.ended = .now
    }
}
