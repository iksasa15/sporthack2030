import SwiftUI
import AVFoundation
import Combine
#if os(iOS)
import Photos
import UIKit
#endif

#if os(iOS)
/// يرفع المقطع للخادم (Python) ويعرض الفيديو الناتج بعد تحديد الجسم.
struct VideoBodyPoseView: View {
    let videoURL: URL
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var phase: Phase = .uploading
    @State private var resultVideoURL: URL?
    @State private var errorMessage: String?
    @State private var isSaving = false
    @State private var saveMessage: String?

    private enum Phase {
        case uploading
        case analyzing
        case done
        case error
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let url = resultVideoURL {
                    VStack(spacing: 0) {
                        InteractiveVideoPlayerView(url: url)
                            .ignoresSafeArea()
                    }
                } else if phase == .error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.yellow)
                        Text(errorMessage ?? "حدث خطأ")
                            .font(.appFont(.regular, size: 16))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                        Text(phaseText)
                            .font(.appFont(.medium, size: 17))
                            .foregroundStyle(.white)
                        Text("تحديد الجسم يتم من الخادم (Python)")
                            .font(.appFont(.regular, size: 13))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
            .navigationTitle("تحديد الجسم")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إغلاق") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
                if resultVideoURL != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            Task { await saveAnalyzedVideo() }
                        } label: {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "square.and.arrow.down")
                                Text("حفظ المقطع")
                            }
                        }
                        .foregroundStyle(.white)
                        .disabled(isSaving)
                    }
                }
            }
            .alert("حفظ المقطع", isPresented: Binding(get: { saveMessage != nil }, set: { if !$0 { saveMessage = nil } })) {
                Button("حسناً") { saveMessage = nil }
            } message: {
                if let msg = saveMessage { Text(msg) }
            }
            .task {
                await runBackendFlow()
            }
        }
    }

    private var phaseText: String {
        switch phase {
        case .uploading: return "جاري رفع المقطع..."
        case .analyzing: return "جاري تحديد الجسم على الخادم..."
        case .done: return "تم"
        case .error: return ""
        }
    }

    @MainActor
    private func runBackendFlow() async {
        do {
            phase = .uploading
            errorMessage = nil
            phase = .analyzing
            if let remoteURL = try await BackendPoseService.processVideoAndGetResultURL(localVideoURL: videoURL, sport: "unknown") {
                let localURL: URL
                if remoteURL.isFileURL {
                    localURL = remoteURL
                } else {
                    let (data, _) = try await URLSession.shared.data(from: remoteURL)
                    let ext = remoteURL.pathExtension.isEmpty ? "mp4" : remoteURL.pathExtension
                    let temp = FileManager.default.temporaryDirectory
                        .appendingPathComponent("pose_\(UUID().uuidString).\(ext)")
                    try data.write(to: temp)
                    localURL = temp
                }
                resultVideoURL = localURL
                phase = .done
            } else {
                phase = .error
                errorMessage = "لم يُرجع الخادم فيديو بالتحديد."
            }
        } catch {
            phase = .error
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func saveAnalyzedVideo() async {
        guard let url = resultVideoURL else { return }
        isSaving = true
        saveMessage = nil
        defer { isSaving = false }
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        let requested: PHAuthorizationStatus
        if status == .notDetermined {
            requested = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        } else {
            requested = status
        }
        guard requested == .authorized || requested == .limited else {
            saveMessage = "يجب السماح بالوصول لمكتبة الصور من الإعدادات."
            return
        }
        do {
            let localURL: URL
            if url.isFileURL {
                localURL = url
            } else {
                let (data, _) = try await URLSession.shared.data(from: url)
                let ext = url.pathExtension.isEmpty ? "mp4" : url.pathExtension
                let temp = FileManager.default.temporaryDirectory
                    .appendingPathComponent("analyzed_\(UUID().uuidString).\(ext)")
                try data.write(to: temp)
                localURL = temp
            }
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: localURL)
            }
            saveMessage = "تم حفظ المقطع في مكتبة الصور."
        } catch {
            saveMessage = "فشل الحفظ: \(error.localizedDescription)"
        }
    }
}

// MARK: - Interactive video player (play/pause, seek)
private struct InteractiveVideoPlayerView: View {
    let url: URL
    @StateObject private var playerState = VideoPlayerState()

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                VideoLayerView(player: playerState.player)
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .aspectRatio(9/16, contentMode: .fit)
                    .onTapGesture {
                        playerState.togglePlayPause()
                    }
                if playerState.loadFailed {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.yellow)
                        Text("الفيديو لا يعمل أو الملف تالف")
                            .font(.appFont(.regular, size: 15))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else if !playerState.isPlaying && !playerState.loadFailed {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            VStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: { playerState.currentTime },
                        set: { playerState.seek(to: $0) }
                    ),
                    in: 0...max(1, playerState.duration)
                )
                .tint(.white)
                HStack(spacing: 12) {
                    Button {
                        playerState.togglePlayPause()
                    } label: {
                        Image(systemName: playerState.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.white)
                    }
                    Text(formatTime(playerState.currentTime))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(minWidth: 40, alignment: .leading)
                    Spacer()
                    Text(formatTime(playerState.duration))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(minWidth: 40, alignment: .trailing)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .background(Color.black.opacity(0.5))
        }
        .background(Color.black)
        .onAppear {
            playerState.setURL(url)
        }
        .onDisappear {
            playerState.pause()
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}

private final class VideoPlayerState: ObservableObject {
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isPlaying: Bool = false
    @Published private(set) var player: AVPlayer?
    @Published private(set) var loadFailed: Bool = false
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var endObserver: NSObjectProtocol?

    func setURL(_ url: URL) {
        loadFailed = false
        let item = AVPlayerItem(url: url)
        let p = AVPlayer(playerItem: item)
        player = p
        isPlaying = false
        duration = 0
        currentTime = 0
        statusObserver = item.observe(\.status) { [weak self] it, _ in
            guard let self else { return }
            DispatchQueue.main.async {
                switch it.status {
                case .readyToPlay:
                    let sec = it.duration.seconds
                    let d = sec.isFinite && sec > 0 ? sec : 1.0
                    self.duration = d
                    if p.rate == 0 {
                        p.play()
                        self.isPlaying = true
                    }
                case .failed:
                    self.loadFailed = true
                    self.isPlaying = false
                default:
                    break
                }
            }
        }
        timeObserver = p.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.25, preferredTimescale: 600), queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }
        p.play()
        isPlaying = true
        endObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak self] _ in
            self?.isPlaying = false
        }
    }

    func togglePlayPause() {
        guard let p = player else { return }
        if p.rate != 0 {
            p.pause()
            isPlaying = false
        } else {
            p.play()
            isPlaying = true
        }
    }

    func seek(to seconds: Double) {
        player?.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
        currentTime = seconds
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    deinit {
        if let o = timeObserver, let p = player {
            p.removeTimeObserver(o)
        }
        if let o = endObserver {
            NotificationCenter.default.removeObserver(o)
        }
    }
}

private struct VideoLayerView: UIViewRepresentable {
    let player: AVPlayer?

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.player = player
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        uiView.player = player
    }
}

private final class PlayerContainerView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }
    private var playerLayer: AVPlayerLayer? { layer as? AVPlayerLayer }
    var player: AVPlayer? {
        get { playerLayer?.player }
        set { playerLayer?.player = newValue }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
        playerLayer?.videoGravity = .resizeAspect
    }
}

/// معاينة المقطع قبل الرفع — يعرض الفيديو مع زر «رفع وتحليل».
struct VideoPreviewBeforeUploadView: View {
    let url: URL
    let onUpload: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                    InteractiveVideoPlayerView(url: url)
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        Text("عاين المقطع ثم اضغط رفع للتحليل")
                            .font(.appFont(.regular, size: 14))
                            .foregroundStyle(.white.opacity(0.9))
                        Button(action: onUpload) {
                            HStack {
                                Image(systemName: "arrow.up.circle.fill")
                                Text("رفع وتحليل")
                                    .font(.appFont(.medium, size: 17))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(.white)
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.vertical, 16)
                    .background(Color.black.opacity(0.6))
                }
            }
            .navigationTitle("معاينة المقطع")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") {
                        onDismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }
}

#else
struct VideoBodyPoseView: View {
    let videoURL: URL
    var body: some View { Text("غير متاح") }
}
struct VideoPreviewBeforeUploadView: View {
    let url: URL
    let onUpload: () -> Void
    let onDismiss: () -> Void
    var body: some View { Text("غير متاح") }
}
#endif

#Preview {
    VideoBodyPoseView(videoURL: URL(fileURLWithPath: "/tmp/sample.mov"))
}
