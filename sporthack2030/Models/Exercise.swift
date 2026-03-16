import Foundation

/// Single exercise from the backend (unified shape from /api/exercises).
struct Exercise: Codable, Identifiable {
    var name: String
    var description: String?
    var target: String?
    var sport: String?
    var repsSets: String?
    var difficulty: String?

    var id: String { "\(sport ?? "generic")-\(name)" }

    enum CodingKeys: String, CodingKey {
        case name, description, target, sport, difficulty
        case repsSets = "reps_sets"
    }
}

/// Response from GET /api/exercises.
struct ExercisesResponse: Codable {
    var exercises: [Exercise]
}
