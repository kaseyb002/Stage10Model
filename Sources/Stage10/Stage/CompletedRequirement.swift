import Foundation

public struct CompletedRequirement: Equatable, Codable {
    public let id: String
    public var requirementType: RequirementType
    
    public enum RequirementType: Equatable, Codable {
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
}
