//import Foundation
//
//public struct Game: Equatable, Codable {
//    public let id: String
//    public let started: Date
//    public internal(set) var state: State = .notStarted
//    public internal(set) var ended: Date?
//
//    public enum State: Equatable, Codable {
//        case notStarted
//        case playing
//        case complete(winner: Player)
//        
//        public var logValue: String {
//            switch self {
//            case .notStarted:
//                "Not started"
//                
//            case .playing:
//                "Playing"
//                
//            case .complete(let winner):
//                "\(winner.name) won."
//            }
//        }
//    }
//    
//    public init() throws {
//        self.id = UUID().uuidString
//        self.started = .now
//    }
//}
