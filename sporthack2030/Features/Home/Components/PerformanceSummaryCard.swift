import SwiftUI

struct PerformanceSummaryCard: View {
    var body: some View {
        CardContainer(
            title: "بطاقة ملخص الأداء (بيانات افتراضية)",
            goal: "محاكاة عرض مستوى اللاعب الحالي بناءً على آخر التمارين."
        ) {
            InfoRow(title: "مؤشر الأداء", value: "85% (دقة المراوغات وسرعة اللاعب)")
            InfoRow(title: "مستوى المهارة", value: "مستوى متقدم")
            InfoRow(title: "التقييم العام", value: "★★★★☆")
        }
    }
}

#Preview {
    PerformanceSummaryCard()
        .padding()
}
