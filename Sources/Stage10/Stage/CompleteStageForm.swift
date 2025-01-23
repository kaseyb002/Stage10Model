import Foundation

public struct CompleteStageForm: Equatable, Codable {
    public let stage: Stage
    public let completionAttempts: [CompletionAttempt]
    
    public struct CompletionAttempt: Equatable, Codable {
        public let requirement: StageRequirement
        public let cardIDs: [CardID]
        
        public init(
            requirement: StageRequirement,
            cardIDs: [CardID]
        ) {
            self.requirement = requirement
            self.cardIDs = cardIDs
        }
    }
    
    public init(
        stage: Stage,
        completionAttempts: [CompletionAttempt]
    ) {
        self.stage = stage
        self.completionAttempts = completionAttempts
    }
}
