import Foundation

public struct CompletedRequirement: Equatable, Codable, Sendable {
    public let id: String
    public var requirementType: RequirementType
    
    public enum RequirementType: Equatable, Codable, Sendable {
        case numberSet(NumberSet)
        case colorSet(ColorSet)
        case run(Run)
    }
    
    public var stageRequirement: StageRequirement {
        switch requirementType {
        case .numberSet(let numberSet):
            .numberSet(count: numberSet.requiredCount)
            
        case .colorSet(let colorSet):
            .colorSet(count: colorSet.requiredCount)
            
        case .run(let run):
            .run(length: run.requiredLength)
        }
    }
    
    public init(
        id: String = UUID().uuidString,
        requirementType: RequirementType
    ) {
        self.id = id
        self.requirementType = requirementType
    }
    
    public init(
        id: String = UUID().uuidString,
        requirement: StageRequirement,
        cards: [Card]
    ) throws {
        self.id = id
        switch requirement {
        case .numberSet(let count):
            let numberSet: NumberSet = try .init(
                requiredCount: count,
                number: cards.first?.cardType.numberValue ?? .one,
                cards: cards
            )
            self.requirementType = .numberSet(numberSet)
            
        case .run(let length):
            let run: Run = try .init(
                requiredLength: length,
                cards: cards
            )
            self.requirementType = .run(run)
            
        case .colorSet(let count):
            let colorSet: ColorSet = try .init(
                requiredCount: count,
                color: cards.first?.cardType.color ?? .blue,
                cards: cards
            )
            self.requirementType = .colorSet(colorSet)
        }
    }
}
