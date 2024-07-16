import SwiftUI
import AVFoundation
import RealmSwift

struct ContentView: View {
    @StateObject internal var realmManager = RealmManager()
    @StateObject internal var shortcutManager = ShortcutManager()
    @State internal var selectedFrameImage: UIImage?
    @State internal var tracks: [FrameSkinTrack] = []
    @State internal var frameImages: [UIImage] = []
    @State internal var logs: [String] = []
    @State internal var drawings: [Int: Path] = [:]
    @State internal var currentDrawing: Path = Path()
    @State internal var currentTrackIndex: Int = 0
    @State internal var currentFrameIndex: Int = 0
    @State internal var isPlaying: Bool = false
    @State internal var timer: Timer?
    @State internal var showingSettings = false

    var body: some View {
        VStack {
//            Button(action: {
//                   // Action to perform when the button is tapped
//                showingSettings = true
//                 }) {
//                   Label("Show Some Love!", systemImage: "heart.fill")
//                     .padding()
//                     .foregroundColor(.white)
//                     .background(Color.blue)
//                     .cornerRadius(10)
//                 }
            Spacer()
            CanvasView(selectedFrameImage: $selectedFrameImage, drawings: $drawings, currentDrawing: $currentDrawing, currentIndex: $currentFrameIndex) {
                saveDrawing()
            }
            
            FrameListView(tracks: $tracks, selectedFrameImage: $selectedFrameImage, currentTrackIndex: $currentTrackIndex, currentFrameIndex: $currentFrameIndex) { trackIndex, frameIndex in
                loadDrawings(for: trackIndex, frameIndex: frameIndex)
                log("Track \(trackIndex), Frame \(frameIndex) selected")
            }
            
            Spacer()
            LogView(logs: $logs)
                .frame(maxWidth: .infinity, maxHeight: 200)
        }
        .overlay(
            ControlView(isPlaying: $isPlaying, startAnimation: startAnimation, stopAnimation: stopAnimation)
        )
        .onAppear {
            loadTracks()
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
