import Foundation

public struct Player: Equatable, Codable, Sendable {
    public let id: String
    public var name: String
    public var imageURL: URL?
    public var points: Int
    public var stage: Stage
    
    public enum CodingKeys: String, CodingKey {
        case id
        case name
        case imageURL = "imageUrl"
        case points
        case stage
    }
    
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
