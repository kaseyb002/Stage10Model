import Foundation

extension [StageRequirement] {
    public static let stage1: [StageRequirement] = [
        .numberSet(count: 3),
        .numberSet(count: 3),
    ]
    
    public static let stage2: [StageRequirement] = [
        .numberSet(count: 3),
        .run(length: 4),
    ]
    
    public static let stage3: [StageRequirement] = [
        .numberSet(count: 4),
        .run(length: 4),
    ]
    
    public static let stage4: [StageRequirement] = [
        .run(length: 7),
    ]
    
    public static let stage5: [StageRequirement] = [
        .run(length: 8),
    ]
    
    public static let stage6: [StageRequirement] = [
        .run(length: 9),
    ]
    
    public static let stage7: [StageRequirement] = [
        .numberSet(count: 4),
        .numberSet(count: 4),
    ]
    
    public static let stage8: [StageRequirement] = [
        .colorSet(count: 7),
    ]
    
    public static let stage9: [StageRequirement] = [
        .numberSet(count: 5),
        .numberSet(count: 2),
    ]
    
    public static let stage10: [StageRequirement] = [
        .numberSet(count: 5),
        .numberSet(count: 3),
    ]
    
    public static let allStages: [[StageRequirement]] = [
        .stage1,
        .stage2,
        .stage3,
        .stage4,
        .stage5,
        .stage6,
        .stage7,
        .stage8,
        .stage9,
        .stage10,
    ]
}
