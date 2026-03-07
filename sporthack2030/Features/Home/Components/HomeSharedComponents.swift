import SwiftUI

struct MockDataChip: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text("بيانات تجريبية")
            .font(.appFont(.bold, size: 12))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppTheme.interactive(for: colorScheme).opacity(0.15))
            .foregroundStyle(AppTheme.interactive(for: colorScheme))
            .clipShape(Capsule())
    }
}

struct CardContainer<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let goal: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.appFont(.bold, size: 18))
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))

            Text(goal)
                .font(.appFont(.regular, size: 13))
                .foregroundStyle(AppTheme.primaryText(for: colorScheme).opacity(0.7))

            Divider()
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.cardBorder(for: colorScheme), lineWidth: 1)
        )
    }
}

struct InfoRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.appFont(.regular, size: 14))
                .foregroundStyle(AppTheme.primaryText(for: colorScheme).opacity(0.7))
            Text(value)
                .font(.appFont(.bold, size: 16))
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
        }
    }
}

struct StressStatusIndicator: View {
    @Environment(\.colorScheme) private var colorScheme

    let status: String

    private var statusColor: Color {
        switch status {
        case "أخضر":
            return .green
        case "أحمر":
            return AppTheme.preventionAlert(for: colorScheme)
        default:
            return .yellow
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
            Text(status)
                .font(.appFont(.bold, size: 14))
                .foregroundStyle(statusColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(statusColor.opacity(0.15))
        .clipShape(Capsule())
    }
}
