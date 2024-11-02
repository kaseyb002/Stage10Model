import Foundation

public enum CompletedRequirement: Equatable {
    case numberSet(NumberSet)
    case colorSet(ColorSet)
    case run(Run)
    
    public var stageRequirement: StageRequirement {
        switch self {
        case .numberSet(let numberSet):
            .numberSet(count: numberSet.requiredCount)
            
        case .colorSet(let colorSet):
            .colorSet(count: colorSet.requiredCount)
            
        case .run(let run):
            .run(length: run.requiredLength)
        }
    }
}
