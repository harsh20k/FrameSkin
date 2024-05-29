import Foundation
import RealmSwift

class RealmManager: ObservableObject {
    private(set) var realm: Realm
    @Published var projects: Results<FrameSkinProject>
    
    init() {
        realm = try! Realm()
        projects = realm.objects(FrameSkinProject.self)
        addDummyData()
    }
    
    func addDummyData() {
        guard projects.isEmpty else { return }
        
        let project = FrameSkinProject()
        project.title = "Sample Project"
        project.projectDescription = "This is a sample project."
        project.createdDate = Date()
        project.lastModifiedDate = Date()
        project.version = 1
        project.createdBy = "User"
        project.tags.append(objectsIn: ["sample", "test"])
        project.thumbnail = Data()
        
        let scene = FrameSkinScene()
        scene.title = "Sample Scene"
        
        project.scenes.append(scene)
        
        try! realm.write {
            realm.add(project)
        }
    }
    
    func addFramesToProject(frames: [Data]) {
        guard let project = projects.first else { return }
        
        let videoTrack = FrameSkinTrack()
        videoTrack.title = "Video Track"
        videoTrack.type = .video
        videoTrack.position = 1
        
        for (index, frameData) in frames.enumerated() {
            let frame = FrameSkinFrame()
            frame.frameIndex = index
            frame.frameData = frameData
            videoTrack.frames.append(frame)
        }
        
        let drawingTrack = FrameSkinTrack()
        drawingTrack.title = "Drawing Track"
        drawingTrack.type = .drawing
        drawingTrack.position = 2
        
        if let scene = project.scenes.first {
            try! realm.write {
                scene.tracks.append(videoTrack)
                scene.tracks.append(drawingTrack)
            }
        }
    }
    
    func addDrawingDataToTrack(drawingData: Data, frameIndex: Int) {
        guard let project = projects.first,
              let scene = project.scenes.first,
              let drawingTrack = scene.tracks.first(where: { $0.type == .drawing }) else { return }
        
        if let frame = drawingTrack.frames.first(where: { $0.frameIndex == frameIndex }) {
            try! realm.write {
                frame.drawingData = drawingData
            }
        } else {
            let frame = FrameSkinFrame()
            frame.frameIndex = frameIndex
            frame.drawingData = drawingData
            try! realm.write {
                drawingTrack.frames.append(frame)
            }
        }
    }
}
