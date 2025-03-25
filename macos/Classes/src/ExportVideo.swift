import Foundation
import ffmpegkit

class ExportVideo {
    
    static func generate(
        videoBytes: Data,
        imageBytes: Data,
        outputFormat: String,
        preset: String,
        startTime: Int?,
        endTime: Int?,
        videoDuration: Int,
        constantRateFactor: Int,
        filters: String,
        onSuccess: @escaping (String) -> Void,
        onError: @escaping (String) -> Void,
        onProgress: ((Double) -> Void)? = nil
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let tempDir = FileManager.default.temporaryDirectory
                
                let videoURL = tempDir.appendingPathComponent("input_video.mp4")
                let imageURL = tempDir.appendingPathComponent("overlay_image.png")
                let outputURL = tempDir.appendingPathComponent("output_video.\(outputFormat)")
                
                try videoBytes.write(to: videoURL)
                try imageBytes.write(to: imageURL)
                
                // Build filter string
                var filterGraph = ""

                if !filters.isEmpty {
                    filterGraph += "[0:v]\(filters)[vid];"
                    filterGraph += "[1:v][vid]scale2ref=w=iw:h=ih[ovr][base];"
                    filterGraph += "[base][ovr]overlay=0:0"
                } else {
                    filterGraph += "[1:v][0:v]scale2ref=w=iw:h=ih[ovr][base];"
                    filterGraph += "[base][ovr]overlay=0:0"
                }

                var ffmpegCommand: [String] = []

                if let start = startTime {
                    ffmpegCommand += ["-ss", "\(start)"]
                }

                if let end = endTime {
                    ffmpegCommand += ["-to", "\(end)"]
                }

                ffmpegCommand += [
                    "-y",
                    "-i", videoURL.path,
                    "-i", imageURL.path,
                    "-filter_complex", filterGraph,
                    "-c:v", "libx264",
                    "-preset", preset,
                    "-crf", "\(constantRateFactor)",
                    "-pix_fmt", "yuv420p",
                    "-c:a", "copy",
                    outputURL.path
                ]

                let command = ffmpegCommand.joined(separator: " ")
                print("FFmpeg command: \(command)")
                
                FFmpegKit.executeAsync(command, withCompleteCallback: { session in
                    let returnCode = session?.getReturnCode()
                    
                    if ReturnCode.isSuccess(returnCode) {
                        DispatchQueue.main.async {
                            onSuccess(outputURL.path)
                        }
                    } else {
                        let failMessage = session?.getFailStackTrace() ?? "Unknown error"
                        DispatchQueue.main.async {
                            onError("FFmpeg failed: \(failMessage)")
                        }
                    }
                }, withLogCallback: { log in
                    if let logMessage = log?.getMessage() {
                        print(logMessage)
                    }
                }, withStatisticsCallback: { stat in
                    guard let time = stat?.getTime() else { return }
                    let trimmedDuration: Int = {
                        if let start = startTime, let end = endTime {
                            return max((end - start) * 1000, 1)
                        } else if let start = startTime {
                            return videoDuration - start * 1000
                        } else if let end = endTime {
                            return end * 1000
                        } else {
                            return videoDuration
                        }
                    }()
                    
                    if trimmedDuration > 0 && time > 0 {
                        let progress = Double(time) / Double(trimmedDuration)
                        DispatchQueue.main.async {
                            onProgress?(min(max(progress, 0.0), 1.0))
                        }
                    }
                })
                
            } catch {
                DispatchQueue.main.async {
                    onError("Exception: \(error.localizedDescription)")
                }
            }
        }
    }
}
