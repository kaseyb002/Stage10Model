import Foundation

public enum FailedObjectiveError: Error, Equatable {
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
}
