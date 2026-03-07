import SwiftUI

struct DigitalArchiveCard: View {
    var body: some View {
        CardContainer(
            title: "بطاقة الأرشيف الرقمي (سجل تجريبي)",
            goal: "توضيح كيفية الوصول للسجل التاريخي لتطور المهارات عبر الزمن."
        ) {
            InfoRow(title: "مخطط النمو", value: "منحنى نمو افتراضي خلال آخر 6 أشهر")
            InfoRow(title: "القيمة السوقية", value: "50,000 ريال")
            InfoRow(title: "ملخص النشاط", value: "96 ساعة تدريب - 42 تمرين مكتمل")
        }
    }
}

#Preview {
    DigitalArchiveCard()
        .padding()
}
