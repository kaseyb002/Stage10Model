import Testing
@testable import Stage10Model

@Test func deckSize() async throws {
    #expect([Card].deck().count == 108)
}

@Test func run() async throws {
    _ = try Run(
        requiredLength: 7,
        cards: [
            Card(id: 0, cardType: .number(NumberCard(number: .one, color: .allCases.randomElement()!))),
            Card(id: 1, cardType: .number(NumberCard(number: .two, color: .allCases.randomElement()!))),
            Card(id: 2, cardType: .number(NumberCard(number: .three, color: .allCases.randomElement()!))),
            Card(id: 3, cardType: .number(NumberCard(number: .four, color: .allCases.randomElement()!))),
            Card(id: 4, cardType: .number(NumberCard(number: .five, color: .allCases.randomElement()!))),
            Card(id: 5, cardType: .number(NumberCard(number: .six, color: .allCases.randomElement()!))),
            Card(id: 6, cardType: .number(NumberCard(number: .seven, color: .allCases.randomElement()!))),
        ]
    )
    
    #expect(throws: Stage10Error.insufficientCards) {
        _ = try Run(
            requiredLength: 8,
            cards: [
                Card(id: 0, cardType: .number(NumberCard(number: .one, color: .allCases.randomElement()!))),
                Card(id: 1, cardType: .number(NumberCard(number: .two, color: .allCases.randomElement()!))),
                Card(id: 2, cardType: .number(NumberCard(number: .three, color: .allCases.randomElement()!))),
                Card(id: 3, cardType: .number(NumberCard(number: .four, color: .allCases.randomElement()!))),
                Card(id: 4, cardType: .number(NumberCard(number: .five, color: .allCases.randomElement()!))),
                Card(id: 5, cardType: .number(NumberCard(number: .six, color: .allCases.randomElement()!))),
                Card(id: 6, cardType: .number(NumberCard(number: .seven, color: .allCases.randomElement()!))),
            ]
        )
    }
    
    #expect(throws: Stage10Error.isNotValidNextCard) {
        _ = try Run(
            requiredLength: 5,
            cards: [
                Card(id: 0, cardType: .number(NumberCard(number: .two, color: .allCases.randomElement()!))),
                Card(id: 1, cardType: .number(NumberCard(number: .two, color: .allCases.randomElement()!))),
                Card(id: 2, cardType: .number(NumberCard(number: .three, color: .allCases.randomElement()!))),
                Card(id: 3, cardType: .number(NumberCard(number: .four, color: .allCases.randomElement()!))),
                Card(id: 4, cardType: .number(NumberCard(number: .five, color: .allCases.randomElement()!))),
                Card(id: 5, cardType: .number(NumberCard(number: .six, color: .allCases.randomElement()!))),
                Card(id: 6, cardType: .number(NumberCard(number: .seven, color: .allCases.randomElement()!))),
            ]
        )
    }
    
    _ = try Run(
        requiredLength: 7,
        cards: [
            Card(id: 0, cardType: .wild(WildCard(color: .allCases.randomElement()!, usedAs: .number(.one)))),
            Card(id: 1, cardType: .number(NumberCard(number: .two, color: .allCases.randomElement()!))),
            Card(id: 2, cardType: .number(NumberCard(number: .three, color: .allCases.randomElement()!))),
            Card(id: 3, cardType: .number(NumberCard(number: .four, color: .allCases.randomElement()!))),
            Card(id: 4, cardType: .number(NumberCard(number: .five, color: .allCases.randomElement()!))),
            Card(id: 5, cardType: .number(NumberCard(number: .six, color: .allCases.randomElement()!))),
            Card(id: 6, cardType: .number(NumberCard(number: .seven, color: .allCases.randomElement()!))),
        ]
    )
    
    _ = try Run(
        requiredLength: 5,
        cards: [
            Card(id: 0, cardType: .wild(WildCard(color: .allCases.randomElement()!, usedAs: nil))),
            Card(id: 1, cardType: .number(NumberCard(number: .two, color: .allCases.randomElement()!))),
            Card(id: 2, cardType: .number(NumberCard(number: .three, color: .allCases.randomElement()!))),
            Card(id: 3, cardType: .number(NumberCard(number: .four, color: .allCases.randomElement()!))),
            Card(id: 4, cardType: .number(NumberCard(number: .five, color: .allCases.randomElement()!))),
            Card(id: 5, cardType: .number(NumberCard(number: .six, color: .allCases.randomElement()!))),
            Card(id: 6, cardType: .number(NumberCard(number: .seven, color: .allCases.randomElement()!))),
        ]
    )
    
    #expect(throws: Stage10Error.isNotValidNextCard) {
        _ = try Run(
            requiredLength: 5,
            cards: [
                Card(id: 1, cardType: .number(NumberCard(number: .two, color: .allCases.randomElement()!))),
                Card(id: 2, cardType: .number(NumberCard(number: .three, color: .allCases.randomElement()!))),
                Card(id: 0, cardType: .skip(playerID: nil)),
                Card(id: 3, cardType: .number(NumberCard(number: .five, color: .allCases.randomElement()!))),
                Card(id: 4, cardType: .number(NumberCard(number: .six, color: .allCases.randomElement()!))),
                Card(id: 5, cardType: .number(NumberCard(number: .seven, color: .allCases.randomElement()!))),
            ]
        )
    }
    
    _ = try Run(
        requiredLength: 5,
        cards: [
            Card(id: 1, cardType: .wild(WildCard(color: .allCases.randomElement()!, usedAs: .number(.one)))),
            Card(id: 1, cardType: .wild(WildCard(color: .allCases.randomElement()!, usedAs: .number(.two)))),
            Card(id: 1, cardType: .wild(WildCard(color: .allCases.randomElement()!, usedAs: .number(.three)))),
            Card(id: 1, cardType: .wild(WildCard(color: .allCases.randomElement()!, usedAs: .number(.four)))),
            Card(id: 1, cardType: .wild(WildCard(color: .allCases.randomElement()!, usedAs: .number(.five)))),
        ]
    )
}

@Test func sets() async throws {
    _ = try NumberSet(
        requiredCount: 4,
        number: .eight,
        cards: [
            Card(id: 1, cardType: .number(NumberCard(number: .eight, color: .allCases.randomElement()!))),
            Card(id: 2, cardType: .number(NumberCard(number: .eight, color: .allCases.randomElement()!))),
            Card(id: 3, cardType: .number(NumberCard(number: .eight, color: .allCases.randomElement()!))),
            Card(id: 4, cardType: .number(NumberCard(number: .eight, color: .allCases.randomElement()!))),
        ]
    )
}

@Test func skipping() async throws {
    var round: Round = try .init(
        cookedDeck: .allSkips(count: 300),
        players: [
            .fake(id: "1", points: .zero, stage: .one),
            .fake(id: "2", points: .zero, stage: .one),
            .fake(id: "3", points: .zero, stage: .one),
            .fake(id: "4", points: .zero, stage: .one),
        ]
    )
    try round.pickUpCard(fromDiscardPile: false)
    try round.playerHands[0].cards[0].setPlayerToSkip(playerID: "3")
    try round.discard(round.playerHands[0].cards[0].id)
    try round.pickUpCard(fromDiscardPile: false)
    #expect(throws: Stage10Error.discardedSkipWithoutSpecifyingPlayerToSkip) {
        try round.discard(round.playerHands[1].cards[0].id)
    }
    try round.playerHands[1].cards[0].setPlayerToSkip(playerID: "3")
    try round.discard(round.playerHands[1].cards[0].id)
    #expect(round.skipQueue["3"] == 1)
    try round.pickUpCard(fromDiscardPile: false)
    #expect(throws: Stage10Error.triedToSkipYourself) {
        try round.playerHands[3].cards[0].setPlayerToSkip(playerID: "4")
        try round.discard(round.playerHands[3].cards[0].id)
    }
    try round.playerHands[3].cards[0].setPlayerToSkip(playerID: "1")
    try round.discard(round.playerHands[3].cards[0].id)
    #expect(round.skipQueue["1"] == 0)
    
    try round.pickUpCard(fromDiscardPile: false)
    try round.playerHands[1].cards[0].setPlayerToSkip(playerID: "1")
    try round.discard(round.playerHands[1].cards[0].id)
    
    try round.pickUpCard(fromDiscardPile: false)
    try round.playerHands[3].cards[0].setPlayerToSkip(playerID: "1")
    try round.discard(round.playerHands[3].cards[0].id)

    try round.pickUpCard(fromDiscardPile: false)
    try round.playerHands[1].cards[0].setPlayerToSkip(playerID: "1")
    try round.discard(round.playerHands[1].cards[0].id)
    
    try round.pickUpCard(fromDiscardPile: false)
    try round.playerHands[2].cards[0].setPlayerToSkip(playerID: "1")
    try round.discard(round.playerHands[2].cards[0].id)
    #expect(round.skipQueue == [
        "1": 3,
        "3": 0,
    ])
}

@Test func playRound() async throws {
    var round: Round = try .init(
        cookedDeck: .deck() + [
            .init(id: 2000, cardType: .number(.init(number: .three, color: .blue))),
            .init(id: 2001, cardType: .number(.init(number: .three, color: .blue))),
            .init(id: 2002, cardType: .number(.init(number: .three, color: .blue))),
            .init(id: 2003, cardType: .number(.init(number: .six, color: .blue))),
            .init(id: 2004, cardType: .number(.init(number: .six, color: .blue))),
            .init(id: 2005, cardType: .number(.init(number: .six, color: .blue))),
            .init(id: 2006, cardType: .number(.init(number: .twelve, color: .blue))),
            .init(id: 2007, cardType: .number(.init(number: .twelve, color: .blue))),
            .init(id: 2008, cardType: .number(.init(number: .twelve, color: .blue))),
            .init(id: 2009, cardType: .number(.init(number: .twelve, color: .blue))),
            // player 1
            .init(id: 1000, cardType: .number(.init(number: .three, color: .blue))),
            .init(id: 1001, cardType: .number(.init(number: .three, color: .blue))),
            .init(id: 1002, cardType: .number(.init(number: .three, color: .blue))),
            .init(id: 1003, cardType: .number(.init(number: .six, color: .blue))),
            .init(id: 1004, cardType: .number(.init(number: .six, color: .blue))),
            .init(id: 1005, cardType: .number(.init(number: .six, color: .blue))),
            .init(id: 1006, cardType: .number(.init(number: .twelve, color: .blue))),
            .init(id: 1007, cardType: .number(.init(number: .twelve, color: .blue))),
            .init(id: 1008, cardType: .number(.init(number: .twelve, color: .blue))),
            .init(id: 1009, cardType: .number(.init(number: .twelve, color: .blue))),
        ],
        players: [
            .fake(id: "1", name: "Player 1", points: .zero, stage: .one),
            .fake(id: "2", name: "Player 2", points: .zero, stage: .one),
        ]
    )
    var form: CompleteStageForm = .init(
        stage: .one,
        completionAttempts: [
            .init(
                requirement: .numberSet(count: 3),
                cardIDs: [1000, 1001, 1002]
            ),
            .init(
                requirement: .numberSet(count: 3),
                cardIDs: [1003, 1004, 1005]
            ),
        ]
    )
    try round.completeStage(form: form)
    try round.pickUpCard(fromDiscardPile: false)
    try round.discard(1006)
    form = .init(
        stage: .one,
        completionAttempts: [
            .init(
                requirement: .numberSet(count: 3),
                cardIDs: [2000, 2001, 2002]
            ),
            .init(
                requirement: .numberSet(count: 3),
                cardIDs: [2006, 2007, 2008, 2009]
            ),
        ]
    )
    try round.completeStage(form: form)
    try round.pickUpCard(fromDiscardPile: false)
    try round.addCard(
        form: .init(
            cardID: 2003,
            completedRequirementID: round.playerHands[0].completed[1].id,
            belongingToPlayerID: round.playerHands[0].player.id,
            attempt: .addToSet
        )
    )
    try round.addCard(
        form: .init(
            cardID: 2004,
            completedRequirementID: round.playerHands[0].completed[1].id,
            belongingToPlayerID: round.playerHands[0].player.id,
            attempt: .addToSet
        )
    )
    try round.addCard(
        form: .init(
            cardID: 2005,
            completedRequirementID: round.playerHands[0].completed[1].id,
            belongingToPlayerID: round.playerHands[0].player.id,
            attempt: .addToSet
        )
    )
    try round.playerHands[1].cards[0].setPlayerToSkip(playerID: round.playerHands[0].player.id)
    try round.discard(53)
    print(round.logValue)
}

@Test func playGame() async throws {
    var round: Round = try .init(
        cookedDeck: .deck().reversed(),
        players: [
            .fake(id: "1", name: "Player 1", points: .zero, stage: .one),
            .fake(id: "2", name: "Player 2", points: .zero, stage: .one),
        ]
    )
    #expect(round.playerHands.allSatisfy({ $0.player.points == .zero }))
    #expect(round.playerHands.allSatisfy({ $0.player.stage == .one }))
    #expect(round.playerHands.allSatisfy({ $0.isRequirementsComplete == false }))
    #expect(round.playerHands.allSatisfy({ $0.completed.isEmpty }))
    try round.pickUpCard(fromDiscardPile: false)
    try round.discard(round.playerHands[0].cards[0].id)
    #expect(round.playerHands[0].cards.count == 10)
    #expect(round.deck.count == 86)
    #expect(round.discardPile.count == 2)
    #expect(round.currentPlayerHand?.player.id == round.playerHands[1].player.id)
    try round.pickUpCard(fromDiscardPile: true)
    #expect(round.playerHands[1].cards.contains(where: { $0.cardType == .number(NumberCard(number: .ten, color: .red)) }))
    #expect(round.discardPile.count == 1)
    #expect(throws: Stage10Error.notWaitingForPlayerToPickUp) {
        try round.pickUpCard(fromDiscardPile: true)
    }
    try round.discard(12)
    try round.pickUpCard(fromDiscardPile: true)
    #expect(round.playerHands[0].cards.filter({ $0.cardType.numberValue == .one }).count == 2)
    try round.discard(round.playerHands[0].cards[9].id)
//    try round.pickUpCard(fromDiscardPile: true)
    print(round.logValue)
//    #expect(throws: Stage10Error.cardDoesNotExistInPlayersHand) {
//        let cards: [Card] = [
//            .number(NumberCard(number: .one, color: .red)),
//            .number(NumberCard(number: .one, color: .blue)),
//            .number(NumberCard(number: .one, color: .blue)),
//        ]
//        let numberSet: NumberSet = try .init(
//            requiredCount: 3,
//            number: .one,
//            cards: cards
//        )
//        try game.rounds[0].complete(
//            requirement: .numberSet(numberSet),
//            with: cards
//        )
//    }
//    #expect(throws: Stage10Error.cardDoesNotExistInPlayersHand) {
//        try game.rounds[0].discard(.number(NumberCard(number: .ten, color: .green)))
//    }
//    try game.rounds[0].discard(.number(NumberCard(number: .ten, color: .blue)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: true)
//    try game.rounds[0].discard(.number(NumberCard(number: .two, color: .blue)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: true)
//    try game.rounds[0].discard(.number(NumberCard(number: .eight, color: .red)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: true)
//    try game.rounds[0].discard(.number(NumberCard(number: .twelve, color: .red)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: false)
//    try game.rounds[0].discard(.number(NumberCard(number: .eleven, color: .blue)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: false)
//    try game.rounds[0].discard(.number(NumberCard(number: .eleven, color: .red)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: false)
//    var laydownCards: [Card] = [
//        .number(NumberCard(number: .one, color: .red)),
//        .number(NumberCard(number: .one, color: .blue)),
//        .number(NumberCard(number: .one, color: .green)),
//    ]
//    let numberSet: NumberSet = try .init(
//        requiredCount: 3,
//        number: .one,
//        cards: laydownCards
//    )
//    try game.rounds[0].complete(
//        requirement: .numberSet(numberSet),
//        with: laydownCards
//    )
//    try game.rounds[0].discard(.number(NumberCard(number: .nine, color: .red)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: false)
//    try game.rounds[0].discard(.number(NumberCard(number: .twelve, color: .blue)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: false)
//    try game.rounds[0].discard(.number(NumberCard(number: .seven, color: .red)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: false)
//    try game.rounds[0].discard(.number(NumberCard(number: .seven, color: .blue)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: false)
//    try game.rounds[0].discard(.number(NumberCard(number: .six, color: .red)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: false)
//    try game.rounds[0].discard(.number(NumberCard(number: .two, color: .green)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: true)
//    try game.rounds[0].discard(.number(NumberCard(number: .four, color: .red)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: true)
//    laydownCards = [
//        .number(NumberCard(number: .four, color: .red)),
//        .number(NumberCard(number: .four, color: .blue)),
//        .number(NumberCard(number: .four, color: .green)),
//    ]
//    try game.rounds[0].complete(
//        requirement: .numberSet(
//            NumberSet(
//                requiredCount: 3,
//                number: .four,
//                cards: laydownCards
//            )
//        ),
//        with: laydownCards
//    )
//    try game.rounds[0].discard(.number(NumberCard(number: .three, color: .blue)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: false)
//    laydownCards = [
//        .number(NumberCard(number: .two, color: .red)),
//        .number(NumberCard(number: .two, color: .blue)),
//        .number(NumberCard(number: .two, color: .green)),
//    ]
//    try game.rounds[0].complete(
//        requirement: .numberSet(
//            NumberSet(
//                requiredCount: 3,
//                number: .two,
//                cards: laydownCards
//            )
//        ),
//        with: laydownCards
//    )
//    try game.rounds[0].discard(.number(NumberCard(number: .three, color: .green)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: false)
//    laydownCards = [
//        .number(NumberCard(number: .eight, color: .red)),
//        .number(NumberCard(number: .eight, color: .blue)),
//        .number(NumberCard(number: .eight, color: .green)),
//    ]
//    try game.rounds[0].complete(
//        requirement: .numberSet(
//            NumberSet(
//                requiredCount: 3,
//                number: .eight,
//                cards: laydownCards
//            )
//        ),
//        with: laydownCards
//    )
//    try game.rounds[0].discard(.number(NumberCard(number: .ten, color: .red)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: false)
//    try game.rounds[0].discard(.number(NumberCard(number: .nine, color: .green)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: false)
//    try game.rounds[0].discard(.number(NumberCard(number: .ten, color: .green)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: false)
//    try game.rounds[0].discard(.number(NumberCard(number: .eleven, color: .green)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: false)
//    try game.rounds[0].discard(.number(NumberCard(number: .twelve, color: .green)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: false)
//    try game.rounds[0].add(
//        card: .number(NumberCard(number: .one, color: .yellow)),
//        to: game.rounds[0].playerHands[0].completed[0],
//        belongingToPlayerID: game.rounds[0].playerHands[0].player.id,
//        runPosition: nil
//    )
//    try game.rounds[0].discard(.number(NumberCard(number: .seven, color: .green)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: false)
//    try game.rounds[0].discard(.number(NumberCard(number: .ten, color: .blue)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: false)
//    try game.rounds[0].discard(.number(NumberCard(number: .five, color: .green)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: false)
//    try game.rounds[0].discard(.number(NumberCard(number: .six, color: .green)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: false)
//    try game.rounds[0].discard(.number(NumberCard(number: .five, color: .red)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: false)
//    try game.rounds[0].discard(.number(NumberCard(number: .six, color: .yellow)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: false)
//    try game.rounds[0].discard(.number(NumberCard(number: .five, color: .yellow)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: false)
//    try game.rounds[0].discard(.number(NumberCard(number: .five, color: .blue)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: false)
//    try game.rounds[0].discard(.number(NumberCard(number: .nine, color: .yellow)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: false)
//    try game.rounds[0].add(
//        card: .number(NumberCard(number: .two, color: .yellow)),
//        to: game.rounds[0].playerHands[0].completed[1],
//        belongingToPlayerID: game.rounds[0].playerHands[0].player.id,
//        runPosition: nil
//    )
//    try game.rounds[0].add(
//        card: .number(NumberCard(number: .four, color: .yellow)),
//        to: game.rounds[0].playerHands[1].completed[0],
//        belongingToPlayerID: game.rounds[0].playerHands[1].player.id,
//        runPosition: nil
//    )
//    try game.rounds[0].add(
//        card: .number(NumberCard(number: .eight, color: .yellow)),
//        to: game.rounds[0].playerHands[1].completed[1],
//        belongingToPlayerID: game.rounds[0].playerHands[1].player.id,
//        runPosition: nil
//    )
//    try game.rounds[0].discard(.number(NumberCard(number: .ten, color: .yellow)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: false)
//    try game.rounds[0].discard(.number(NumberCard(number: .eleven, color: .yellow)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: false)
//    try game.rounds[0].discard(.number(NumberCard(number: .twelve, color: .yellow)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: true)
//    try game.rounds[0].discard(.number(NumberCard(number: .twelve, color: .yellow)))
//    try game.rounds[0].pickUpCard(fromDiscardPile: false)
//    try game.rounds[0].add(
//        card: .number(NumberCard(number: .one, color: .red)),
//        to: game.rounds[0].playerHands[0].completed[0],
//        belongingToPlayerID: game.rounds[0].playerHands[0].player.id,
//        runPosition: nil
//    )
//    try game.rounds[0].discard(.number(NumberCard(number: .six, color: .blue)))
//    #expect(throws: Stage10Error.notWaitingForPlayerToPickUp) {
//        try game.rounds[0].pickUpCard(fromDiscardPile: false)
//    }
//    #expect(game.players[0].points == .zero)
//    #expect(game.players[0].stage == .two)
//    #expect(game.players[1].points == 15)
//    #expect(game.players[1].stage == .two)
//    print("----------------")
//    print(game.rounds[0].logValue)
//    print(game.rounds[1].logValue)
//    print(game.logValue)
}
