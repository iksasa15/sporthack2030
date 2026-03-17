import AVFoundation
import Combine
import Foundation

final class VisionViewModel: ObservableObject {
    @Published var trackedHands: [TrackedHand] = []
    @Published var raisedFingersCount = 0
    @Published var interactionMessage = "وجّه يدك نحو الكاميرا"
    @Published var authorizationDenied = false
    @Published var isUsingFrontCamera = false
    @Published var isTorchOn = false
    @Published var isTorchAvailable = false
    @Published var poseLandmarks: [PoseLandmark] = []
    @Published var poseConnections: [(Int, Int)] = []

    let cameraManager = CameraManager()
    private var cancellables = Set<AnyCancellable>()

    var session: AVCaptureSession { cameraManager.session }

    init() {
        cameraManager.$trackedHands
            .receive(on: RunLoop.main)
            .assign(to: &$trackedHands)

        cameraManager.$poseLandmarks
            .receive(on: RunLoop.main)
            .assign(to: &$poseLandmarks)

        cameraManager.$poseConnections
            .receive(on: RunLoop.main)
            .assign(to: &$poseConnections)

        cameraManager.$authorizationDenied
            .receive(on: RunLoop.main)
            .assign(to: &$authorizationDenied)

        cameraManager.$raisedFingersCount
            .receive(on: RunLoop.main)
            .assign(to: &$raisedFingersCount)

        cameraManager.$interactionMessage
            .receive(on: RunLoop.main)
            .assign(to: &$interactionMessage)

        cameraManager.$isUsingFrontCamera
            .receive(on: RunLoop.main)
            .assign(to: &$isUsingFrontCamera)

        cameraManager.$isTorchOn
            .receive(on: RunLoop.main)
            .assign(to: &$isTorchOn)

        cameraManager.$isTorchAvailable
            .receive(on: RunLoop.main)
            .assign(to: &$isTorchAvailable)
    }

    func start() {
        cameraManager.startSession()
    }

    func stop() {
        cameraManager.stopSession()
    }

    func switchCamera() {
        cameraManager.switchCamera()
    }

    func toggleTorch() {
        cameraManager.toggleTorch()
    }
}
