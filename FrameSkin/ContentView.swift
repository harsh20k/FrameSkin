import SwiftUI
import RealmSwift

struct ContentView: View {
    @StateObject private var realmManager = RealmManager()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(realmManager.projects, id: \.self) { project in
                    NavigationLink(destination: ProjectDetailView(project: project)) {
                        Text(project.title)
                    }
                }
            }
            .navigationTitle("Projects")
        }
    }
}

struct ProjectDetailView: View {
    @ObservedRealmObject var project: FrameSkinProject
    
    var body: some View {
        VStack {
            Text(project.title)
                .font(.title)
            List {
                ForEach(project.scenes, id: \.self) { scene in
                    SceneRowView(scene: scene)
                }
            }
        }
        .navigationTitle("Project Detail")
    }
}

struct SceneRowView: View {
    @ObservedRealmObject var scene: FrameSkinScene
    @State private var selectedFrame: FrameSkinFrame?
    
    var body: some View {
        VStack {
            Text(scene.title)
            List {
                ForEach(scene.tracks, id: \.self) { track in
                    TrackRowView(track: track, selectedFrame: $selectedFrame)
                }
            }
            if let frame = selectedFrame {
                DrawingView(frame: frame)
            }
        }
    }
}

struct TrackRowView: View {
    @ObservedRealmObject var track: FrameSkinTrack
    @Binding var selectedFrame: FrameSkinFrame?
    
    var body: some View {
        VStack {
            Text(track.title)
            if track.type == .video {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(track.frames, id: \.self) { frame in
                            Image(uiImage: UIImage(data: frame.frameData) ?? UIImage())
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .onTapGesture {
                                    selectedFrame = frame
                                }
                        }
                    }
                }
            }
        }
    }
}

struct DrawingView: View {
    @ObservedRealmObject var frame: FrameSkinFrame
    @State private var currentDrawing: Drawing = Drawing()
    
    var body: some View {
        VStack {
            Text("Drawing on Frame \(frame.frameIndex)")
            Canvas { context, size in
                for line in currentDrawing.lines {
                    var path = Path()
                    path.addLines(line.points)
                    context.stroke(path, with: .color(line.color), lineWidth: line.lineWidth)
                }
            }
            .gesture(DragGesture(minimumDistance: 0.1)
                .onChanged { value in
                    let newPoint = value.location
                    currentDrawing.addPoint(newPoint)
                }
                .onEnded { _ in
                    saveDrawing()
                })
        }
    }
    
    private func saveDrawing() {
        // Convert currentDrawing to Data and save to frame.drawingData
        if let drawingData = try? JSONEncoder().encode(currentDrawing) {
            try? frame.realm?.write {
                frame.drawingData = drawingData
            }
        }
    }
}

struct Drawing: Codable {
    var lines: [Line] = []
    
    mutating func addPoint(_ point: CGPoint) {
        if lines.isEmpty {
            lines.append(Line(points: [point]))
        } else {
            lines[lines.count - 1].points.append(point)
        }
    }
}

struct Line: Codable {
    var points: [CGPoint]
    var color: Color = .black
    var lineWidth: CGFloat = 2.0
    
    enum CodingKeys: String, CodingKey {
        case points
        case color
        case lineWidth
    }
    
    init(points: [CGPoint], color: Color = .black, lineWidth: CGFloat = 2.0) {
        self.points = points
        self.color = color
        self.lineWidth = lineWidth
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        points = try container.decode([CGPoint].self, forKey: .points)
        color = try container.decode(Color.self, forKey: .color)
        lineWidth = try container.decode(CGFloat.self, forKey: .lineWidth)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(points, forKey: .points)
        try container.encode(color, forKey: .color)
        try container.encode(lineWidth, forKey: .lineWidth)
    }
}

extension CGPoint: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let x = try container.decode(CGFloat.self)
        let y = try container.decode(CGFloat.self)
        self.init(x: x, y: y)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(x)
        try container.encode(y)
    }
}

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
