import Foundation

extension Round {
    public static func fake(
        id: String = UUID().uuidString,
        started: Date = .init(),
        cookedDeck: [Card]? = nil,
        players: [Player] = [
            .fake(),
            .fake(),
            .fake(),
            .fake(),
        ]
    ) throws -> Round{
        try self.init(
            id: id,
            started: started,
            cookedDeck: cookedDeck,
            players: players
        )
    }
}
