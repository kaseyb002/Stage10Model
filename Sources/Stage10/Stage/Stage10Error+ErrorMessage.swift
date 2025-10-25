import Foundation

extension Stage10Error {
    public var errorMessage: String {
        switch self {
        case .notEnoughPlayers:
            "Not enough players."
            
        case .tooManyPlayers:
            "Too many players."
            
        case .attemptedToActWithNoCurrentPlayer:
            "Not waiting for player to act."
            
        case .notWaitingForPlayerToPickUp:
            "Not waiting for player to pick up a card."
            
        case .notWaitingForPlayerToDiscard:
            "Not waiting for player to discard."
            
        case .notWaitingForPlayerToAct:
            "Not waiting for player to act."
            
        case .cardDoesNotExistInPlayersHand:
            "Card does not exist in player's hand."
            
        case .requirementsAlreadyCompleted:
            "Requirements already completed."
            
        case .didNotCompleteAllRequirementsForStage:
            "Did not complete all requirements for this stage."
            
        case .requirementDoesNotExist:
            "Requirement does not exist for this stage."
            
        case .roundIsIncomplete:
            "Round is incomplete."
            
        case .playerNotFound:
            "Player not found."
            
        case .completedRequirementDoesNotExist:
            "Completed requirement does not exist in this stage."
            
        case .completionAttemptsDoesNotMatchRequirements:
            "Number of attempted requirement completions does not match the number of requirements."
            
        case .discardedSkipWithoutSpecifyingPlayerToSkip:
            "Tried to skip without specifying whom to skip."
            
        case .triedToSkipYourself:
            "You can't skip yourself."
            
        case .triedToSkipWithCardThatsAlreadyBeenUsed:
            "This skip has already been used."
            
        case .triedToSkipWithCardThatIsNotSkip:
            "You can't skip with a card that is not a skip."
            
        case .notAWild:
            "Not a wild card."
            
        case .insufficientCards:
            "Not enough cards."
            
        case .runNotLongEnough(let countNeeded):
            "Run isn't long enough. Needs \(countNeeded)."
            
        case .setNotBigEnough(let countNeeded):
            "Set isn't big enough. Needs \(countNeeded)."
            
        case .requiredLengthBelowMin:
            "Required length below minimum."
            
        case .requiredLengthAboveMax:
            "Required length above maximum."

        case .isNotValidNextCard:
            "Is not a valid next card."
            
        case .runReachedEnd:
            "Run can't go any further."
            
        case .invalidCard:
            "Card is not valid."
            
        case .cardsDoNotMakeRun:
            "These card do not make a run."
            
        case .missingAddPositionForRun:
            "You need to specify whether this card should be added to the beginning or end of the run."
            
        case .gameIsComplete:
            "Game is complete."
        }
    }
}
