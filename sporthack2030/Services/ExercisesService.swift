import Foundation

enum ExercisesService {
    /// Fetch exercises from backend. Pass nil or "all" for all sports; otherwise e.g. "football", "basketball".
    static func fetchExercises(sport: String? = nil) async throws -> [Exercise] {
        guard let url = AppConnection.exercisesURL(sport: sport) else {
            throw ExercisesError.invalidURL
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw ExercisesError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw ExercisesError.serverError(statusCode: http.statusCode)
        }
        let decoded = try JSONDecoder().decode(ExercisesResponse.self, from: data)
        return decoded.exercises
    }
}

enum ExercisesError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "رابط التمارين غير صالح"
        case .invalidResponse: return "استجابة غير صالحة من الخادم"
        case .serverError(let code): return "خطأ من الخادم (\(code))"
        }
    }
}
