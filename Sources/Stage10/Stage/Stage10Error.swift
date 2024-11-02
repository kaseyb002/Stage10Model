import Foundation

public enum Stage10Error: Error, Equatable {
    case notEnoughPlayers
    case tooManyPlayers
    case attemptedToActWithNoCurrentPlayer
    case notWaitingForPlayerToPickUp
    case cardDoesNotExistInPlayersHand
    case requirementsAlreadyCompleted
    case requirementDoesNotExist
    case roundIsIncomplete
    case gameIsAlreadyComplete
    case gameIsIncomplete
    case gameHasNoRounds
    case playerNotFound
    case completedRequirementDoesNotExist
}
