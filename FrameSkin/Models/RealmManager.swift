import Foundation
import RealmSwift
import CoreGraphics

class RealmManager: ObservableObject {
    private(set) var localRealm: Realm?
    @Published private(set) var projects: [FrameSkinProject] = []

    init() {
        openRealm()
        loadProjects()
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
        }
    }

    func addFramesToProject(frames: [Data]) {
        if let localRealm = localRealm, let project = projects.first, let scene = project.scenes.first {
            try? localRealm.write {
                let videoTrack = scene.tracks.first(where: { $0.type == .video }) ?? FrameSkinTrack()
                if videoTrack.type != .video {
                    videoTrack.type = .video
                    videoTrack.title = "Video Track"
                    videoTrack.position = scene.tracks.count
                    scene.tracks.append(videoTrack)
                }

                for (index, frameData) in frames.enumerated() {
                    let frame = FrameSkinFrame()
                    frame.frameIndex = index
                    frame.frameData = frameData
                    videoTrack.frames.append(frame)
                }

                localRealm.add(project, update: .modified)
            }
        }
    }

    func addDrawingDataToTrack(drawingData: Data, frameIndex: Int) {
        if let localRealm = localRealm, let project = projects.first, let scene = project.scenes.first {
            try? localRealm.write {
                let drawingTrack = scene.tracks.first(where: { $0.type == .drawing }) ?? FrameSkinTrack()
                if drawingTrack.type != .drawing {
                    drawingTrack.type = .drawing
                    drawingTrack.title = "Drawing Track"
                    drawingTrack.position = scene.tracks.count
                    scene.tracks.append(drawingTrack)
                }

                if let frame = drawingTrack.frames.first(where: { $0.frameIndex == frameIndex }) {
                    frame.drawingData = drawingData
                } else {
                    let frame = FrameSkinFrame()
                    frame.frameIndex = frameIndex
                    frame.drawingData = drawingData
                    drawingTrack.frames.append(frame)
                }

                localRealm.add(project, update: .modified)
            }
        }
    }
}
