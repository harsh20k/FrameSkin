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

        log("Adding dummy data...")
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
        log("Dummy data added")
    }
    
    func addFramesToProject(frames: [Data]) {
        log("Adding frames to project...")
        guard let project = projects.first else {
            log("No project found")
            return
        }
        
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
        
        if let scene = project.scenes.first {
            try! realm.write {
                if scene.tracks.first(where: { $0.type == .video }) == nil {
                    scene.tracks.append(videoTrack)
                    log("Video track added")
                }
                if scene.tracks.first(where: { $0.type == .drawing }) == nil {
                    let drawingTrack = FrameSkinTrack()
                    drawingTrack.title = "Drawing Track"
                    drawingTrack.type = .drawing
                    drawingTrack.position = scene.tracks.count + 1
                    scene.tracks.append(drawingTrack)
                    log("Drawing track added")
                }
            }
        }
        log("Frames added to project")
    }
    
    func addDrawingDataToTrack(drawingData: Data, frameIndex: Int) {
        log("Adding drawing data to track...")
        guard let project = projects.first,
              let scene = project.scenes.first,
              let drawingTrack = scene.tracks.first(where: { $0.type == .drawing }) else {
            log("No project, scene, or drawing track found")
            return
        }
        
        if let frame = drawingTrack.frames.first(where: { $0.frameIndex == frameIndex }) {
            try! realm.write {
                frame.drawingData = drawingData
            }
            log("Drawing data updated for frame \(frameIndex)")
        } else {
            let frame = FrameSkinFrame()
            frame.frameIndex = frameIndex
            frame.drawingData = drawingData
            try! realm.write {
                drawingTrack.frames.append(frame)
            }
            log("Drawing data added for frame \(frameIndex)")
        }
    }
    
    private func log(_ message: String) {
        print(message)  // Print to console for debugging
    }
}


