import Foundation

public enum Stage10Error: Error, Equatable {
    case notEnoughPlayers
    case tooManyPlayers
    case attemptedToActWithNoCurrentPlayer
    case notWaitingForPlayerToPickUp
    case notWaitingForPlayerToDiscard
    case notWaitingForPlayerToAct
    case cardDoesNotExistInPlayersHand
    case requirementsAlreadyCompleted
    case didNotCompleteAllRequirementsForStage
    case requirementDoesNotExist
    case roundIsIncomplete
    case playerNotFound
    case completedRequirementDoesNotExist
    case completionAttemptsDoesNotMatchRequirements
    case discardedSkipWithoutSpecifyingPlayerToSkip
    case triedToSkipYourself
    case triedToSkipWithCardThatsAlreadyBeenUsed
    case triedToSkipWithCardThatIsNotSkip
    case notAWild
    case insufficientCards
    case runNotLongEnough(countNeeded: Int)
    case setNotBigEnough(countNeeded: Int)
    case requiredLengthBelowMin
    case requiredLengthAboveMax
    case isNotValidNextCard
    case runReachedEnd
    case invalidCard
    case cardsDoNotMakeRun
    case missingAddPositionForRun
    case gameIsComplete
}
