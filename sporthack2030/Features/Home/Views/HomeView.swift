import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    PerformanceSummaryCard()
                    DigitalArchiveCard()
                    FatigueAlertsCard()
                }
                .padding()
            }
            .background(AppTheme.background(for: colorScheme))
            .scrollIndicators(.hidden)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    MockDataChip()
                }
            }
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("الرئيسية")
        }
    }
}

#Preview {
    HomeView()
}
