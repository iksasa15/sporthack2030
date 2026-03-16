import SwiftUI
import PhotosUI

private struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct MainTabView: View {
    @AppStorage(AppThemePalette.storageKey) private var selectedPaletteRaw = AppThemePalette.defaultPalette.rawValue
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("الرئيسية", systemImage: "house.fill") }
                .tag(0)

            WorkoutsView(selectedTab: $selectedTab)
                .tabItem { Label("التدريبات", systemImage: "figure.strengthtraining.traditional") }
                .tag(1)

            CameraView()
                .tabItem { Label("الكاميرا", systemImage: "camera.fill") }
                .tag(2)

            ReportsView()
                .tabItem { Label("التقارير", systemImage: "chart.bar.fill") }
                .tag(3)

            ProfileView()
                .tabItem { Label("الملف الشخصي", systemImage: "person.fill") }
                .tag(4)
        }
        .tint(AppTheme.interactive(for: colorScheme))
        .background(AppTheme.background(for: colorScheme))
        .id(selectedPaletteRaw)
    }
}

private struct WorkoutsView: View {
    @Binding var selectedTab: Int
    @Environment(\.colorScheme) private var colorScheme
    @State private var exercises: [Exercise] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedExercise: Exercise?
    @State private var showExerciseAction = false
    @State private var showVideoPicker = false
    @State private var pickedVideoItem: PhotosPickerItem?
    @State private var videoPickedMessage: String?
    @State private var selectedVideoForPose: IdentifiableURL?

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
                        Button {
                            selectedExercise = exercise
                            showExerciseAction = true
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(exercise.nameAr)
                                    .font(.appFont(.bold, size: 17))
                                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                                if !exercise.targetAr.isEmpty {
                                    Text("الهدف: \(exercise.targetAr)")
                                        .font(.appFont(.regular, size: 14))
                                        .foregroundStyle(AppTheme.primaryText(for: colorScheme).opacity(0.9))
                                }
                                if let desc = exercise.descriptionAr ?? exercise.description, !desc.isEmpty {
                                    Text(desc)
                                        .font(.appFont(.regular, size: 14))
                                        .foregroundStyle(AppTheme.primaryText(for: colorScheme).opacity(0.85))
                                }
                                if !exercise.sportAr.isEmpty {
                                    Text("الرياضة: \(exercise.sportAr)")
                                        .font(.appFont(.regular, size: 12))
                                        .foregroundStyle(AppTheme.primaryText(for: colorScheme).opacity(0.7))
                                }
                            }
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("التدريبات")
            .task { await loadExercises() }
            .sheet(isPresented: $showExerciseAction) {
                if let exercise = selectedExercise {
                    exerciseActionSheet(exercise: exercise)
                }
            }
            .sheet(isPresented: $showVideoPicker) {
                videoPickerSheet
            }
            .alert("تم اختيار المقطع", isPresented: Binding(
                get: { videoPickedMessage != nil },
                set: { if !$0 { videoPickedMessage = nil } }
            )) {
                Button("حسناً") { videoPickedMessage = nil }
            } message: {
                if let msg = videoPickedMessage { Text(msg) }
            }
            .onChange(of: pickedVideoItem) { _, newItem in
                guard let item = newItem else { return }
                showVideoPicker = false
                Task {
                    if let video = try? await item.loadTransferable(type: VideoFile.self) {
                        await MainActor.run {
                            selectedVideoForPose = IdentifiableURL(url: video.url)
                        }
                    } else {
                        await MainActor.run {
                            videoPickedMessage = "تعذر تحميل المقطع."
                        }
                    }
                }
            }
            .fullScreenCover(item: $selectedVideoForPose) { item in
                VideoBodyPoseView(videoURL: item.url)
            }
        }
    }

    @ViewBuilder
    private func exerciseActionSheet(exercise: Exercise) -> some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(exercise.nameAr)
                    .font(.appFont(.bold, size: 20))
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                    .padding(.top, 8)

                VStack(spacing: 12) {
                    Button {
                        UserDefaults.standard.set(exercise.nameAr, forKey: AppConnection.cameraExerciseNameKey)
                        showExerciseAction = false
                        selectedTab = 2
                    } label: {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("تصوير الآن")
                                .font(.appFont(.medium, size: 16))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(.white)
                        .background(AppTheme.interactive(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Button {
                        showExerciseAction = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showVideoPicker = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "video.fill")
                            Text("رفع مقطع")
                                .font(.appFont(.medium, size: 16))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                        .background(AppTheme.card(for: colorScheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.cardBorder(for: colorScheme), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .background(AppTheme.background(for: colorScheme))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") {
                        showExerciseAction = false
                    }
                    .foregroundStyle(AppTheme.interactive(for: colorScheme))
                }
            }
        }
    }

    private var videoPickerSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("اختر مقطع فيديو من المعرض")
                    .font(.appFont(.regular, size: 16))
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .padding()

                PhotosPicker(
                    selection: $pickedVideoItem,
                    matching: .videos
                ) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("اختر فيديو")
                            .font(.appFont(.medium, size: 16))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(.white)
                    .background(AppTheme.interactive(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .background(AppTheme.background(for: colorScheme))
            .navigationTitle("رفع مقطع")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") {
                        showVideoPicker = false
                    }
                    .foregroundStyle(AppTheme.interactive(for: colorScheme))
                }
            }
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
