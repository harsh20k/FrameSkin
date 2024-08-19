import Foundation
import RealmSwift

class FrameSkinProject: Object, Identifiable, Codable {
    
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var title: String
    @Persisted var projectDescription: String?
    @Persisted var createdDate: Date
    @Persisted var lastModifiedDate: Date
    @Persisted var version: Int
    @Persisted var createdBy: String?
    @Persisted var tags: List<String> = List<String>()
    @Persisted var thumbnail: Data?
    
    @Persisted var scenes: List<FrameSkinScene> = List<FrameSkinScene>()
    
    override class func primaryKey() -> String? {
        return "id"
    }
}

class FrameSkinScene: Object, Identifiable, Codable {
    
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var title: String
    
    @Persisted var tracks: List<FrameSkinTrack> = List<FrameSkinTrack>()
    
    override class func primaryKey() -> String? {
        return "id"
    }
}

enum TrackType: String, PersistableEnum {
    case video
    case audio
    case drawing
    // Add other track types as needed
}
class FrameSkinTrack: Object, Identifiable, Codable {
    
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var title: String
    @Persisted var rawType: String
    @Persisted var position: Int
    
    var type: TrackType {
		get {
			if let trackType = TrackType(rawValue: rawType) {
				return trackType
			} else {
				print("Invalid rawType '\(rawType)', defaulting to .video")
				return .video
			}
		}
		set { rawType = newValue.rawValue }
    }
    
    @Persisted var frames: List<FrameSkinFrame> = List<FrameSkinFrame>()
    
    override class func primaryKey() -> String? {
        return "id"
    }
}


class FrameSkinFrame: Object, Identifiable, Codable {
    
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var frameIndex: Int
    @Persisted var frameData: Data?
    @Persisted var drawingData: Data?
    
    override class func primaryKey() -> String? {
        return "id"
    }
}



//extensions

extension FrameSkinProject {
	var sizeInBytes: Int {
		var size = MemoryLayout.size(ofValue: self.id) +
		MemoryLayout.size(ofValue: self.title) +
		(projectDescription?.count ?? 0) +
		MemoryLayout.size(ofValue: self.createdDate) +
		MemoryLayout.size(ofValue: self.lastModifiedDate) +
		MemoryLayout.size(ofValue: self.version) +
		(createdBy?.count ?? 0) +
		tags.reduce(0) { $0 + $1.count } +
		(thumbnail?.count ?? 0)
		
		size += scenes.reduce(0) { $0 + $1.sizeInBytes }
		return size
	}
}

extension FrameSkinScene {
	var sizeInBytes: Int {
		var size = MemoryLayout.size(ofValue: self.id) +
		MemoryLayout.size(ofValue: self.title)
		
		size += tracks.reduce(0) { $0 + $1.sizeInBytes }
		return size
	}
}

extension FrameSkinTrack {
	var sizeInBytes: Int {
		var size = MemoryLayout.size(ofValue: self.id) +
		MemoryLayout.size(ofValue: self.title) +
		MemoryLayout.size(ofValue: self.rawType) +
		MemoryLayout.size(ofValue: self.position)
		
		size += frames.reduce(0) { $0 + $1.sizeInBytes }
		return size
	}
}

extension FrameSkinFrame {
	var sizeInBytes: Int {
		let size = MemoryLayout.size(ofValue: self.id) +
		MemoryLayout.size(ofValue: self.frameIndex) +
		(frameData?.count ?? 0) +
		(drawingData?.count ?? 0)
		return size
	}
}

