import SwiftUI

/// Draws body skeleton overlay on camera (same style as on analyzed video clips).
struct BodyPoseOverlayView: View {
    @Environment(\.colorScheme) private var colorScheme

    let landmarks: [PoseLandmark]
    let connections: [(Int, Int)]
    let isFrontCamera: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(Array(connections.enumerated()), id: \.offset) { _, pair in
                    if let start = landmark(byId: pair.0), let end = landmark(byId: pair.1) {
                        Path { path in
                            path.move(to: convertToViewPoint(CGPoint(x: start.x, y: start.y), in: proxy.size))
                            path.addLine(to: convertToViewPoint(CGPoint(x: end.x, y: end.y), in: proxy.size))
                        }
                        .stroke(AppTheme.interactive(for: colorScheme), lineWidth: 2.5)
                    }
                }
                ForEach(landmarks) { lm in
                    let converted = convertToViewPoint(CGPoint(x: lm.x, y: lm.y), in: proxy.size)
                    Circle()
                        .fill(AppTheme.interactive(for: colorScheme))
                        .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 1))
                        .frame(width: 8, height: 8)
                        .position(converted)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func landmark(byId id: Int) -> PoseLandmark? {
        landmarks.first { $0.id == id }
    }

    private func convertToViewPoint(_ normalized: CGPoint, in size: CGSize) -> CGPoint {
        let videoRect = fittedVideoRect(in: size)
        let normalizedX = isFrontCamera ? (1 - normalized.x) : normalized.x
        let x = videoRect.minX + (normalizedX * videoRect.width)
        let y = videoRect.minY + ((1 - normalized.y) * videoRect.height)
        return CGPoint(x: x, y: y)
    }

    private func fittedVideoRect(in size: CGSize) -> CGRect {
        let cameraAspect: CGFloat = 9.0 / 16.0
        let viewAspect = size.width / max(size.height, 1)
        if viewAspect > cameraAspect {
            let height = size.height
            let width = height * cameraAspect
            let x = (size.width - width) / 2
            return CGRect(x: x, y: 0, width: width, height: height)
        } else {
            let width = size.width
            let height = width / cameraAspect
            let y = (size.height - height) / 2
            return CGRect(x: 0, y: y, width: width, height: height)
        }
    }
}
