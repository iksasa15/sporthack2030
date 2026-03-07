import SwiftUI

struct WelcomeCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let playerName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("مرحباً، \(playerName)")
                .font(.appFont(.medium, size: 20))
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))

            Text("جاهز نبدأ تمرين اليوم؟")
                .font(.appFont(.regular, size: 14))
                .foregroundStyle(AppTheme.primaryText(for: colorScheme).opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.card(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppTheme.cardBorder(for: colorScheme), lineWidth: 1)
        )
    }
}

#Preview {
    WelcomeCard(playerName: "أحمد")
        .padding()
}
