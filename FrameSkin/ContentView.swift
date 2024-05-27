import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var selectedFrameImage: UIImage?
    @State private var frameImages: [UIImage] = []
    @State private var logs: [String] = []
    @State private var currentDrawing: Path = Path()
    @State private var drawings: [Path] = []

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
                            extractFrames()
                        }
                }

                // Drawing Canvas
                Canvas { context, size in
                    for drawing in drawings {
                        context.stroke(drawing, with: .color(.white), lineWidth: 2)
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
                                drawings.append(currentDrawing)
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
                                .onTapGesture {
                                    selectedFrameImage = frameImages[index]
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
    }

    private func extractFrames() {
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
                    frameRate = Double(videoTrack.nominalFrameRate)
                    log("Frame rate loaded: \(frameRate) fps")
                }

                let frameCount = 5
                let frameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
                let times: [NSValue] = (0..<frameCount).map { i in
                    let time = CMTimeMultiply(frameDuration, multiplier: Int32(i))
                    return NSValue(time: time)
                }

                log("Extracting \(frameCount) frames")

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

                DispatchQueue.main.async {
                    frameImages = images
                    if let firstImage = images.first {
                        selectedFrameImage = firstImage
                        log("Initial frame set for display")
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
    
    private func log(_ message: String) {
        DispatchQueue.main.async {
            logs.append(message)
            print(message)  // Also print to console for debugging
        }
    }
}


