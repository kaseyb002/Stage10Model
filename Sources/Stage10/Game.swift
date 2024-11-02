import Foundation

public struct Game: Equatable {
    public let id: String
    public let started: Date
    public internal(set) var state: State
    public internal(set) var players: [Player]
    public internal(set) var rounds: [Round] {
        didSet { try? finishRoundIfNeeded() }
    }
    public internal(set) var ended: Date?

    public enum State: Equatable {
        case playing
        case complete(winner: Player)
        
        public var logValue: String {
            switch self {
            case .playing:
                "Playing"
                
            case .complete(let winner):
                "\(winner.name) won."
            }
        }
    }
    
    public init(
        players: [Player],
        cookedDeck: [Card]? = nil
    ) throws {
        self.id = UUID().uuidString
        self.started = .now
        self.players = players.map {
            Player(
                id: $0.id,
                name: $0.name,
                imageURL: $0.imageURL,
                points: .zero,
                stage: .one
            )
        }
        let firstRound: Round = try .init(
            cookedDeck: cookedDeck,
            players: self.players
        )
        self.rounds = [firstRound]
        self.state = .playing
    }
}
