import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
guard args.count >= 4 else {
  fputs("Usage: upscale-lanczos.swift input output scale\n", stderr)
  exit(1)
}

let inputURL = URL(fileURLWithPath: args[1])
let outputURL = URL(fileURLWithPath: args[2])
let scale = Double(args[3]) ?? 2.0

guard
  let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
  let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
else {
  fputs("Could not read input image: \(inputURL.path)\n", stderr)
  exit(1)
}

let outputWidth = Int((Double(image.width) * scale).rounded())
let outputHeight = Int((Double(image.height) * scale).rounded())
let colorSpace = image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!
let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

guard
  let context = CGContext(
    data: nil,
    width: outputWidth,
    height: outputHeight,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: bitmapInfo.rawValue
  )
else {
  fputs("Could not create bitmap context\n", stderr)
  exit(1)
}

context.interpolationQuality = .high
context.setShouldAntialias(true)
context.setAllowsAntialiasing(true)
context.draw(image, in: CGRect(x: 0, y: 0, width: outputWidth, height: outputHeight))

guard let outputImage = context.makeImage() else {
  fputs("Could not create output image\n", stderr)
  exit(1)
}

guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
  fputs("Could not create destination: \(outputURL.path)\n", stderr)
  exit(1)
}

CGImageDestinationAddImage(destination, outputImage, nil)
if !CGImageDestinationFinalize(destination) {
  fputs("Could not write output image: \(outputURL.path)\n", stderr)
  exit(1)
}
