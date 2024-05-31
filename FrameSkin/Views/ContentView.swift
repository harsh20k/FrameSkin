import SwiftUI
import AVFoundation
import RealmSwift

struct ContentView: View {
    @StateObject private var realmManager = RealmManager()
    @StateObject private var shortcutManager = ShortcutManager()
    @State private var selectedFrameImage: UIImage?
    @State private var frameImages: [UIImage] = []
    @State private var logs: [String] = []
    @State private var drawings: [Int: Path] = [:]
    @State private var currentDrawing: Path = Path()
    @State private var currentIndex: Int = 0
    @State private var isPlaying: Bool = false
    @State private var timer: Timer?
    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                CanvasView(selectedFrameImage: $selectedFrameImage, drawings: $drawings, currentDrawing: $currentDrawing, currentIndex: $currentIndex) {
                    saveDrawing()
                }

                FrameListView(frameImages: $frameImages, selectedFrameImage: $selectedFrameImage, currentIndex: $currentIndex) { index in
                    loadDrawings(for: index)
                    log("Frame \(index) selected")
                }

                Spacer()
                LogView(logs: $logs)
                    .frame(maxWidth: .infinity, maxHeight: 200)
            }
            .overlay(
                ControlView(isPlaying: $isPlaying, startAnimation: startAnimation, stopAnimation: stopAnimation)
            )
            .onAppear {
                loadFrames()
            }
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        Button(action: togglePlayPause) {
                            EmptyView()
                        }
                        .keyboardShortcut(shortcutManager.keyEquivalent(for: "playPause"), modifiers: [])
                        
                        Button(action: nextFrame) {
                            EmptyView()
                        }
                        .keyboardShortcut(shortcutManager.keyEquivalent(for: "nextFrame"), modifiers: [])
                        
                        Button(action: previousFrame) {
                            EmptyView()
                        }
                        .keyboardShortcut(shortcutManager.keyEquivalent(for: "previousFrame"), modifiers: [])
                    }
                }
            )
            .navigationBarTitle("FrameSkin", displayMode: .inline)
            .navigationBarItems(leading: Button(action: {
                showingSettings.toggle()
            }) {
                Text("Settings")
            })
            .sheet(isPresented: $showingSettings) {
                ShortcutSettingsView(shortcutManager: shortcutManager)
            }
        }
    }

    private func togglePlayPause() {
        isPlaying.toggle()
        if isPlaying {
            startAnimation()
        } else {
            stopAnimation()
        }
    }

    private func nextFrame() {
        currentIndex = min(currentIndex + 1, frameImages.count - 1)
        selectedFrameImage = frameImages[currentIndex]
        loadDrawings(for: currentIndex)
    }

    private func previousFrame() {
        currentIndex = max(currentIndex - 1, 0)
        selectedFrameImage = frameImages[currentIndex]
        loadDrawings(for: currentIndex)
    }

    private func loadFrames() {
        log("Loading frames...")
        guard let project = realmManager.projects.first, let scene = project.scenes.first else {
            log("No project or scene found")
            return
        }

        if let videoTrack = scene.tracks.first(where: { $0.type == .video }) {
            log("Video track found")
            if (videoTrack.frames.isEmpty) {
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
        
        let frameExtractor = FrameExtractor(videoURL: url)
        frameExtractor.extractFrames(frameCount: 30) { images in
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
    }
    
    private func saveDrawing() {
        log("Saving drawing for frame \(currentIndex)...")
        guard let drawingPath = drawings[currentIndex] else {
            log("No drawing to save for frame \(currentIndex)")
            return
        }
        guard let drawingData = drawingPath.toJSON()?.data(using: .utf8) else {
            log("Failed to serialize drawing to JSON")
            return
        }
        realmManager.addDrawingDataToTrack(drawingData: drawingData, frameIndex: currentIndex)
        log("Drawing saved for frame \(currentIndex)")
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

        if let drawingData = frame.drawingData, let drawingJSON = String(data: drawingData, encoding: .utf8) {
            drawings[frameIndex] = Path(json: drawingJSON)
            log("Loaded drawing for frame \(frameIndex)")
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
        Logger.log(message)
        logs.append(message)
    }
}
