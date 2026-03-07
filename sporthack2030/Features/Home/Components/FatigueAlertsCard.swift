import SwiftUI

struct FatigueAlertsCard: View {
    var body: some View {
        CardContainer(
            title: "بطاقة تنبيهات الإجهاد والوقاية (نموذج محاكاة)",
            goal: "عرض شكل التحذيرات الفورية في حال رصد مؤشرات تعب أو حركات خاطئة."
        ) {
            HStack {
                Text("حالة الجهد")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                StressStatusIndicator(status: "أصفر")
            }

            Divider()
            InfoRow(title: "تنبيه الإصابة", value: "تم رصد حركة خاطئة في الركبة")
            InfoRow(
                title: "نصيحة التصحيح",
                value: "خفف الاندفاع واثبت القدم الداعمة قبل تغيير الاتجاه"
            )
        }
    }
}

#Preview {
    FatigueAlertsCard()
        .padding()
}
