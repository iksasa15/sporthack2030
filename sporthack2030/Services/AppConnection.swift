import Foundation

enum AppConnection {
    static let hostKey = "backendHost"
    static let defaultHost = "127.0.0.1:5001"

    static var host: String {
        normalizedHost(UserDefaults.standard.string(forKey: hostKey) ?? defaultHost)
    }

    static var baseURLString: String {
        "http://\(host)"
    }

    static var mediaPipePoseURLString: String {
        "\(baseURLString)/api/mediapipe/pose"
    }

    static var mediaPipeFingersURLString: String {
        "\(baseURLString)/api/mediapipe/fingers"
    }

    /// URL for listing exercises. Pass nil or "all" for all sports; otherwise e.g. "football", "basketball".
    static func exercisesURL(sport: String?) -> URL? {
        var comp = URLComponents(string: "\(baseURLString)/api/exercises")
        if let s = sport, !s.trimmingCharacters(in: .whitespaces).isEmpty, s.lowercased() != "all" {
            comp?.queryItems = [URLQueryItem(name: "sport", value: s)]
        }
        return comp?.url
    }

    static func healthURLString(for rawHost: String) -> String {
        "http://\(normalizedHost(rawHost))/health"
    }

    static func normalizedHost(_ raw: String) -> String {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        value = value.replacingOccurrences(of: "http://", with: "")
        value = value.replacingOccurrences(of: "https://", with: "")
        value = value.replacingOccurrences(of: "/", with: "")
        return value.isEmpty ? defaultHost : value
    }
}
