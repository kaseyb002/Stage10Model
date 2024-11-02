import Foundation

extension Player {
    public static func fake(
        id: String = UUID().uuidString,
        name: String = Lorem.fullName,
        imageURL: URL? = .randomImageURL,
        points: Int = .random(in: 0 ... 150),
        stage: Stage = .allCases.randomElement()!
    ) -> Player {
        .init(
            id: id,
            name: name,
            imageURL: imageURL,
            points: points,
            stage: stage
        )
    }
}
