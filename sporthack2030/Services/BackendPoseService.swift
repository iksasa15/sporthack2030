import Foundation

/// Upload video to backend, run analysis (pose overlay from Python), poll until done, return result video URL.
enum BackendPoseService {
    struct UploadResponse: Codable {
        let path: String
        let filename: String
    }

    struct AnalyzeResponse: Codable {
        let job_id: String
        let status: String
    }

    struct ReportResponse: Codable {
        let job_id: String?
        let video_url: String?
        let pdf_url: String?
        let sport: String?
        let overall_score: Double?
    }

    /// Upload video file to backend; returns server path for analyze.
    static func uploadVideo(fileURL: URL) async throws -> UploadResponse {
        let base = AppConnection.baseURLString
        guard let url = URL(string: "\(base)/api/upload") else { throw BackendPoseError.badURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let data = try Data(contentsOf: fileURL)
        let filename = fileURL.lastPathComponent
        let body = multipartBody(boundary: boundary, fileData: data, fieldName: "file", filename: filename)
        request.httpBody = body
        request.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")

        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw BackendPoseError.uploadFailed(String(data: responseData, encoding: .utf8))
        }
        let decoded = try JSONDecoder().decode(UploadResponse.self, from: responseData)
        return decoded
    }

    /// Start analysis; returns job_id.
    static func startAnalyze(sourcePath: String, sport: String = "unknown") async throws -> String {
        let base = AppConnection.baseURLString
        guard let url = URL(string: "\(base)/api/analyze") else { throw BackendPoseError.badURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["source": sourcePath, "sport": sport]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw BackendPoseError.analyzeFailed(String(data: responseData, encoding: .utf8))
        }
        let decoded = try JSONDecoder().decode(AnalyzeResponse.self, from: responseData)
        return decoded.job_id
    }

    /// Poll status until completed or error; returns final status.
    static func pollUntilDone(jobId: String, interval: TimeInterval = 1.0, maxWait: TimeInterval = 300) async throws -> String {
        let base = AppConnection.baseURLString
        let start = Date()
        while Date().timeIntervalSince(start) < maxWait {
            guard let url = URL(string: "\(base)/api/status/\(jobId)") else { throw BackendPoseError.badURL }
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = json["status"] as? String {
                if status == "completed" || status == "error" { return status }
            }
            try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }
        throw BackendPoseError.timeout
    }

    /// Get report for completed job; returns video_url (path like /api/output/xxx.mp4).
    static func getReport(jobId: String) async throws -> ReportResponse {
        let base = AppConnection.baseURLString
        guard let url = URL(string: "\(base)/api/report/\(jobId)") else { throw BackendPoseError.badURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw BackendPoseError.reportFailed(String(data: data, encoding: .utf8))
        }
        return try JSONDecoder().decode(ReportResponse.self, from: data)
    }

    /// Full flow: upload → analyze → poll → report. Returns full URL for result video, or nil if no video.
    static func processVideoAndGetResultURL(localVideoURL: URL, sport: String = "unknown") async throws -> URL? {
        let upload = try await uploadVideo(fileURL: localVideoURL)
        let jobId = try await startAnalyze(sourcePath: upload.path, sport: sport)
        let status = try await pollUntilDone(jobId: jobId)
        if status == "error" { throw BackendPoseError.analysisError }
        let report = try await getReport(jobId: jobId)
        guard let path = report.video_url, !path.isEmpty else { return nil }
        let base = AppConnection.baseURLString
        let full = "\(base)\(path.hasPrefix("/") ? "" : "/")\(path)"
        return URL(string: full)
    }

    private static func multipartBody(boundary: String, fileData: Data, fieldName: String, filename: String) -> Data {
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: video/mp4\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }
}

// ReportResponse keys match backend: video_url, pdf_url, etc.
enum BackendPoseError: LocalizedError {
    case badURL
    case uploadFailed(String?)
    case analyzeFailed(String?)
    case reportFailed(String?)
    case timeout
    case analysisError

    var errorDescription: String? {
        switch self {
        case .badURL: return "رابط الخادم غير صالح"
        case .uploadFailed(let m): return "فشل رفع المقطع. \(m ?? "")"
        case .analyzeFailed(let m): return "فشل بدء التحليل. \(m ?? "")"
        case .reportFailed(let m): return "فشل جلب التقرير. \(m ?? "")"
        case .timeout: return "انتهت المهلة. جرّب مقطعاً أقصر."
        case .analysisError: return "فشل التحليل على الخادم."
        }
    }
}

