import Foundation
import RealmSwift
import CoreGraphics
import SwiftUI

class RealmManager: ObservableObject {
    private(set) var localRealm: Realm?
    @Published public var projects: [FrameSkinProject] = []

    init() {
		DispatchQueue.main.async{
			self.openRealm()
			self.loadProjects()
			self.createDummyProjectIfNeeded(forceCreate: false)
		}
    }

    func openRealm() {
        do {
            let config = Realm.Configuration(schemaVersion: 1)
            Realm.Configuration.defaultConfiguration = config
            localRealm = try Realm()
        } catch {
			fatalError("Error opening Realm: \(error)")
        }
    }

	func loadProjects() {
		guard let localRealm = localRealm else {
			print("Realm instance is not available")
			return
		}
		let allProjects = localRealm.objects(FrameSkinProject.self)
		
		self.projects = Array(allProjects).filter { !$0.isInvalidated }
		
		print("Loaded \(self.projects.count) projects from Realm")
		
			// Calculate the size of the projects array in bytes
		let sizeInBytes = self.projects.reduce(0) { $0 + $1.sizeInBytes }
		let sizeInMegabytes = Double(sizeInBytes) / (1024 * 1024)
		print("Size of projects array: \(String(format: "%.2f", sizeInMegabytes)) MB")
	}
	
	func projectCount() {
		print("project count: \(self.projects.count)")
	}
	
	func deleteAllProjects() {
			// Ensure the Realm instance is available
		guard let localRealm = localRealm else {
			print("Realm instance is not available")
			return
		}
		DispatchQueue.main.async {
			do {
					// Begin a write transaction
				try localRealm.write {
						// Fetch all projects from the Realm database
					let allProjects = localRealm.objects(FrameSkinProject.self)
					let allScenes = localRealm.objects(FrameSkinScene.self)
					let allTracks = localRealm.objects(FrameSkinTrack.self)
					let allFrames = localRealm.objects(FrameSkinFrame.self)
						// Delete all fetched projects
					localRealm.delete(allProjects)
					localRealm.delete(allScenes)
					localRealm.delete(allTracks)
					localRealm.delete(allFrames)
					print("All projects and their data have been deleted")
				}
				self.openRealm()
				self.projectCount()
				let allProjects = localRealm.objects(FrameSkinProject.self)
				print("\(allProjects.count)")
				self.projectCount()
				
			} catch {
					// Handle any errors that occur during the write transaction
				fatalError("Unable to delete projects from Realm DB: \(error.localizedDescription)")
			}
		}
	}

	func createDummyProjectIfNeeded(forceCreate: Bool) {
		if forceCreate==false {
			if projects.isEmpty {
				print("No projects found, creating dummy project...")
				createDummyProject()
			} else {
				print("Existing projects found")
			}
		} else {
			createDummyProject()
			print("Forcefully creating dummy project")
		}
    }

	func createDummyProject() {
		guard let localRealm = localRealm else { return }
		
		do {
			try localRealm.write {
				let project = FrameSkinProject()
				print("project count ==== \(projects.count)")
				project.title = "Dummy" + "\(projects.count)"
				project.createdDate = Date()
				project.lastModifiedDate = Date()
				
				let trackVideo = FrameSkinTrack()
				trackVideo.type = .video
				trackVideo.title = "Video Track"
				trackVideo.position = 0
				
					// Extract frames synchronously
				let frameDataArray = extractFramesFromVideoAppBundle()
				for (index, frameData) in frameDataArray.enumerated() {
					let frame = FrameSkinFrame()
					frame.frameIndex = index
					frame.frameData = frameData
					trackVideo.frames.append(frame)
				}
				
				let trackDrawing = FrameSkinTrack()
				trackDrawing.type = .drawing
				trackDrawing.title = "Drawing Track"
				trackDrawing.position = 1
				
				let scene = FrameSkinScene()
				scene.tracks.append(trackVideo)
				scene.tracks.append(trackDrawing)
				scene.title = "Default_Scene"
				
				project.scenes.append(scene)
				
				localRealm.add(project)
				print("Added project")
			}
			
				// Reload projects to include the new dummy project
			loadProjects()
			print("Dummy project created")
		} catch {
			fatalError("Unable to write dummy project to Realm DB: \(error.localizedDescription)")
		}
	}
	
	
	func extractFramesFromVideoAppBundle() -> [Data] {
		print("Extracting frames from video...")
		guard let url = Bundle.main.url(forResource: "sample", withExtension: "mp4") else {
			fatalError("Video file not found")
		}
		
		let frameExtractor = FrameExtractor(videoURL: url)
		let images = frameExtractor.extractFrames(frameCount: 5)
		
		let frameDataArray = images.map { $0.pngData()! }
		
		let totalSizeInBytes = images.reduce(0) { $0 + ($1.jpegData(compressionQuality: 1)?.count ?? 0) }
		let totalSizeInMB = Double(totalSizeInBytes) / 1_048_576
		print("Total size of image collection: \(String(format: "%.2f", totalSizeInMB)) MB")
		
		return frameDataArray
	}
		/// Extracts frames from a sample video and adds them to the project.
//	func extractFramesFromVideoAppBundle() {
//		print("Extracting frames from video...")
//		guard let url = Bundle.main.url(forResource: "sample", withExtension: "mp4") else {
//			fatalError("Video file not found")
//		}
//		
//		let frameExtractor = FrameExtractor(videoURL: url)
//		frameExtractor.extractFrames(frameCount: 5) { images in
//			
//			if let firstImage = images.first {
//				let frameDataArray = images.map { $0.pngData()! }
//				self.addFramesToProject(frames: frameDataArray)
//			} else {
//				print("No frames extracted")
//			}
//			let totalSizeInBytes = images.reduce(0) { $0 + ($1.jpegData(compressionQuality: 1)?.count ?? 0) }
//			let totalSizeInMB = Double(totalSizeInBytes) / 1_048_576
//			print("Total size of image collection: \(String(format: "%.2f", totalSizeInMB)) MB")
//		}
//	}
	
    func addFramesToScene(frames: [Data]) {
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
        if let localRealm = localRealm, 
			let project = projects.first,
			let scene = project.scenes.first {
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
	
	func addDrawingDataToTrack(drawingData: Data, frameIndex: Int, projectId: ObjectId) {
		guard let localRealm = localRealm,
			  let project = localRealm.object(ofType: FrameSkinProject.self, forPrimaryKey: projectId),
			  let scene = project.scenes.first else {
			print("Failed to find the project or scene for the given ID")
			return
		}
		
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
			print("Added drawing data for frame \(frameIndex) to project \(project.title)")
		}
	}
	

	

}
