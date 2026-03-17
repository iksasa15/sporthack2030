import AVFoundation
import Combine
import CoreImage
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct TrackedHand: Identifiable, Equatable {
    let id: String
    let handedness: String
    let score: CGFloat
    let landmarks: [Int: CGPoint]
}

/// Body pose landmark (normalized 0–1) for live skeleton overlay.
struct PoseLandmark: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let z: CGFloat
}

final class CameraManager: NSObject, ObservableObject {
    @Published var trackedHands: [TrackedHand] = []
    @Published var raisedFingersCount = 0
    @Published var interactionMessage = "وجّه يدك نحو الكاميرا"
    @Published var authorizationDenied = false
    @Published var isUsingFrontCamera = false
    @Published var isTorchOn = false
    @Published var isTorchAvailable = false
    /// Live body pose for skeleton overlay (same as on analyzed clips).
    @Published var poseLandmarks: [PoseLandmark] = []
    @Published var poseConnections: [(Int, Int)] = []

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let outputQueue = DispatchQueue(label: "camera.output.queue")
    private let ciContext = CIContext()

    private var isConfigured = false
    private var currentCameraPosition: AVCaptureDevice.Position = .back
    private var isRequestInFlight = false
    private var frameCounter = 0
    private var smoothedHandLandmarks: [String: [Int: CGPoint]] = [:]
    private var previousRaisedFingersCount = 0

    func startSession() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureIfNeededAndStart()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.authorizationDenied = !granted
                }
                if granted {
                    self?.configureIfNeededAndStart()
                }
            }
        default:
            DispatchQueue.main.async { [weak self] in
                self?.authorizationDenied = true
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard self.isConfigured else { return }

            self.currentCameraPosition = self.currentCameraPosition == .back ? .front : .back
            self.session.beginConfiguration()
            let configuredInput = self.configureCameraInput(position: self.currentCameraPosition)
            if configuredInput {
                self.configureOutputConnection(position: self.currentCameraPosition)
            }
            self.session.commitConfiguration()
            self.turnTorchOffIfNeeded()
            self.updateTorchAvailability()

            DispatchQueue.main.async {
                self.isUsingFrontCamera = self.currentCameraPosition == .front
            }
        }
    }

    func toggleTorch() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard let device = self.currentCaptureDevice(), device.hasTorch else { return }
            do {
                try device.lockForConfiguration()
                let newState = !self.isTorchOn
                if newState {
                    try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
                } else {
                    device.torchMode = .off
                }
                device.unlockForConfiguration()

                DispatchQueue.main.async {
                    self.isTorchOn = newState
                    self.isTorchAvailable = device.hasTorch
                }
            } catch {
                DispatchQueue.main.async {
                    self.isTorchOn = false
                }
            }
        }
    }

    private func configureIfNeededAndStart() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.isConfigured {
                self.configureSession()
            }
            guard self.isConfigured else { return }
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        defer { session.commitConfiguration() }

        guard configureCameraInput(position: currentCameraPosition) else {
            return
        }

        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: outputQueue)

        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        configureOutputConnection(position: currentCameraPosition)

        isConfigured = true
        updateTorchAvailability()
        DispatchQueue.main.async {
            self.isUsingFrontCamera = self.currentCameraPosition == .front
        }
    }

    @discardableResult
    private func configureCameraInput(position: AVCaptureDevice.Position) -> Bool {
        session.inputs.forEach { session.removeInput($0) }

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(input) else {
            return false
        }

        session.addInput(input)
        return true
    }

    private func configureOutputConnection(position: AVCaptureDevice.Position) {
        guard let connection = (session.outputs.first as? AVCaptureVideoDataOutput)?.connection(with: .video) else {
            return
        }

        connection.videoRotationAngle = 90
        connection.automaticallyAdjustsVideoMirroring = false
        connection.isVideoMirrored = position == .front
    }

    private func currentCaptureDevice() -> AVCaptureDevice? {
        let input = session.inputs.first as? AVCaptureDeviceInput
        return input?.device
    }

    private func turnTorchOffIfNeeded() {
        guard let device = currentCaptureDevice(), device.hasTorch else {
            DispatchQueue.main.async {
                self.isTorchOn = false
            }
            return
        }

        do {
            try device.lockForConfiguration()
            device.torchMode = .off
            device.unlockForConfiguration()
        } catch {
            // Ignore torch lock failures silently.
        }

        DispatchQueue.main.async {
            self.isTorchOn = false
        }
    }

    private func updateTorchAvailability() {
        let available = currentCaptureDevice()?.hasTorch ?? false
        DispatchQueue.main.async {
            self.isTorchAvailable = available
            if !available {
                self.isTorchOn = false
            }
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        frameCounter += 1
        guard frameCounter % 5 == 0 else { return } // reduce API load
        guard !isRequestInFlight else { return }

        guard let imageBase64 = makeBase64JPEG(from: sampleBuffer) else { return }
        isRequestInFlight = true
        sendFrameToMediaPipe(imageBase64: imageBase64)
        sendFrameToPose(imageBase64: imageBase64)
    }

    private func makeBase64JPEG(from sampleBuffer: CMSampleBuffer) -> String? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return nil }

#if os(iOS)
        let image = UIImage(cgImage: cgImage)
        guard let data = image.jpegData(compressionQuality: 0.5) else { return nil }
        return data.base64EncodedString()
#else
        return nil
#endif
    }

    private func sendFrameToMediaPipe(imageBase64: String) {
        guard let url = URL(string: AppConnection.mediaPipeFingersURLString) else {
            isRequestInFlight = false
            return
        }

        var request = URLRequest(url: url, timeoutInterval: 4)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = ["image_base64": imageBase64]
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
            isRequestInFlight = false
            return
        }
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { [weak self] data, response, _ in
            guard let self else { return }
            defer { self.isRequestInFlight = false }

            guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let data else { return }

            DispatchQueue.main.async {
                guard let apiResponse = try? JSONDecoder().decode(MediaPipeHandsResponse.self, from: data) else { return }
                let hands = self.mapHands(from: apiResponse)
                let stableHands = self.smooth(hands: hands)
                let (count, message) = self.evaluateInteraction(from: stableHands)
                self.trackedHands = stableHands
                self.raisedFingersCount = count
                self.interactionMessage = message
            }
        }.resume()
    }

    private func sendFrameToPose(imageBase64: String) {
        guard let url = URL(string: AppConnection.mediaPipePoseURLString) else { return }
        var request = URLRequest(url: url, timeoutInterval: 3)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload = ["image_base64": imageBase64]
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { [weak self] data, response, _ in
            guard let self else { return }
            guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let data else { return }
            guard let apiResponse = try? JSONDecoder().decode(MediaPipePoseResponse.self, from: data),
                  apiResponse.success else { return }
            let landmarks = apiResponse.landmarks.map { lm in
                PoseLandmark(id: lm.id, x: CGFloat(lm.x), y: CGFloat(lm.y), z: CGFloat(lm.z))
            }
            let connections = apiResponse.connections.map { c in (c[0], c[1]) }
            DispatchQueue.main.async {
                self.poseLandmarks = landmarks
                self.poseConnections = connections
            }
        }.resume()
    }

    private func mapHands(from response: MediaPipeHandsResponse) -> [TrackedHand] {
        guard response.success, response.hands.detected else { return [] }

        return response.hands.hands.map { hand in
            let correctedHandedness = correctedHandedness(for: hand.handedness)
            let points = Dictionary(uniqueKeysWithValues: hand.landmarks.map { item in
                (item.id, CGPoint(x: CGFloat(item.x), y: CGFloat(item.y)))
            })
            let handId = "\(correctedHandedness)-\(Int(hand.score * 1000))"
            return TrackedHand(
                id: handId,
                handedness: correctedHandedness,
                score: CGFloat(hand.score),
                landmarks: points
            )
        }
    }

    private func correctedHandedness(for raw: String) -> String {
        let value = raw.lowercased()
        guard currentCameraPosition == .back else { return value }

        if value == "left" { return "right" }
        if value == "right" { return "left" }
        return value
    }

    private func smooth(hands newHands: [TrackedHand]) -> [TrackedHand] {
        let alpha: CGFloat = 0.45
        var result: [TrackedHand] = []
        var newCache: [String: [Int: CGPoint]] = [:]

        for hand in newHands {
            let cacheKey = hand.handedness
            let previousLandmarks = smoothedHandLandmarks[cacheKey] ?? [:]
            var mergedLandmarks: [Int: CGPoint] = [:]

            for (id, point) in hand.landmarks {
                if let previous = previousLandmarks[id] {
                    mergedLandmarks[id] = CGPoint(
                        x: previous.x + alpha * (point.x - previous.x),
                        y: previous.y + alpha * (point.y - previous.y)
                    )
                } else {
                    mergedLandmarks[id] = point
                }
            }

            newCache[cacheKey] = mergedLandmarks
            result.append(
                TrackedHand(
                    id: hand.id,
                    handedness: hand.handedness,
                    score: hand.score,
                    landmarks: mergedLandmarks
                )
            )
        }

        smoothedHandLandmarks = newCache
        return result
    }

    private func evaluateInteraction(from hands: [TrackedHand]) -> (Int, String) {
        guard let activeHand = hands.max(by: { $0.score < $1.score }) else {
            previousRaisedFingersCount = 0
            return (0, "وجّه يدك نحو الكاميرا")
        }

        let count = raisedFingersCount(for: activeHand)
        let handLabel = activeHand.handedness == "left" ? "اليسرى" : "اليمنى"

        let message: String
        if count < previousRaisedFingersCount {
            message = "ممتاز! نزلت أصابعك - اليد \(handLabel) (\(count))"
        } else if count > previousRaisedFingersCount {
            message = "ممتاز! رفعت أصابعك - اليد \(handLabel) (\(count))"
        } else {
            message = "اليد \(handLabel) - عدد الأصابع المرفوعة: \(count)"
        }

        previousRaisedFingersCount = count
        return (count, message)
    }

    private func raisedFingersCount(for hand: TrackedHand) -> Int {
        let fingerPairs: [(tip: Int, pip: Int)] = [
            (8, 6),   // index
            (12, 10), // middle
            (16, 14), // ring
            (20, 18)  // pinky
        ]

        var count = 0
        for pair in fingerPairs {
            guard let tip = hand.landmarks[pair.tip], let pip = hand.landmarks[pair.pip] else { continue }
            if tip.y < pip.y - 0.01 {
                count += 1
            }
        }
        return count
    }
}

private struct MediaPipeHandsResponse: Decodable, Sendable {
    let success: Bool
    let hands: HandsBody

    struct HandsBody: Decodable, Sendable {
        let detected: Bool
        let hands: [Hand]
    }

    struct Hand: Decodable, Sendable {
        let handedness: String
        let score: Double
        let landmarks: [Landmark]
    }

    struct Landmark: Decodable, Sendable {
        let id: Int
        let x: Double
        let y: Double
        let z: Double
    }
}

private struct MediaPipePoseResponse: Decodable, Sendable {
    let success: Bool
    let landmarks: [PoseLandmarkDTO]
    let connections: [[Int]]

    struct PoseLandmarkDTO: Decodable, Sendable {
        let id: Int
        let x: Double
        let y: Double
        let z: Double
    }
}
