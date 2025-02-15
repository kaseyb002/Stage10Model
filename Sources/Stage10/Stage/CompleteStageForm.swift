import Foundation

public struct CompleteStageForm: Equatable, Codable {
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
        completionAttempts: [CompletionAttempt]
    ) {
        self.completionAttempts = completionAttempts
    }
}
