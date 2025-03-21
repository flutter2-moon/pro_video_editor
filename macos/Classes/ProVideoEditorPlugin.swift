import Cocoa
import FlutterMacOS

public class ProVideoEditorPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "pro_video_editor", binaryMessenger: registrar.messenger)
    let instance = ProVideoEditorPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)

    case "getVideoInformation":
      guard let args = call.arguments as? [String: Any],
            let videoData = args["videoBytes"] as? FlutterStandardTypedData,
            let ext = args["extension"] as? String else {
        result(["error": "Invalid arguments"])
        return
      }

      let output = VideoProcessor.processVideo(videoData: videoData.data, ext: ext)
      result(output)

    case "createVideoThumbnails":
      guard let args = call.arguments as? [String: Any],
            let videoData = args["videoBytes"] as? FlutterStandardTypedData,
            let rawTimestamps = args["timestamps"] as? [Double],
            let format = args["thumbnailFormat"] as? String,
            let ext = args["extension"] as? String,
            let width = args["imageWidth"] as? NSNumber else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing or invalid arguments", details: nil))
        return
      }

      ThumbnailGenerator.generateThumbnails(
        videoBytes: videoData.data,
        timestamps: rawTimestamps,
        thumbnailFormat: format,
        extension: ext,
        width: width
      ) { thumbnails in
        let flutterDataList = thumbnails.map { FlutterStandardTypedData(bytes: $0) }
        result(flutterDataList)
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
