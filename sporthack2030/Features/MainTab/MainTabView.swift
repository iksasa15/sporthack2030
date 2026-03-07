import SwiftUI

struct MainTabView: View {
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
    }
}

private struct HomeView: View {
    var body: some View {
        NavigationStack {
            Text("صفحة الرئيسية")
                .navigationTitle("الرئيسية")
        }
    }
}

private struct WorkoutsView: View {
    var body: some View {
        NavigationStack {
            Text("صفحة التدريبات")
                .navigationTitle("التدريبات")
        }
    }
}

private struct CameraView: View {
    var body: some View {
        NavigationStack {
            Text("صفحة الكاميرا")
                .navigationTitle("الكاميرا")
        }
    }
}

private struct ReportsView: View {
    var body: some View {
        NavigationStack {
            Text("صفحة التقارير")
                .navigationTitle("التقارير")
        }
    }
}

private struct ProfileView: View {
    var body: some View {
        NavigationStack {
            Text("صفحة الملف الشخصي")
                .navigationTitle("الملف الشخصي")
        }
    }
}

#Preview {
    MainTabView()
}
