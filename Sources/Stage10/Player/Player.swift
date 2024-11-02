import Foundation

public struct Player: Equatable {
    public let id: String
    public var name: String
    public var imageURL: URL?
    public var points: Int
    public var stage: Stage
    
    public init(
        id: String,
        name: String,
        imageURL: URL?,
        points: Int,
        stage: Stage
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.points = points
        self.stage = stage
    }
}
