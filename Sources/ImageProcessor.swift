import Foundation
import CoreImage
import ImageIO
import UniformTypeIdentifiers

enum ProcessingError: LocalizedError {
    case cannotOpen, cannotDecode, cannotRender, cannotCreate, cannotWrite, cannotExport

    var errorDescription: String? {
        switch self {
        case .cannotOpen:   return "Cannot open the file."
        case .cannotDecode: return "Cannot decode the image."
        case .cannotRender: return "Cannot render the processed image."
        case .cannotCreate: return "Cannot create the output file."
        case .cannotWrite:  return "Cannot write the output file."
        case .cannotExport: return "Cannot export the video."
        }
    }
}

enum ImageProcessor {

    static let supportedExtensions: Set<String> = [
        "jpg", "jpeg", "heic", "heif", "png", "tiff", "tif", "webp", "bmp"
    ]

    static func process(url: URL) throws -> (URL, String) {
        // CIImage with automatic orientation baking — strips all source metadata
        guard let ciImage = CIImage(contentsOf: url, options: [.applyOrientationProperty: true]) else {
            throw ProcessingError.cannotOpen
        }

        // Render to CGImage: pure pixels, no EXIF attached
        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            throw ProcessingError.cannotRender
        }

        let filename  = FakeMetadata.randomImageFilename()
        let outputURL = outputDirectory(for: url).appendingPathComponent(filename)

        guard let destination = CGImageDestinationCreateWithURL(
            outputURL as CFURL,
            UTType.jpeg.identifier as CFString,
            1, nil
        ) else { throw ProcessingError.cannotCreate }

        // Write with ONLY fake properties — original metadata is never copied
        let (fakeProps, summary) = FakeMetadata.generateImageProperties()
        CGImageDestinationAddImage(destination, cgImage, fakeProps as CFDictionary)

        guard CGImageDestinationFinalize(destination) else { throw ProcessingError.cannotWrite }

        return (outputURL, "\(filename) · \(summary)")
    }

    private static func outputDirectory(for url: URL) -> URL {
        let dir = url.deletingLastPathComponent()
        // Try to write alongside the original; fall back to Desktop
        if FileManager.default.isWritableFile(atPath: dir.path) { return dir }
        return FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first ?? dir
    }
}
