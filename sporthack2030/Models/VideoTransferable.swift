import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// Used to load a video URL from PhotosPickerItem.
struct VideoFile: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let ext = received.file.pathExtension.isEmpty ? "mov" : received.file.pathExtension
            let temp = FileManager.default.temporaryDirectory
                .appendingPathComponent("video_\(UUID().uuidString).\(ext)")
            try FileManager.default.copyItem(at: received.file, to: temp)
            return Self(url: temp)
        }
    }
}
