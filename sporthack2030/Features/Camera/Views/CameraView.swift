import SwiftUI

#if os(iOS)
import AVFoundation
import UIKit

struct CameraView: View {
    @StateObject private var viewModel = VisionViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(AppConnection.cameraExerciseNameKey) private var cameraExerciseName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                CameraPreviewView(session: viewModel.session)
                    .ignoresSafeArea()

                VisionOverlayView(
                    trackedHands: viewModel.trackedHands,
                    isFrontCamera: viewModel.isUsingFrontCamera
                )
                    .ignoresSafeArea()

                BodyPoseOverlayView(
                    landmarks: viewModel.poseLandmarks,
                    connections: viewModel.poseConnections,
                    isFrontCamera: viewModel.isUsingFrontCamera
                )
                    .ignoresSafeArea()

                if viewModel.authorizationDenied {
                    cameraDeniedView
                }

                VStack {
                    if !cameraExerciseName.isEmpty {
                        Text(cameraExerciseName)
                            .font(.appFont(.bold, size: 18))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.black.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .padding(.top, 12)
                    }
                    HStack {
                        Button {
                            viewModel.toggleTorch()
                        } label: {
                            Image(systemName: viewModel.isTorchOn ? "bolt.fill" : "bolt.slash.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(.black.opacity(0.35))
                                .clipShape(Circle())
                        }
                        .disabled(!viewModel.isTorchAvailable)
                        .opacity(viewModel.isTorchAvailable ? 1.0 : 0.45)
                        .padding(.leading, 16)
                        .padding(.top, 12)

                        Spacer()
                        Button {
                            viewModel.switchCamera()
                        } label: {
                            Image(systemName: "camera.rotate.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(.black.opacity(0.35))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 12)
                    }
                    Spacer()

                    VStack(spacing: 6) {
                        Text(viewModel.interactionMessage)
                            .font(.appFont(.medium, size: 13))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text("الأصابع المرفوعة: \(viewModel.raisedFingersCount)")
                            .font(.appFont(.regular, size: 12))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.bottom, 18)
                }
            }
            .background(AppTheme.background(for: colorScheme))
            .navigationTitle("الكاميرا")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { viewModel.start() }
            .onDisappear { viewModel.stop() }
        }
    }

    private var cameraDeniedView: some View {
        VStack(spacing: 10) {
            Text("السماح بالكاميرا مطلوب")
                .font(.appFont(.medium, size: 18))
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            Text("فعّل إذن الكاميرا من إعدادات الجهاز ثم أعد فتح الصفحة.")
                .font(.appFont(.regular, size: 14))
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.primaryText(for: colorScheme).opacity(0.75))
        }
        .padding(16)
        .background(AppTheme.card(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.cardBorder(for: colorScheme), lineWidth: 1)
        )
        .padding()
    }
}

private struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewContainerView {
        let view = PreviewContainerView()
        // Keep geometry consistent with normalized Vision points.
        view.previewLayer.videoGravity = .resizeAspect
        view.previewLayer.session = session
        return view
    }

    func updateUIView(_ uiView: PreviewContainerView, context: Context) {
        uiView.previewLayer.session = session
    }
}

private final class PreviewContainerView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var previewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Invalid layer type")
        }
        return layer
    }
}

#else
struct CameraView: View {
    var body: some View {
        NavigationStack {
            Text("الكاميرا غير مدعومة على هذا النظام.")
                .navigationTitle("الكاميرا")
        }
    }
}
#endif
