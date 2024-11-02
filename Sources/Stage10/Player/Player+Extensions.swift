import Foundation

extension Player {
    public var logValue: String {
        """
        ID: \(id)
        Name: \(name)
        Points: \(points)
        Stage: \(stage)
        """
    }
}

extension [Player] {
    public var logValue: String {
        var text = ""
        for player in self {
            text += player.logValue
            text += "\n\n"
        }
        return text
    }
}
