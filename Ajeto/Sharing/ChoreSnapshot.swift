import Foundation

/// Serializable payload van één klus. Bewust plat gehouden zodat het bestandje
/// forwards-compatible is: onbekende velden bij een nieuwere versie mogen
/// gewoon genegeerd worden.
struct ChoreSnapshot: Codable {
    var schemaVersion: Int = 1
    var title: String
    var details: String
    var scheduledStart: Date?
    var scheduledEnd: Date?
    var isDone: Bool
    var createdAt: Date

    var roomName: String?
    var roomIconName: String?

    var photos: [PhotoSnapshot]

    struct PhotoSnapshot: Codable {
        /// JPEG-bytes; JSONEncoder codeert dit als base64.
        var data: Data
        var addedAt: Date
    }
}

/// Verpakking rond één of meer klus-snapshots plus exportmoment. Dit is het
/// enige formaat dat we schrijven vanaf schema v2; oude v1-losse-snapshots
/// worden bij inlezen gepromoveerd naar een bundle van 1.
struct ChoresBundle: Codable {
    var schemaVersion: Int = 2
    var exportedAt: Date
    var chores: [ChoreSnapshot]
}

extension ChoreSnapshot {
    static let fileExtension = "ajeto"
    static let uti = "nl.tomderoos.Ajeto.klus"

    static var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }

    static var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}
