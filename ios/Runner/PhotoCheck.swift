import Flutter
import ImageIO
import Vision

/// Tells whether a photo shows a person head to toe, with Vision's body pose
/// detection on the device.
enum PhotoCheck {
  static let channelName = "in_vogue/photo_check"

  /// Joints that must be seen for a photo to count as head to toe.
  private static let joints: [VNHumanBodyPoseObservation.JointName] = [
    .nose, .leftAnkle, .rightAnkle,
  ]

  /// Vision's confidence below which a joint counts as not seen.
  private static let minimumConfidence: VNConfidence = 0.3

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "isFullLength" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let arguments = call.arguments as? [String: Any],
        let path = arguments["path"] as? String
      else {
        result(FlutterError(code: "bad_arguments", message: "A path is required", details: nil))
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        let answer: Any
        do {
          answer = try isFullLength(path: path)
        } catch {
          answer = FlutterError(
            code: "unreadable", message: error.localizedDescription, details: nil)
        }
        DispatchQueue.main.async { result(answer) }
      }
    }
  }

  static func isFullLength(path: String) throws -> Bool {
    let url = URL(fileURLWithPath: path) as CFURL
    guard let source = CGImageSourceCreateWithURL(url, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else {
      throw PhotoCheckError.unreadable
    }
    let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
    let orientation =
      (properties?[kCGImagePropertyOrientation] as? UInt32)
      .flatMap(CGImagePropertyOrientation.init(rawValue:)) ?? .up
    let request = VNDetectHumanBodyPoseRequest()
    try VNImageRequestHandler(cgImage: image, orientation: orientation).perform([request])
    return (request.results ?? []).contains { observation in
      guard let points = try? observation.recognizedPoints(.all) else { return false }
      return joints.allSatisfy { (points[$0]?.confidence ?? 0) >= minimumConfidence }
    }
  }
}

enum PhotoCheckError: Error {
  case unreadable
}
