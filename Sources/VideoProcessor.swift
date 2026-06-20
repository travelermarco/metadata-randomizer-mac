import Foundation
import AVFoundation

enum VideoProcessor {

    static let supportedExtensions: Set<String> = [
        "mp4", "mov", "m4v", "avi", "mkv"
    ]

    static func process(url: URL) async throws -> (URL, String) {
        let asset = AVURLAsset(url: url)

        // Prefer passthrough (no re-encode); fall back to highest-quality if asset is incompatible
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough)
            ?? AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        guard let exportSession else { throw ProcessingError.cannotExport }

        let filename  = FakeMetadata.randomVideoFilename()
        let outputURL = outputDirectory(for: url).appendingPathComponent(filename)

        // Remove any leftover file at the output path
        try? FileManager.default.removeItem(at: outputURL)

        exportSession.outputURL      = outputURL
        exportSession.outputFileType = .mp4
        // Strip location, user-identifying metadata from the container
        exportSession.metadata           = []
        exportSession.metadataItemFilter = AVMetadataItemFilter.forSharing()

        await exportSession.export()

        switch exportSession.status {
        case .completed:
            let summary = FakeMetadata.videoSummary()
            return (outputURL, "\(filename) · \(summary)")
        default:
            throw exportSession.error
                ?? NSError(domain: "VideoProcessor", code: 1,
                           userInfo: [NSLocalizedDescriptionKey: "Export failed with status \(exportSession.status.rawValue)"])
        }
    }

    private static func outputDirectory(for url: URL) -> URL {
        let dir = url.deletingLastPathComponent()
        if FileManager.default.isWritableFile(atPath: dir.path) { return dir }
        return FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first ?? dir
    }
}
