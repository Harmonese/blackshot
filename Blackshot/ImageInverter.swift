import AppKit
import CoreImage
import ImageIO
import UniformTypeIdentifiers

enum ImageInverter {
    nonisolated static func invert(_ data: Data) throws -> Data {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw Failure.invalidImage
        }
        let space = image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!
        // Disable automatic linear working-space conversion: invert the encoded RGB channels.
        let context = CIContext(options: [.workingColorSpace: NSNull()])
        let output = CIImage(cgImage: image).applyingFilter("CIColorInvert")
        guard let inverted = context.createCGImage(output, from: output.extent, format: .RGBA8, colorSpace: space) else {
            throw Failure.processing
        }
        let png = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(png, UTType.png.identifier as CFString, 1, nil) else {
            throw Failure.processing
        }
        let original = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] ?? [:]
        var properties: [CFString: Any] = [:]
        properties[kCGImagePropertyDPIWidth] = original[kCGImagePropertyDPIWidth]
        properties[kCGImagePropertyDPIHeight] = original[kCGImagePropertyDPIHeight]
        CGImageDestinationAddImage(destination, inverted, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw Failure.processing }
        return png as Data
    }
    enum Failure: Error { case invalidImage, processing }
}
