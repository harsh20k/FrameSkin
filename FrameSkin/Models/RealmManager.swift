import Foundation
import RealmSwift
import CoreGraphics

class RealmManager: ObservableObject {
    private(set) var localRealm: Realm?
    @Published private(set) var projects: [FrameSkinProject] = []

    init() {
        openRealm()
        loadProjects()
        createDummyProjectIfNeeded()
    }

    func openRealm() {
        do {
            let config = Realm.Configuration(schemaVersion: 1)
            Realm.Configuration.defaultConfiguration = config
            localRealm = try Realm()
        } catch {
            print("Error opening Realm: \(error)")
        }
    }

    func loadProjects() {
        if let localRealm = localRealm {
            let allProjects = localRealm.objects(FrameSkinProject.self)
            projects = Array(allProjects)
            print("Loaded \(projects.count) projects from Realm")
        }
    }

    func createDummyProjectIfNeeded() {
        if projects.isEmpty {
            print("No projects found, creating dummy project...")
            createDummyProject()
        } else {
            print("Existing projects found")
        }
    }

    func createDummyProject() {
        guard let localRealm = localRealm else { return }
        let project = FrameSkinProject()
        project.title = "Dummy Project"
        project.createdDate = Date()
        project.lastModifiedDate = Date()
        let scene = FrameSkinScene()
        project.scenes.append(scene)

        try? localRealm.write {
            localRealm.add(project)
        }

        // Reload projects to include the new dummy project
        loadProjects()
        print("Dummy project created")
    }

    func addFramesToProject(frames: [Data]) {
        if let localRealm = localRealm, let project = projects.first, let scene = project.scenes.first {
            try? localRealm.write {
                var videoTrack = scene.tracks.first(where: { $0.type == .video })
                if videoTrack == nil {
                    videoTrack = FrameSkinTrack()
                    videoTrack?.type = .video
                    videoTrack?.title = "Video Track"
                    videoTrack?.position = scene.tracks.count
                    scene.tracks.append(videoTrack!)
                    print("Created new video track")
                }

                for (index, frameData) in frames.enumerated() {
                    let frame = FrameSkinFrame()
                    frame.frameIndex = index
                    frame.frameData = frameData
                    videoTrack?.frames.append(frame)
                }

                localRealm.add(project, update: .modified)
                print("Added \(frames.count) frames to realm project")
            }
        } else {
            print("Failed to add frames to project: Realm or project/scene not found")
        }
    }

    func addDrawingDataToTrack(drawingData: Data, frameIndex: Int) {
        if let localRealm = localRealm, let project = projects.first, let scene = project.scenes.first {
            try? localRealm.write {
                var drawingTrack = scene.tracks.first(where: { $0.type == .drawing })
                if drawingTrack == nil {
                    drawingTrack = FrameSkinTrack()
                    drawingTrack?.type = .drawing
                    drawingTrack?.title = "Drawing Track"
                    drawingTrack?.position = scene.tracks.count
                    scene.tracks.append(drawingTrack!)
                    print("Created new drawing track")
                }

                if let frame = drawingTrack?.frames.first(where: { $0.frameIndex == frameIndex }) {
                    frame.drawingData = drawingData
                } else {
                    let frame = FrameSkinFrame()
                    frame.frameIndex = frameIndex
                    frame.drawingData = drawingData
                    drawingTrack?.frames.append(frame)
                }

                localRealm.add(project, update: .modified)
                print("Added drawing data for frame \(frameIndex) to project")
            }
        } else {
            print("Failed to add drawing data to project: Realm or project/scene not found")
        }
    }
}
