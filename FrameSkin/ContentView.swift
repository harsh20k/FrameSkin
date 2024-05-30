import SwiftUI
import AVFoundation
import RealmSwift

struct ContentView: View {
    @StateObject private var realmManager = RealmManager()
    @State private var selectedFrameImage: UIImage?
    @State private var frameImages: [UIImage] = []
    @State private var logs: [String] = []
    @State private var drawings: [Int: Path] = [:]
    @State private var currentDrawing: Path = Path()
    @State private var currentIndex: Int = 0
    @State private var isPlaying: Bool = false
    @State private var timer: Timer?

    var body: some View {
        VStack {
            Spacer()
            ZStack {
                if let selectedFrameImage = selectedFrameImage {
                    Image(uiImage: selectedFrameImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 600, height: 600)
                } else {
                    Text("Loading...")
                        .onAppear {
                            loadFrames()
                        }
                }

                // Drawing Canvas
                Canvas { context, size in
                    if let frameDrawing = drawings[currentIndex] {
                        context.stroke(frameDrawing, with: .color(.white), lineWidth: 2)
                    }
                    context.stroke(currentDrawing, with: .color(.white), lineWidth: 2)
                }
                .frame(width: 600, height: 600)
                .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .onChanged { value in
                                if currentDrawing.isEmpty {
                                    currentDrawing.move(to: value.location)
                                } else {
                                    currentDrawing.addLine(to: value.location)
                                }
                            }
                            .onEnded { value in
                                if drawings[currentIndex] == nil {
                                    drawings[currentIndex] = Path()
                                }
                                drawings[currentIndex]?.addPath(currentDrawing)
                                saveDrawing()
                                currentDrawing = Path()
                            })
            }

            if !frameImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(frameImages.indices, id: \.self) { index in
                            Image(uiImage: frameImages[index])
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .shadow(color: currentIndex == index ? .white : .clear, radius: 20)
                                .onTapGesture {
                                    selectedFrameImage = frameImages[index]
                                    currentIndex = index
                                    loadDrawings(for: index)
                                    log("Frame \(index) selected")
                                }
                        }
                    }
                    .padding()
                }
            }
            Spacer()
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(logs, id: \.self) { log in
                        Text(log)
                            .foregroundColor(.white)
                            .font(.footnote)
                    }
                }
            }
            .frame(maxHeight: 100)
            .background(Color.black)
            .padding(.top, 10)
        }
        .overlay(
            VStack {
                Spacer()
                Button(action: {
                    isPlaying.toggle()
                    if isPlaying {
                        startAnimation()
                    } else {
                        stopAnimation()
                    }
                }) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .padding()
                        .background(Color.white)
                        .clipShape(Circle())
                }
                .padding()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        )
    }

    private func loadFrames() {
        log("Loading frames...")
        guard let project = realmManager.projects.first, let scene = project.scenes.first else {
            log("No project or scene found")
            return
        }

        if let videoTrack = scene.tracks.first(where: { $0.type == .video }) {
            log("Video track found")
            if videoTrack.frames.isEmpty {
                log("Video track found but contains no frames, extracting frames...")
                extractFrames()
            } else {
                log("Loading frames from existing video track")
                frameImages = videoTrack.frames.compactMap { UIImage(data: $0.frameData ?? Data()) }
                selectedFrameImage = frameImages.first
                currentIndex = 0
                log("Loaded \(frameImages.count) frames from existing video track")
                loadDrawings(for: 0)
            }
        } else {
            log("No video track found, extracting frames...")
            extractFrames()
        }
    }

    private func extractFrames() {
        log("Extracting frames from video...")
        guard let url = Bundle.main.url(forResource: "sample", withExtension: "mp4") else {
            log("Video file not found")
            return
        }
        
        log("Video file found: \(url)")

        let asset = AVAsset(url: url)
        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImageGenerator.appliesPreferredTrackTransform = true
        assetImageGenerator.maximumSize = CGSize(width: 300, height: 300) // Scale down the image size
        assetImageGenerator.requestedTimeToleranceBefore = .zero
        assetImageGenerator.requestedTimeToleranceAfter = .zero

        Task {
            do {
                let duration = try await asset.load(.duration)
                let tracks = try await asset.load(.tracks)
                
                log("Duration loaded: \(CMTimeGetSeconds(duration)) seconds")

                var frameRate: Double = 30.0
                if let videoTrack = tracks.first(where: { $0.mediaType == .video }) {
                    frameRate = try await Double(videoTrack.load(.nominalFrameRate))
                    log("Frame rate loaded: \(frameRate) fps")
                }

                let frameCount = 30
                let frameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate))

                log("Extracting \(frameCount) frames")

                DispatchQueue.main.async {
                    let times: [NSValue] = (0..<frameCount).map { i in
                        let time = CMTimeMultiply(frameDuration, multiplier: Int32(i))
                        return NSValue(time: time)
                    }
                    var images: [UIImage] = []
                    for time in times {
                        do {
                            let cgImage = try assetImageGenerator.copyCGImage(at: time.timeValue, actualTime: nil)
                            let uiImage = UIImage(cgImage: cgImage)
                            images.append(uiImage)
                            log("Frame extracted at time: \(time.timeValue.seconds)")
                        } catch {
                            log("Error extracting frame at time \(time.timeValue.seconds): \(error)")
                        }
                    }
                    frameImages = images
                    if let firstImage = images.first {
                        selectedFrameImage = firstImage
                        currentIndex = 0
                        log("Initial frame set for display")
                        realmManager.addFramesToProject(frames: images.map { $0.pngData()! })
                    } else {
                        log("No frames extracted")
                    }
                    let totalSizeInBytes = images.reduce(0) { $0 + ($1.jpegData(compressionQuality: 1)?.count ?? 0) }
                    let totalSizeInMB = Double(totalSizeInBytes) / 1_048_576
                    log("Total size of image collection: \(String(format: "%.2f", totalSizeInMB)) MB")
                }
            } catch {
                log("Error loading asset properties: \(error)")
            }
        }
    }
    
    private func saveDrawing() {
        log("Saving drawing for frame \(currentIndex)...")
        guard let drawingPath = drawings[currentIndex] else {
            log("No drawing to save for frame \(currentIndex)")
            return
        }
        do {
            let drawingData = try NSKeyedArchiver.archivedData(withRootObject: drawingPath, requiringSecureCoding: false)
            realmManager.addDrawingDataToTrack(drawingData: drawingData, frameIndex: currentIndex)
            log("Drawing saved for frame \(currentIndex)")
        } catch {
            log("Failed to save drawing for frame \(currentIndex): \(error)")
        }
    }

    private func loadDrawings(for frameIndex: Int) {
        log("Loading drawings for frame \(frameIndex)...")
        guard let project = realmManager.projects.first,
              let scene = project.scenes.first,
              let drawingTrack = scene.tracks.first(where: { $0.type == .drawing }),
              let frame = drawingTrack.frames.first(where: { $0.frameIndex == frameIndex }) else {
            log("No drawings found for frame \(frameIndex)")
            return
        }

        if let drawingData = frame.drawingData {
            do {
                if let path = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(drawingData) as? Path {
                    drawings[frameIndex] = path
                    log("Loaded drawing for frame \(frameIndex)")
                } else {
                    log("Failed to unarchive drawing for frame \(frameIndex)")
                }
            } catch {
                log("Error unarchiving drawing for frame \(frameIndex): \(error)")
            }
        } else {
            log("No drawing data found for frame \(frameIndex)")
        }
    }
    
    private func startAnimation() {
        log("Starting animation...")
        timer = Timer.scheduledTimer(withTimeInterval: 3.0 / 30.0, repeats: true) { _ in
            currentIndex = (currentIndex + 1) % frameImages.count
            selectedFrameImage = frameImages[currentIndex]
            loadDrawings(for: currentIndex)
        }
    }

    private func stopAnimation() {
        log("Stopping animation...")
        timer?.invalidate()
        timer = nil
    }

    private func log(_ message: String) {
        DispatchQueue.main.async {
            logs.append(message)
            print(message)  // Also print to console for debugging
        }
    }
}


