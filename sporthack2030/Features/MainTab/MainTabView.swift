import SwiftUI

struct MainTabView: View {
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
    }
}

private struct WorkoutsView: View {
    var body: some View {
        NavigationStack {
            Text("صفحة التدريبات")
                .font(.appFont(.regular, size: 18))
                .navigationTitle("التدريبات")
        }
    }
}

private struct CameraView: View {
    var body: some View {
        NavigationStack {
            Text("صفحة الكاميرا")
                .font(.appFont(.regular, size: 18))
                .navigationTitle("الكاميرا")
        }
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

private struct ProfileView: View {
    var body: some View {
        NavigationStack {
            Text("صفحة الملف الشخصي")
                .font(.appFont(.regular, size: 18))
                .navigationTitle("الملف الشخصي")
        }
    }
}

#Preview {
    MainTabView()
}
