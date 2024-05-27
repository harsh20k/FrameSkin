import SwiftUI
import PhotosUI
import AVFoundation
import os

// Logger for logging events
let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "VideoFrameExtractor")

// ViewModel to handle frame extraction logic
class VideoFramesExtractor: ObservableObject {
    @Published var frames: [UIImage] = []
    
    func extractFrames(from videoURL: URL) {
        logger.log("Started frame extraction from video URL: \(videoURL.absoluteString)")
        
        let asset = AVAsset(url: videoURL)
        asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            var error: NSError?
            let status = asset.statusOfValue(forKey: "duration", error: &error)
            if status == .loaded {
                let duration = CMTimeGetSeconds(asset.duration)
                let fps: Double = 30 // Assuming 30 frames per second
                let frameCount = Int(duration * fps)
                
                logger.log("Video duration: \(duration) seconds, frame count: \(frameCount)")
                
                var times: [CMTime] = []
                for i in 0..<frameCount {
                    let time = CMTimeMake(value: Int64(i), timescale: Int32(fps))
                    times.append(time)
                }
                
                let imageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true
                
                DispatchQueue.global(qos: .userInitiated).async {
                    self.generateFramesSynchronously(imageGenerator: imageGenerator, times: times)
                }
            } else {
                logger.error("Failed to load duration: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func generateFramesSynchronously(imageGenerator: AVAssetImageGenerator, times: [CMTime]) {
        var extractedFrames: [UIImage] = []
        
        for time in times {
            do {
                let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                let image = UIImage(cgImage: cgImage)
                extractedFrames.append(image)
//                logger.log("Added frame for time \(time) to frames array. Total frames: \(extractedFrames.count)")
            } catch {
//                logger.error("Error generating image at time \(time): \(error.localizedDescription)")
            }
        }
        
        DispatchQueue.main.async {
            self.frames = extractedFrames
        }
    }
}

// Main view of the app
struct ContentView: View {
    @State private var isPickerPresented: Bool = false
    @StateObject private var extractor = VideoFramesExtractor()
    
    var body: some View {
        VStack {
            Button(action: {
                isPickerPresented.toggle()
                logger.log("Import Video button tapped")
            }) {
                Text("Import Video")
                    .font(.title)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(extractor.frames, id: \.self) { frame in
                        Image(uiImage: frame)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .padding(2)
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $isPickerPresented) {
            PhotoPicker(extractor: extractor)
        }
        .onAppear {
            logger.log("ContentView appeared")
        }
    }
}

// Photo picker for importing video
struct PhotoPicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    var extractor: VideoFramesExtractor
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            logger.log("Picker didFinishPicking with results: \(results.count)")
            
            if let result = results.first {
                result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                    if let error = error {
                        logger.error("Error loading file representation: \(error.localizedDescription)")
                        return
                    }
                    
                    if let url = url {
                        DispatchQueue.main.async {
                            logger.log("Selected video URL: \(url.absoluteString)")
                            self.parent.extractor.extractFrames(from: url)
                        }
                    }
                }
            } else {
                logger.log("No video selected")
            }
        }
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .videos
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        logger.log("PHPickerViewController created")
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
}

