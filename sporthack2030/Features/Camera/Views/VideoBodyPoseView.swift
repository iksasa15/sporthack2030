import SwiftUI
import AVFoundation
import Combine
import Vision

#if os(iOS)
import UIKit

/// Plays a video file and draws body pose skeleton overlay in real time.
struct VideoBodyPoseView: View {
    let videoURL: URL
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var poseModel = VideoPoseViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                VideoPlayerView(url: videoURL, poseModel: poseModel)
                    .ignoresSafeArea()

                VideoBodyPoseOverlay(landmarks: poseModel.bodyLandmarks, videoSize: poseModel.videoSize)
                    .ignoresSafeArea()
            }
            .background(Color.black)
            .navigationTitle("تحديد الجسم")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إغلاق") {
                        poseModel.pause()
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .onAppear {
                poseModel.loadVideo(url: videoURL)
                poseModel.play()
            }
            .onDisappear {
                poseModel.pause()
            }
        }
    }
}

// MARK: - Video player (AVPlayerLayer)
private struct VideoPlayerView: UIViewRepresentable {
    let url: URL
    @ObservedObject var poseModel: VideoPoseViewModel

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.player = poseModel.player
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        uiView.player = poseModel.player
    }
}

private final class PlayerContainerView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }
    var player: AVPlayer? {
        get { (layer as? AVPlayerLayer)?.player }
        set { (layer as? AVPlayerLayer)?.player = newValue }
    }
}

// MARK: - Overlay drawing body skeleton (image-space points → view-space)
fileprivate struct VideoBodyPoseOverlay: View {
    let landmarks: [VNRecognizedPointKey: CGPoint]
    let videoSize: CGSize

    private static let bodyConnections: [(VNRecognizedPointKey, VNRecognizedPointKey)] = [
        (.leftShoulder, .rightShoulder),
        (.leftShoulder, .leftElbow),
        (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow),
        (.rightElbow, .rightWrist),
        (.leftShoulder, .neck),
        (.rightShoulder, .neck),
        (.neck, .root),
        (.root, .leftHip),
        (.root, .rightHip),
        (.leftHip, .leftKnee),
        (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee),
        (.rightKnee, .rightAnkle),
        (.leftHip, .rightHip),
    ]

    var body: some View {
        GeometryReader { geo in
            let viewSize = geo.size
            let fitted = fittedVideoRect(videoSize: videoSize, viewSize: viewSize)
            ZStack {
                ForEach(Array(Self.bodyConnections.enumerated()), id: \.offset) { _, pair in
                    if let a = landmarks[pair.0], let b = landmarks[pair.1] {
                        let va = imageToView(a, videoSize: videoSize, fitted: fitted)
                        let vb = imageToView(b, videoSize: videoSize, fitted: fitted)
                        Path { path in
                            path.move(to: va)
                            path.addLine(to: vb)
                        }
                        .stroke(Color.green, lineWidth: 3)
                    }
                }
                ForEach(Array(landmarks.keys), id: \.rawValue) { key in
                    if let p = landmarks[key] {
                        let vp = imageToView(p, videoSize: videoSize, fitted: fitted)
                        Circle()
                            .fill(Color.cyan)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                            .position(vp)
                    }
                }
            }
            .allowsHitTesting(false)
        }
    }

    private func fittedVideoRect(videoSize: CGSize, viewSize: CGSize) -> CGRect {
        guard videoSize.width > 0, videoSize.height > 0 else { return CGRect(origin: .zero, size: viewSize) }
        let videoAspect = videoSize.width / videoSize.height
        let viewAspect = viewSize.width / viewSize.height
        if viewAspect > videoAspect {
            let h = viewSize.height
            let w = h * videoAspect
            return CGRect(x: (viewSize.width - w) / 2, y: 0, width: w, height: h)
        } else {
            let w = viewSize.width
            let h = w / videoAspect
            return CGRect(x: 0, y: (viewSize.height - h) / 2, width: w, height: h)
        }
    }

    private func imageToView(_ p: CGPoint, videoSize: CGSize, fitted: CGRect) -> CGPoint {
        guard videoSize.width > 0, videoSize.height > 0 else { return p }
        let x = fitted.minX + (p.x / videoSize.width) * fitted.width
        let y = fitted.minY + (1 - p.y / videoSize.height) * fitted.height
        return CGPoint(x: x, y: y)
    }
}

// MARK: - ViewModel: play video + sample frames + run Vision body pose
fileprivate final class VideoPoseViewModel: ObservableObject {
    @Published var bodyLandmarks: [VNRecognizedPointKey: CGPoint] = [:]
    @Published var videoSize: CGSize = .zero

    private(set) var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var asset: AVAsset?
    private var displayLink: CADisplayLink?
    private var playerLayer: AVPlayerLayer?
    private let request = VNDetectHumanBodyPoseRequest()
    private let queue = DispatchQueue(label: "video.pose.queue")
    private var lastRequestTime: CFTimeInterval = 0
    private let minRequestInterval: CFTimeInterval = 0.08 // ~12 fps for overlay

    func loadVideo(url: URL) {
        let asset = AVAsset(url: url)
        self.asset = asset
        let item = AVPlayerItem(asset: asset)
        playerItem = item
        player = AVPlayer(playerItem: item)

        Task {
            if let track = try? await asset.loadTracks(withMediaType: .video).first,
               let size = try? await track.load(.naturalSize),
               let transform = try? await track.load(.preferredTransform) {
                let w = size.width
                let h = size.height
                let t = transform
                let actualW = abs(t.a) * w + abs(t.c) * h
                let actualH = abs(t.d) * h + abs(t.b) * w
                await MainActor.run {
                    self.videoSize = CGSize(width: actualW, height: actualH)
                }
            }
        }
    }

    func play() {
        player?.play()
        startDisplayLink()
    }

    func pause() {
        player?.pause()
        stopDisplayLink()
    }

    private func startDisplayLink() {
        stopDisplayLink()
        let link = CADisplayLink(target: self, selector: #selector(processFrame))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func processFrame(_ link: CADisplayLink) {
        let now = link.timestamp
        guard now - lastRequestTime >= minRequestInterval else { return }
        lastRequestTime = now

        guard let player = player,
              let asset = asset,
              let currentItem = player.currentItem else { return }

        let time = currentItem.currentTime()
        guard time.isNumeric, CMTimeGetSeconds(time) >= 0 else { return }

        queue.async { [weak self] in
            self?.generateFrameAndDetectPose(asset: asset, at: time)
        }
    }

    private func generateFrameAndDetectPose(asset: AVAsset, at time: CMTime) {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.02, preferredTimescale: 600)

        var actualTime: CMTime = .zero
        guard let cgImage = try? generator.copyCGImage(at: time, actualTime: &actualTime) else { return }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return
        }

        guard let observation = request.results?.first else {
            DispatchQueue.main.async { [weak self] in
                self?.bodyLandmarks = [:]
            }
            return
        }

        let renderSize = CGSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
        var points: [VNRecognizedPointKey: CGPoint] = [:]

        for joint in [VNRecognizedPointKey.leftAnkle, .leftKnee, .leftHip, .rightAnkle, .rightKnee, .rightHip,
                      .leftWrist, .leftElbow, .leftShoulder, .rightWrist, .rightElbow, .rightShoulder,
                      .neck, .root, .nose] {
            let point = try? observation.recognizedPoint(joint)
            guard let p = point, p.confidence > 0.3 else { continue }
            let x = p.location.x * renderSize.width
            let y = (1 - p.location.y) * renderSize.height
            points[joint] = CGPoint(x: x, y: y)
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.bodyLandmarks = points
            if self.videoSize.width == 0 {
                self.videoSize = renderSize
            }
        }
    }
}

// VNRecognizedPointKey is the type for joint names in Vision - we use the joint name type from VNHumanBodyPoseObservation
private typealias VNRecognizedPointKey = VNHumanBodyPoseObservation.JointName

#else
struct VideoBodyPoseView: View {
    let videoURL: URL
    var body: some View { Text("غير متاح") }
}
#endif

#Preview {
    VideoBodyPoseView(videoURL: URL(fileURLWithPath: "/tmp/sample.mov"))
}
