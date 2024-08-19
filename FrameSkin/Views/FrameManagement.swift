import SwiftUI
import AVFoundation

extension OpenProjectView {
		/// Loads the tracks of the given project into the `tracks` array and sets the initial frame image.
		/// - Parameter project: The project whose tracks need to be loaded.
	func loadTracks(project: FrameSkinProject) {
		log("Loading tracks...")
		
			// Fetching the first scene of the selected project
		guard let scene = project.scenes.first else {
			log("No project or scene found")
			return
		}
		
		tracks = Array(scene.tracks)
		log("The number of tracks in the scene are: \(scene.tracks.count)")
		if let firstTrack = tracks.first,
			let firstFrame = firstTrack.frames.first,
			let frameData = firstFrame.frameData,
			let uiImage = UIImage(data: frameData) {
			selectedFrameImage = uiImage
			currentTrackIndex = 0
			currentFrameIndex = 0
			log("Loaded \(tracks.count) tracks with track id \(firstTrack.id) with frameid \(firstFrame.id)")
			loadDrawings(for: 0, frameIndex: 0)
		} else {
			log("No frames found in tracks")
		}
	}
	
//		/// Extracts frames from a sample video and adds them to the project.
//	func extractFrames() {
//		log("Extracting frames from video...")
//		guard let url = Bundle.main.url(forResource: "sample", withExtension: "mp4") else {
//			fatalError("Video file not found")
//		}
//		
//		let frameExtractor = FrameExtractor(videoURL: url)
//		frameExtractor.extractFrames(frameCount: 30) { images in
//			frameImages = images
//			if let firstImage = images.first {
//				selectedFrameImage = firstImage
//				currentFrameIndex = 0
//				log("Initial frame set for display")
//				let frameDataArray = images.map { $0.pngData()! }
//				realmManager.addFramesToProject(frames: frameDataArray)
//			} else {
//				log("No frames extracted")
//			}
//			
//			let totalSizeInBytes = images.reduce(0) { $0 + ($1.jpegData(compressionQuality: 1)?.count ?? 0) }
//			let totalSizeInMB = Double(totalSizeInBytes) / 1_048_576
//			log("Total size of image collection: \(String(format: "%.2f", totalSizeInMB)) MB")
//		}
//	}
		/// Saves the current drawing to the Realm database.
//	func saveDrawing() {
//		log("Saving drawing for track \(currentTrackIndex), frame \(currentFrameIndex)...")
//		guard let drawingPath = drawings[currentFrameIndex] else {
//			log("No drawing to save for frame \(currentFrameIndex)")
//			return
//		}
//		guard let drawingData = drawingPath.toJSON()?.data(using: .utf8) else {
//			log("Failed to serialize drawing to JSON")
//			return
//		}
//		realmManager.addDrawingDataToTrack(drawingData: drawingData, frameIndex: currentFrameIndex)
//		log("Drawing saved for track \(currentTrackIndex), frame \(currentFrameIndex)")
//	}
	
	func saveDrawing() {
		log("Saving drawing for track \(currentTrackIndex), frame \(currentFrameIndex)...")
		guard let drawingPath = drawings[currentFrameIndex] else {
			log("No drawing to save for frame \(currentFrameIndex)")
			return
		}
		guard let drawingData = drawingPath.toJSON()?.data(using: .utf8) else {
			log("Failed to serialize drawing to JSON")
			return
		}
		
		let currentTrack = tracks[currentTrackIndex]
		realmManager.addDrawingDataToTrack(drawingData: drawingData, frameIndex: currentFrameIndex, trackId: currentTrack.id)
		log("Drawing saved for track \(currentTrackIndex), frame \(currentFrameIndex) in track \(currentTrack.id)")
	}
		/// Loads the drawing data for the specified track and frame index.
		/// - Parameters:
		///   - trackIndex: The index of the track.
		///   - frameIndex: The index of the frame.
	func loadDrawings(for trackIndex: Int, frameIndex: Int) {
//		log("Loading drawings for track \(trackIndex), frame \(frameIndex)...")
		
		guard let scene = project.scenes.first,
			  let drawingTrack = scene.tracks.first(where: { $0.type == .drawing }),
			  let frame = drawingTrack.frames.first(where: { $0.frameIndex == frameIndex }) else {
			log("No drawings found for track \(trackIndex), frame \(frameIndex)")
			return
		}
		
		if let drawingData = frame.drawingData, let drawingJSON = String(data: drawingData, encoding: .utf8) {
			drawings[frameIndex] = Path(json: drawingJSON)
//			log("Loaded drawing for track \(trackIndex), frame \(frameIndex)")
		} else {
			log("No drawing data found for track \(trackIndex), frame \(frameIndex)")
		}
	}
	
		/// Starts the animation by cycling through the frames at a specified interval.
	func startAnimation() {
		log("Starting animation...")
		timer = Timer.scheduledTimer(withTimeInterval: 3.0 / 30.0, repeats: true) { _ in
			currentFrameIndex = (currentFrameIndex + 1) % tracks[currentTrackIndex].frames.count
			if let frameData = tracks[currentTrackIndex].frames[currentFrameIndex].frameData,
			   let uiImage = UIImage(data: frameData) {
				selectedFrameImage = uiImage
				loadDrawings(for: currentTrackIndex, frameIndex: currentFrameIndex)
			}
		}
	}
	
		/// Stops the animation by invalidating the timer.
	func stopAnimation() {
		log("Stopping animation...")
		timer?.invalidate()
		timer = nil
	}
	
		/// Toggles the play/pause state of the animation.
	func togglePlayPause() {
		isPlaying.toggle()
		if isPlaying {
			startAnimation()
		} else {
			stopAnimation()
		}
	}
	
		/// Advances to the next frame.
	func nextFrame() {
		currentFrameIndex = min(currentFrameIndex + 1, tracks[currentTrackIndex].frames.count - 1)
		if let frameData = tracks[currentTrackIndex].frames[currentFrameIndex].frameData,
		   let uiImage = UIImage(data: frameData) {
			selectedFrameImage = uiImage
			loadDrawings(for: currentTrackIndex, frameIndex: currentFrameIndex)
		}
	}
	
		/// Moves to the previous frame.
	func previousFrame() {
		currentFrameIndex = max(currentFrameIndex - 1, 0)
		if let frameData = tracks[currentTrackIndex].frames[currentFrameIndex].frameData,
		   let uiImage = UIImage(data: frameData) {
			selectedFrameImage = uiImage
			loadDrawings(for: currentTrackIndex, frameIndex: currentFrameIndex)
		}
	}
	
		/// Logs a message to the console and the local log array.
		/// - Parameter message: The message to log.
	func log(_ message: String) {
		Logger.log(message)
		logs.append(message)
	}
}
