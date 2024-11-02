import Testing
@testable import Stage10

@Test func deckSize() async throws {
    #expect([Card].deck().count == 108)
    print([Card].deck().logValue)
}

@Test func run() async throws {
    _ = try Run(
        requiredLength: 7,
        cards: [
            .number(NumberCard(number: .one, color: .allCases.randomElement()!)),
            .number(NumberCard(number: .two, color: .allCases.randomElement()!)),
            .number(NumberCard(number: .three, color: .allCases.randomElement()!)),
            .number(NumberCard(number: .four, color: .allCases.randomElement()!)),
            .number(NumberCard(number: .five, color: .allCases.randomElement()!)),
            .number(NumberCard(number: .six, color: .allCases.randomElement()!)),
            .number(NumberCard(number: .seven, color: .allCases.randomElement()!)),
        ]
    )
    
    #expect(throws: FailedObjectiveError.insufficientCards) {
        _ = try Run(
            requiredLength: 8,
            cards: [
                .number(NumberCard(number: .one, color: .allCases.randomElement()!)),
                .number(NumberCard(number: .two, color: .allCases.randomElement()!)),
                .number(NumberCard(number: .three, color: .allCases.randomElement()!)),
                .number(NumberCard(number: .four, color: .allCases.randomElement()!)),
                .number(NumberCard(number: .five, color: .allCases.randomElement()!)),
                .number(NumberCard(number: .six, color: .allCases.randomElement()!)),
                .number(NumberCard(number: .seven, color: .allCases.randomElement()!)),
            ]
        )
    }
    
    #expect(throws: FailedObjectiveError.cardsDoNotMakeRun) {
        _ = try Run(
            requiredLength: 5,
            cards: [
                .number(NumberCard(number: .two, color: .allCases.randomElement()!)),
                .number(NumberCard(number: .two, color: .allCases.randomElement()!)),
                .number(NumberCard(number: .three, color: .allCases.randomElement()!)),
                .number(NumberCard(number: .four, color: .allCases.randomElement()!)),
                .number(NumberCard(number: .five, color: .allCases.randomElement()!)),
                .number(NumberCard(number: .six, color: .allCases.randomElement()!)),
                .number(NumberCard(number: .seven, color: .allCases.randomElement()!)),
            ]
        )
    }
    
    _ = try Run(
        requiredLength: 7,
        cards: [
            .wild(WildCard(color: .allCases.randomElement()!, usedAs: .number(.one))),
            .number(NumberCard(number: .two, color: .allCases.randomElement()!)),
            .number(NumberCard(number: .three, color: .allCases.randomElement()!)),
            .number(NumberCard(number: .four, color: .allCases.randomElement()!)),
            .number(NumberCard(number: .five, color: .allCases.randomElement()!)),
            .number(NumberCard(number: .six, color: .allCases.randomElement()!)),
            .number(NumberCard(number: .seven, color: .allCases.randomElement()!)),
        ]
    )
    
    #expect(throws: FailedObjectiveError.invalidCard) {
        _ = try Run(
            requiredLength: 5,
            cards: [
                .wild(WildCard(color: .allCases.randomElement()!, usedAs: nil)),
                .number(NumberCard(number: .two, color: .allCases.randomElement()!)),
                .number(NumberCard(number: .three, color: .allCases.randomElement()!)),
                .number(NumberCard(number: .four, color: .allCases.randomElement()!)),
                .number(NumberCard(number: .five, color: .allCases.randomElement()!)),
                .number(NumberCard(number: .six, color: .allCases.randomElement()!)),
                .number(NumberCard(number: .seven, color: .allCases.randomElement()!)),
            ]
        )
    }
    
    #expect(throws: FailedObjectiveError.invalidCard) {
        _ = try Run(
            requiredLength: 5,
            cards: [
                .number(NumberCard(number: .two, color: .allCases.randomElement()!)),
                .number(NumberCard(number: .three, color: .allCases.randomElement()!)),
                .skip,
                .number(NumberCard(number: .five, color: .allCases.randomElement()!)),
                .number(NumberCard(number: .six, color: .allCases.randomElement()!)),
                .number(NumberCard(number: .seven, color: .allCases.randomElement()!)),
            ]
        )
    }
    
    _ = try Run(
        requiredLength: 5,
        cards: [
            .wild(WildCard(color: .allCases.randomElement()!, usedAs: .number(.one))),
            .wild(WildCard(color: .allCases.randomElement()!, usedAs: .number(.two))),
            .wild(WildCard(color: .allCases.randomElement()!, usedAs: .number(.three))),
            .wild(WildCard(color: .allCases.randomElement()!, usedAs: .number(.four))),
            .wild(WildCard(color: .allCases.randomElement()!, usedAs: .number(.five))),
        ]
    )
}

@Test func sets() async throws {
    _ = try NumberSet(
        requiredCount: 4,
        number: .eight,
        cards: [
            .number(NumberCard(number: .eight, color: .allCases.randomElement()!)),
            .number(NumberCard(number: .eight, color: .allCases.randomElement()!)),
            .number(NumberCard(number: .eight, color: .allCases.randomElement()!)),
        ]
    )
}

@Test func playGame() async throws {
    var game: Game = try .init(
        players: [
            .fake(),
            .fake(),
        ],
        cookedDeck: .deck().reversed()
    )
    #expect(game.players.allSatisfy({ $0.points == .zero }))
    #expect(game.players.allSatisfy({ $0.stage == .one }))
    #expect(game.rounds[0].playerHands.allSatisfy({ $0.player.points == .zero }))
    #expect(game.rounds[0].playerHands.allSatisfy({ $0.isRequirementsComplete == false }))
    #expect(game.rounds[0].playerHands.allSatisfy({ $0.completed.isEmpty }))
    try game.rounds[0].pickUpCard(fromDiscardPile: false)
    try game.rounds[0].discard(game.rounds[0].playerHands[0].cards[0])
    #expect(game.rounds[0].playerHands[0].cards.count == 10)
    #expect(game.rounds[0].deck.count == 86)
    #expect(game.rounds[0].discardPile.count == 2)
    #expect(game.rounds[0].currentPlayerHand?.player.id == game.players[1].id)
    try game.rounds[0].pickUpCard(fromDiscardPile: true)
    #expect(game.rounds[0].playerHands[1].cards.contains(.number(NumberCard(number: .ten, color: .red))))
    #expect(game.rounds[0].discardPile.count == 1)
    #expect(throws: Stage10Error.notWaitingForPlayerToPickUp) {
        try game.rounds[0].pickUpCard(fromDiscardPile: true)
    }
    try game.rounds[0].discard(.number(NumberCard(number: .one, color: .blue)))
    try game.rounds[0].pickUpCard(fromDiscardPile: true)
    #expect(game.rounds[0].playerHands[0].cards.filter({ $0.numberValue == .one }).count == 2)
    #expect(throws: Stage10Error.cardDoesNotExistInPlayersHand) {
        let cards: [Card] = [
            .number(NumberCard(number: .one, color: .red)),
            .number(NumberCard(number: .one, color: .blue)),
            .number(NumberCard(number: .one, color: .blue)),
        ]
        let numberSet: NumberSet = try .init(
            requiredCount: 3,
            number: .one,
            cards: cards
        )
        try game.rounds[0].complete(
            requirement: .numberSet(numberSet),
            with: cards
        )
    }
    #expect(throws: Stage10Error.cardDoesNotExistInPlayersHand) {
        try game.rounds[0].discard(.number(NumberCard(number: .ten, color: .green)))
    }
    try game.rounds[0].discard(.number(NumberCard(number: .ten, color: .blue)))
    try game.rounds[0].pickUpCard(fromDiscardPile: true)
    try game.rounds[0].discard(.number(NumberCard(number: .two, color: .blue)))
    try game.rounds[0].pickUpCard(fromDiscardPile: true)
    try game.rounds[0].discard(.number(NumberCard(number: .eight, color: .red)))
    try game.rounds[0].pickUpCard(fromDiscardPile: true)
    try game.rounds[0].discard(.number(NumberCard(number: .twelve, color: .red)))
    try game.rounds[0].pickUpCard(fromDiscardPile: false)
    try game.rounds[0].discard(.number(NumberCard(number: .eleven, color: .blue)))
    try game.rounds[0].pickUpCard(fromDiscardPile: false)
    try game.rounds[0].discard(.number(NumberCard(number: .eleven, color: .red)))
    try game.rounds[0].pickUpCard(fromDiscardPile: false)
    var laydownCards: [Card] = [
        .number(NumberCard(number: .one, color: .red)),
        .number(NumberCard(number: .one, color: .blue)),
        .number(NumberCard(number: .one, color: .green)),
    ]
    let numberSet: NumberSet = try .init(
        requiredCount: 3,
        number: .one,
        cards: laydownCards
    )
    try game.rounds[0].complete(
        requirement: .numberSet(numberSet),
        with: laydownCards
    )
    try game.rounds[0].discard(.number(NumberCard(number: .nine, color: .red)))
    try game.rounds[0].pickUpCard(fromDiscardPile: false)
    try game.rounds[0].discard(.number(NumberCard(number: .twelve, color: .blue)))
    try game.rounds[0].pickUpCard(fromDiscardPile: false)
    try game.rounds[0].discard(.number(NumberCard(number: .seven, color: .red)))
    try game.rounds[0].pickUpCard(fromDiscardPile: false)
    try game.rounds[0].discard(.number(NumberCard(number: .seven, color: .blue)))
    try game.rounds[0].pickUpCard(fromDiscardPile: false)
    try game.rounds[0].discard(.number(NumberCard(number: .six, color: .red)))
    try game.rounds[0].pickUpCard(fromDiscardPile: false)
    try game.rounds[0].discard(.number(NumberCard(number: .two, color: .green)))
    try game.rounds[0].pickUpCard(fromDiscardPile: true)
    try game.rounds[0].discard(.number(NumberCard(number: .four, color: .red)))
    try game.rounds[0].pickUpCard(fromDiscardPile: true)
    laydownCards = [
        .number(NumberCard(number: .four, color: .red)),
        .number(NumberCard(number: .four, color: .blue)),
        .number(NumberCard(number: .four, color: .green)),
    ]
    try game.rounds[0].complete(
        requirement: .numberSet(
            NumberSet(
                requiredCount: 3,
                number: .four,
                cards: laydownCards
            )
        ),
        with: laydownCards
    )
    try game.rounds[0].discard(.number(NumberCard(number: .three, color: .blue)))
    try game.rounds[0].pickUpCard(fromDiscardPile: false)
    laydownCards = [
        .number(NumberCard(number: .two, color: .red)),
        .number(NumberCard(number: .two, color: .blue)),
        .number(NumberCard(number: .two, color: .green)),
    ]
    try game.rounds[0].complete(
        requirement: .numberSet(
            NumberSet(
                requiredCount: 3,
                number: .two,
                cards: laydownCards
            )
        ),
        with: laydownCards
    )
    try game.rounds[0].discard(.number(NumberCard(number: .three, color: .green)))
    try game.rounds[0].pickUpCard(fromDiscardPile: false)
    laydownCards = [
        .number(NumberCard(number: .eight, color: .red)),
        .number(NumberCard(number: .eight, color: .blue)),
        .number(NumberCard(number: .eight, color: .green)),
    ]
    try game.rounds[0].complete(
        requirement: .numberSet(
            NumberSet(
                requiredCount: 3,
                number: .eight,
                cards: laydownCards
            )
        ),
        with: laydownCards
    )
    try game.rounds[0].discard(.number(NumberCard(number: .ten, color: .red)))
    try game.rounds[0].pickUpCard(fromDiscardPile: false)
    try game.rounds[0].discard(.number(NumberCard(number: .nine, color: .green)))
    try game.rounds[0].pickUpCard(fromDiscardPile: false)
    try game.rounds[0].discard(.number(NumberCard(number: .ten, color: .green)))
    try game.rounds[0].pickUpCard(fromDiscardPile: false)
    try game.rounds[0].discard(.number(NumberCard(number: .eleven, color: .green)))
    try game.rounds[0].pickUpCard(fromDiscardPile: false)
    try game.rounds[0].discard(.number(NumberCard(number: .twelve, color: .green)))
    try game.rounds[0].pickUpCard(fromDiscardPile: false)
    try game.rounds[0].add(
        card: .number(NumberCard(number: .one, color: .yellow)),
        to: game.rounds[0].playerHands[0].completed[0],
        belongingToPlayerID: game.rounds[0].playerHands[0].player.id,
        runPosition: nil
    )
    try game.rounds[0].discard(.number(NumberCard(number: .seven, color: .green)))
    try game.rounds[0].pickUpCard(fromDiscardPile: false)
    try game.rounds[0].discard(.number(NumberCard(number: .ten, color: .blue)))
    try game.rounds[0].pickUpCard(fromDiscardPile: false)
    try game.rounds[0].discard(.number(NumberCard(number: .five, color: .green)))
    try game.rounds[0].pickUpCard(fromDiscardPile: false)
    try game.rounds[0].discard(.number(NumberCard(number: .six, color: .green)))
    try game.rounds[0].pickUpCard(fromDiscardPile: false)
    try game.rounds[0].discard(.number(NumberCard(number: .five, color: .red)))
    try game.rounds[0].pickUpCard(fromDiscardPile: false)
    try game.rounds[0].discard(.number(NumberCard(number: .six, color: .yellow)))
    try game.rounds[0].pickUpCard(fromDiscardPile: false)
    try game.rounds[0].discard(.number(NumberCard(number: .five, color: .yellow)))
    try game.rounds[0].pickUpCard(fromDiscardPile: false)
    try game.rounds[0].discard(.number(NumberCard(number: .five, color: .blue)))
    try game.rounds[0].pickUpCard(fromDiscardPile: false)
    try game.rounds[0].discard(.number(NumberCard(number: .nine, color: .yellow)))
    try game.rounds[0].pickUpCard(fromDiscardPile: false)
    try game.rounds[0].add(
        card: .number(NumberCard(number: .two, color: .yellow)),
        to: game.rounds[0].playerHands[0].completed[1],
        belongingToPlayerID: game.rounds[0].playerHands[0].player.id,
        runPosition: nil
    )
    try game.rounds[0].add(
        card: .number(NumberCard(number: .four, color: .yellow)),
        to: game.rounds[0].playerHands[1].completed[0],
        belongingToPlayerID: game.rounds[0].playerHands[1].player.id,
        runPosition: nil
    )
    try game.rounds[0].add(
        card: .number(NumberCard(number: .eight, color: .yellow)),
        to: game.rounds[0].playerHands[1].completed[1],
        belongingToPlayerID: game.rounds[0].playerHands[1].player.id,
        runPosition: nil
    )
    try game.rounds[0].discard(.number(NumberCard(number: .ten, color: .yellow)))
    try game.rounds[0].pickUpCard(fromDiscardPile: false)
    try game.rounds[0].discard(.number(NumberCard(number: .eleven, color: .yellow)))
    try game.rounds[0].pickUpCard(fromDiscardPile: false)
    try game.rounds[0].discard(.number(NumberCard(number: .twelve, color: .yellow)))
    try game.rounds[0].pickUpCard(fromDiscardPile: true)
    try game.rounds[0].discard(.number(NumberCard(number: .twelve, color: .yellow)))
    try game.rounds[0].pickUpCard(fromDiscardPile: false)
    try game.rounds[0].add(
        card: .number(NumberCard(number: .one, color: .red)),
        to: game.rounds[0].playerHands[0].completed[0],
        belongingToPlayerID: game.rounds[0].playerHands[0].player.id,
        runPosition: nil
    )
    try game.rounds[0].discard(.number(NumberCard(number: .six, color: .blue)))
    #expect(throws: Stage10Error.notWaitingForPlayerToPickUp) {
        try game.rounds[0].pickUpCard(fromDiscardPile: false)
    }
    #expect(game.players[0].points == .zero)
    #expect(game.players[0].stage == .two)
    #expect(game.players[1].points == 15)
    #expect(game.players[1].stage == .two)
    print("----------------")
    print(game.rounds[0].logValue)
    print(game.rounds[1].logValue)
    print(game.logValue)
}
