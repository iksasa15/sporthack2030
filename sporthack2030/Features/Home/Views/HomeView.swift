import SwiftUI

struct HomeView: View {
    @AppStorage("playerName") private var playerName = "أحمد"
    @Environment(\.colorScheme) private var colorScheme

    private var resolvedPlayerName: String {
        let trimmedName = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "اللاعب" : trimmedName
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    WelcomeCard(playerName: resolvedPlayerName)
                    PerformanceSummaryCard()
                    DigitalArchiveCard()
                    FatigueAlertsCard()
                }
                .padding()
            }
            .background(AppTheme.background(for: colorScheme))
            .scrollIndicators(.hidden)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("الرئيسية")
        }
    }
}

#Preview {
    HomeView()
}
