import SwiftUI

struct FrameListView: View {
    @Binding var tracks: [FrameSkinTrack]
    @Binding var selectedFrameImage: UIImage?
    @Binding var currentTrackIndex: Int
    @Binding var currentFrameIndex: Int
    let onSelectFrame: (Int, Int) -> Void

    var body: some View {
        VStack {
            ForEach(tracks.indices, id: \.self) { trackIndex in
                if !tracks[trackIndex].frames.isEmpty {
                    VStack(alignment: .leading) {
                        Text(tracks[trackIndex].title)
                            .font(.headline)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(tracks[trackIndex].frames.indices, id: \.self) { frameIndex in
                                    let frame = tracks[trackIndex].frames[frameIndex]
                                    FrameView(frame: frame, trackType: tracks[trackIndex].type)
                                        .frame(width: 60, height: 60)
                                        .shadow(color: (currentTrackIndex == trackIndex && currentFrameIndex == frameIndex) ? .white : .clear, radius: 20)
                                        .onTapGesture {
                                            if tracks[trackIndex].type == .video, let frameData = frame.frameData {
                                                selectedFrameImage = UIImage(data: frameData)
                                            } else {
                                                selectedFrameImage = nil
                                            }
                                            currentTrackIndex = trackIndex
                                            currentFrameIndex = frameIndex
                                            onSelectFrame(trackIndex, frameIndex)
                                        }
                                }
                            }
                            .padding()
                        }
                    }
                    .padding(.bottom, 10)
                }
            }
        }
    }
}

struct FrameView: View {
    let frame: FrameSkinFrame
    let trackType: TrackType

    var body: some View {
        switch trackType {
        case .video:
            if let frameData = frame.frameData, let uiImage = UIImage(data: frameData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Color.gray
            }
        case .drawing:
            if let drawingData = frame.drawingData, let drawingJSON = String(data: drawingData, encoding: .utf8), let drawingPath = Path(json: drawingJSON) {
                Canvas { context, size in
                    context.stroke(drawingPath, with: .color(.black), lineWidth: 2)
                }
                .background(Color.white.opacity(0.1))
            } else {
                Color.gray
            }
        case .audio:
            EmptyView()
        }
    }
}
