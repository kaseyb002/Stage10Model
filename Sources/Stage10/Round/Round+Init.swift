import Foundation

extension Round {
    public init(
        id: String = UUID().uuidString,
        started: Date = .init(),
        cookedDeck: [Card]? = nil,
        players: [Player]
    ) throws {
        guard players.count >= 2 else {
            throw Stage10Error.notEnoughPlayers
        }
        guard players.count <= 6 else {
            throw Stage10Error.tooManyPlayers
        }
        self.id = id
        self.started = started
        var deck: [Card] = cookedDeck ?? .deck().shuffled()
        self.playerHands = Self.dealCards(
            to: players,
            deck: &deck
        )
        let firstDiscard: Card = deck.removeLast()
        self.deck = deck
        self.discardPile = [firstDiscard]
        self.state = .waitingForPlayerToAct(
            playerId: players.first!.id,
            discardState: .needsToPickUp
        )
    }
    
    /// returns `nil` if game is complete
    public static func nextRound(
        previous: Round
    ) throws -> Round? {
        struct GameIsComplete: Error {}
        
        func nextRoundPlayers() throws -> [Player] {
            var players: [Player] = previous.playerHands.map(\.player)
            for i in 0 ..< players.count {
                if previous.playerHands[i].isRequirementsComplete {
                    if let nextStage: Stage = players[i].stage.next {
                        players[i].stage = nextStage
                    } else {
                        throw GameIsComplete()
                    }
                }
            }
            return players
        }
        
        do {
            return try .init(players: nextRoundPlayers())
        } catch is GameIsComplete {
            return nil
        } catch {
            throw error
        }
    }
    
    private static func dealCards(
        to players: [Player],
        deck: inout [Card]
    ) -> [PlayerHand] {
        var playerHands: [PlayerHand] = []
        
        for player in players {
            let playerCards: [Card] = Array(deck.suffix(10))
            deck.removeLast(10)
            let playerHand: PlayerHand = .init(
                player: player,
                cards: playerCards,
                completed: []
            )
            playerHands.append(playerHand)
        }
        
        return playerHands
    }
}
