import SwiftUI

struct MainTabView: View {
    @AppStorage(AppThemePalette.storageKey) private var selectedPaletteRaw = AppThemePalette.defaultPalette.rawValue
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("الرئيسية", systemImage: "house.fill")
                }

            WorkoutsView()
                .tabItem {
                    Label("التدريبات", systemImage: "figure.strengthtraining.traditional")
                }

            CameraView()
                .tabItem {
                    Label("الكاميرا", systemImage: "camera.fill")
                }

            ReportsView()
                .tabItem {
                    Label("التقارير", systemImage: "chart.bar.fill")
                }

            ProfileView()
                .tabItem {
                    Label("الملف الشخصي", systemImage: "person.fill")
                }
        }
        .tint(AppTheme.interactive(for: colorScheme))
        .background(AppTheme.background(for: colorScheme))
        .id(selectedPaletteRaw)
    }
}

private struct WorkoutsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var exercises: [Exercise] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("جاري تحميل التمارين…")
                        .font(.appFont(.regular, size: 16))
                } else if let message = errorMessage {
                    VStack(spacing: 12) {
                        Text("حدث خطأ")
                            .font(.appFont(.bold, size: 18))
                        Text(message)
                            .font(.appFont(.regular, size: 16))
                            .multilineTextAlignment(.center)
                    }
                    .foregroundColor(AppTheme.primaryText(for: colorScheme))
                } else if exercises.isEmpty {
                    Text("لا توجد تمارين لعرضها")
                        .font(.appFont(.regular, size: 18))
                        .foregroundColor(AppTheme.primaryText(for: colorScheme))
                } else {
                    List(exercises) { exercise in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(exercise.name)
                                .font(.appFont(.bold, size: 17))
                            if let target = exercise.target, !target.isEmpty {
                                Text("الهدف: \(target)")
                                    .font(.appFont(.regular, size: 14))
                            }
                            if let desc = exercise.description, !desc.isEmpty {
                                Text(desc)
                                    .font(.appFont(.regular, size: 14))
                                    .foregroundColor(AppTheme.primaryText(for: colorScheme).opacity(0.85))
                            }
                            if let sport = exercise.sport, !sport.isEmpty {
                                Text("الرياضة: \(sport)")
                                    .font(.appFont(.regular, size: 12))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("التدريبات")
            .task { await loadExercises() }
        }
    }

    private func loadExercises() async {
        isLoading = true
        errorMessage = nil
        do {
            exercises = try await ExercisesService.fetchExercises(sport: nil)
        } catch {
            errorMessage = error.localizedDescription
            exercises = []
        }
        isLoading = false
    }
}

private struct ReportsView: View {
    var body: some View {
        NavigationStack {
            Text("صفحة التقارير")
                .font(.appFont(.regular, size: 18))
                .navigationTitle("التقارير")
        }
    }
}

#Preview {
    MainTabView()
}
