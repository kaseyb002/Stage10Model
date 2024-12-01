import Foundation

extension Game {
    public mutating func finishRoundIfNeeded() throws {
        guard let currentRound: Round,
              currentRound.state == .roundComplete
        else {
            return
        }
        try finishRound()
    }
    
    public mutating func finishRound() throws {
        guard state == .playing else {
            throw Stage10Error.attemptedToActWithNoCurrentPlayer
        }
        guard let round: Round = currentRound else {
            throw Stage10Error.gameHasNoRounds
        }
        guard round.state == .roundComplete else {
            throw Stage10Error.roundIsIncomplete
        }
        
        var gameIsFinished: Bool = false
        for playerHand in round.playerHands {
            guard let playerIndex: Int = players.firstIndex(where: {
                playerHand.player.id == $0.id
            }) else {
                continue
            }
            players[playerIndex].points += playerHand.player.points
            if playerHand.isRequirementsComplete && playerHand.player.stage == .ten {
                gameIsFinished = true
            } else if let nextStage: Stage = players[playerIndex].stage.next {
                players[playerIndex].stage = nextStage
            }
        }
        
        if gameIsFinished {
            try finishGame()
        } else {
            try moveToNextRound()
        }
    }
    
    private mutating func moveToNextRound() throws {
        var rotatedPlayers: [Player] = players
        let lastPlayer: Player = rotatedPlayers.removeLast()
        rotatedPlayers.insert(lastPlayer, at: .zero)
        self.players = rotatedPlayers
        let nextRound: Round = try .init(players: players)
        rounds.append(nextRound)
    }
    
    private mutating func finishGame() throws {
        guard let winner: Player = players
            .filter({ $0.stage == .ten })
            .sorted(by: { $0.points < $1.points })
            .first // i dont care about ties
        else {
            throw Stage10Error.gameIsIncomplete
        }
        state = .complete(winner: winner)
        ended = .now
    }
    
    public var winner: Player? {
        switch state {
        case .complete(let winner):
            winner
            
        case .playing:
            nil
        }
    }
    
    public var currentLeader: Player? {
        if let winner: Player {
            return winner
        }
        
        return players
            .sorted(by: { $0.points < $1.points })
            .sorted(by: { $0.stage.numberValue > $1.stage.numberValue })
            .first
    }
    
    public var currentRoundIndex: Int? {
        guard rounds.isEmpty == false else {
            return nil
        }
        return rounds.count - 1
    }
    
    public var currentRound: Round? {
        rounds.last
    }
    
    public var logValue: String {
        """
        State: \(state.logValue)
        Round: \(rounds.count)
        Player stats: \(players.count) players
        \(players.logValue)
        """
    }
}
