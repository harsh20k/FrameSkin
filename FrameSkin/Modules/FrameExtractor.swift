import Foundation
import AVFoundation
import UIKit

class FrameExtractor {
    let videoURL: URL
    
    init(videoURL: URL) {
        self.videoURL = videoURL
    }
    
    func extractFrames(frameCount: Int, completion: @escaping ([UIImage]) -> Void) {
        let asset = AVAsset(url: videoURL)
        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImageGenerator.appliesPreferredTrackTransform = true
        assetImageGenerator.maximumSize = CGSize(width: 300, height: 300) // Scale down the image size
        assetImageGenerator.requestedTimeToleranceBefore = .zero
        assetImageGenerator.requestedTimeToleranceAfter = .zero

        Task {
            do {
               // let duration = try await asset.load(.duration)
                let tracks = try await asset.load(.tracks)

                var frameRate: Double = 30.0
                if let videoTrack = tracks.first(where: { $0.mediaType == .video }) {
                    frameRate = try await Double(videoTrack.load(.nominalFrameRate))
                }

                let frameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
                let times: [NSValue] = (0..<frameCount).map { i in
                    let time = CMTimeMultiply(frameDuration, multiplier: Int32(i))
                    return NSValue(time: time)
                }

                DispatchQueue.main.async {
                    var images: [UIImage] = []
                    for time in times {
                        do {
                            let cgImage = try assetImageGenerator.copyCGImage(at: time.timeValue, actualTime: nil)
                            let uiImage = UIImage(cgImage: cgImage)
                            images.append(uiImage)
                        } catch {
                            print("Error extracting frame at time \(time.timeValue.seconds): \(error)")
                        }
                    }
                    completion(images)
                }
            } catch {
                print("Error loading asset properties: \(error)")
                completion([])
            }
        }
    }
}
