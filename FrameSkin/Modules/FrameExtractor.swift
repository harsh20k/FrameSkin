import Foundation
import AVFoundation
import UIKit

class FrameExtractor {
	let videoURL: URL
	
	init(videoURL: URL) {
		self.videoURL = videoURL
	}
	
	func extractFrames(frameCount: Int) -> [UIImage] {
		let asset = AVAsset(url: videoURL)
		let assetImageGenerator = AVAssetImageGenerator(asset: asset)
		assetImageGenerator.appliesPreferredTrackTransform = true
		assetImageGenerator.maximumSize = CGSize(width: 300, height: 300) // Scale down the image size
		assetImageGenerator.requestedTimeToleranceBefore = .zero
		assetImageGenerator.requestedTimeToleranceAfter = .zero
		
		var images: [UIImage] = []
		let semaphore = DispatchSemaphore(value: 0)
		
		let duration = asset.duration
		let frameDuration = CMTime(value: 1, timescale: CMTimeScale(30)) // Assuming 30 fps
		let times: [NSValue] = (0..<frameCount).map { i in
			let time = CMTimeMultiply(frameDuration, multiplier: Int32(i))
			return NSValue(time: time)
		}
		
		for time in times {
			do {
				let cgImage = try assetImageGenerator.copyCGImage(at: time.timeValue, actualTime: nil)
				let uiImage = UIImage(cgImage: cgImage)
				images.append(uiImage)
			} catch {
				print("Error extracting frame at time \(time.timeValue.seconds): \(error)")
			}
		}
		semaphore.signal()
		
		semaphore.wait()
		return images
	}
}
