import Foundation

public struct CompleteStageForm: Equatable, Codable, Sendable {
    public let completionAttempts: [CompletionAttempt]
    
    public struct CompletionAttempt: Equatable, Codable, Sendable {
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
