import Foundation

enum AppConnection {
    static let hostKey = "backendHost"
    /// فعّله عند استخدام ngrok أو Cloudflare Tunnel (HTTPS).
    static let useHTTPSKey = "backendUseHTTPS"
    static let defaultHost = "127.0.0.1:5001"

    static var useHTTPS: Bool {
        UserDefaults.standard.bool(forKey: useHTTPSKey)
    }
    /// اسم التمرين المعروض أعلى الكاميرا (يُعيَّن من التدريبات عند اختيار «تصوير الآن»).
    static let cameraExerciseNameKey = "cameraExerciseName"

    static var host: String {
        normalizedHost(UserDefaults.standard.string(forKey: hostKey) ?? defaultHost)
    }

    /// ngrok وغيرها تتطلب HTTPS؛ iOS يمنع http لهذه النطاقات (خطأ ATS).
    private static func schemeForHost(_ normalizedHost: String) -> String {
        let h = normalizedHost.lowercased()
        let needsTLS = useHTTPS
            || h.contains("ngrok")
            || h.contains("trycloudflare")
            || h.contains("loca.lt")
        return needsTLS ? "https" : "http"
    }

    static var baseURLString: String {
        "\(schemeForHost(host))://\(host)"
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
        let nh = normalizedHost(rawHost)
        return "\(schemeForHost(nh))://\(nh)/health"
    }

    static func normalizedHost(_ raw: String) -> String {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        value = value.replacingOccurrences(of: "http://", with: "")
        value = value.replacingOccurrences(of: "https://", with: "")
        value = value.replacingOccurrences(of: "/", with: "")
        return value.isEmpty ? defaultHost : value
    }
}
