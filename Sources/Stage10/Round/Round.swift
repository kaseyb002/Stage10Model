import Foundation

public struct Round: Equatable, Codable {
    // MARK: - Initialized Properties
    public let id: String
    public let started: Date
    
    // MARK: - Round Progression
    public internal(set) var state: State
    public internal(set) var cardsMap: [CardID: Card]
    public internal(set) var deck: [CardID]
    public internal(set) var discardPile: [CardID]
    public internal(set) var playerHands: [PlayerHand]
    public internal(set) var skipQueue: Dictionary<String, Int> = [:]
    
    // MARK: - Results
    public internal(set) var log: Log = .init()
    public internal(set) var ended: Date?
    
    public enum State: Equatable, Codable {
        case waitingForPlayerToAct(playerId: String, discardState: DiscardState)
        case roundComplete
        case gameComplete(winner: Player)
        
        public enum DiscardState: Hashable, Codable {
            case needsToPickUp
            case needsToDiscard
        }
        
        public var logValue: String {
            switch self {
            case .waitingForPlayerToAct(let playerID, discardState: .needsToPickUp):
                "Waiting for player \(playerID) to pick up card"
                
            case .waitingForPlayerToAct(let playerID, discardState: .needsToDiscard):
                "Waiting for player \(playerID) to discard"
                
            case .roundComplete:
                "Round complete"
                
            case .gameComplete(let winner):
                "\(winner) won the game."
            }
        }
    }
}
