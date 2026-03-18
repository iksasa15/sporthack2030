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

// MARK: - Arabic display
extension Exercise {
    /// Arabic name for common exercises (backend sends English).
    var nameAr: String {
        let map: [String: String] = [
            "Clam shells": "صدفة المحار",
            "Squat jump": "قفزة القرفصاء",
            "Plank": "البلانك",
            "Single-leg balance": "التوازن على قدم واحدة",
            "Single-leg stance": "الوقوف على قدم واحدة",
            "Wall sit": "الجلوس على الحائط",
            "Hip flexor stretch": "تمدد ثني الورك",
            "Hip bridge": "جسر الورك",
            "Glute bridge": "جسر الألوية",
            "Glute bridges": "جسور الألوية",
            "Band pull-apart": "سحب الشريط",
            "Push-ups": "الضغط",
            "Torso twist": "لف الجذع",
            "Seated torso twist": "لف الجذع جالساً",
            "Rotator cuff exercises": "تمارين الكفة المدورة",
            "Rotator cuff": "الكفة المدورة",
            "Core rotation": "دوران الجذع",
            "Hip rotation drill": "تدريب دوران الورك",
            "Downward dog": "وضعية الكلب النازل",
            "Tree pose": "وضعية الشجرة",
            "Cat-cow": "القط-البقرة",
            "Hollow hold": "التمسك الجوفاء",
            "Shoulder mobility": "مرونة الكتف",
            "Calf raises": "رفع ربلة الساق",
            "Squats": "القرفصاء",
            "Single-leg landing": "الهبوط على قدم واحدة",
        ]
        return map[name] ?? name
    }

    /// Arabic for target (body part).
    var targetAr: String {
        let map: [String: String] = [
            "hip": "الورك",
            "knee": "الركبة",
            "core": "الجذع",
            "ankle": "الكاحل",
            "shoulder": "الكتف",
            "balance": "التوازن",
            "spine": "العمود الفقري",
            "leg": "الساق",
        ]
        guard let t = target, !t.isEmpty else { return "" }
        return map[t.lowercased()] ?? t
    }

    /// Arabic for sport.
    var sportAr: String {
        let map: [String: String] = [
            "football": "كرة القدم",
            "basketball": "كرة السلة",
            "generic": "عام",
            "tennis": "التنس",
            "running": "الجري",
            "yoga": "اليوغا",
            "boxing": "الملاكمة",
            "weightlifting": "رفع الأثقال",
            "volleyball": "الكرة الطائرة",
            "golf": "الجولف",
            "baseball": "كرة القاعدة",
            "gymnastics": "الجمباز",
            "martial_arts": "الفنون القتالية",
        ]
        guard let s = sport, !s.isEmpty else { return "" }
        return map[s.lowercased()] ?? s
    }

    var descriptionAr: String? {
        description
    }

    /// تمارين ثابتة لعرض الصفحة أثناء تصميم الواجهة أو عند تعطّل السيرفر.
    static let designPlaceholders: [Exercise] = [
        Exercise(
            name: "Clam shells",
            description: "تقوية عضلات الألوية والورك الجانبية.",
            target: "hip",
            sport: "football",
            repsSets: "3×12",
            difficulty: "متوسط"
        ),
        Exercise(
            name: "Squat jump",
            description: "انفجارية وقوة الساقين.",
            target: "leg",
            sport: "basketball",
            repsSets: "3×8",
            difficulty: "صعب"
        ),
        Exercise(
            name: "Plank",
            description: "ثبات الجذع والكتفين.",
            target: "core",
            sport: "generic",
            repsSets: "3×45 ث",
            difficulty: "سهل"
        ),
        Exercise(
            name: "Single-leg balance",
            description: "تحسين الثبات والكاحل.",
            target: "balance",
            sport: "football",
            repsSets: "3×30 ث",
            difficulty: "متوسط"
        ),
        Exercise(
            name: "Hip flexor stretch",
            description: "مرونة مقدمة الورك.",
            target: "hip",
            sport: "running",
            repsSets: "2×30 ث",
            difficulty: "سهل"
        ),
        Exercise(
            name: "Band pull-apart",
            description: "تقوية الكتف الخلفي.",
            target: "shoulder",
            sport: "tennis",
            repsSets: "3×15",
            difficulty: "سهل"
        ),
    ]
}
