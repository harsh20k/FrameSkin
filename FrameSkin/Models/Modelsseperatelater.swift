import Foundation
import RealmSwift

class FrameSkinProject: Object, Identifiable {
    
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




class FrameSkinScene: Object, Identifiable {
    
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
class FrameSkinTrack: Object, Identifiable {
    
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var title: String
    @Persisted var rawType: String
    @Persisted var position: Int
    
    var type: TrackType {
        get { return TrackType(rawValue: rawType) ?? .video }
        set { rawType = newValue.rawValue }
    }
    
    @Persisted var frames: List<FrameSkinFrame> = List<FrameSkinFrame>()
    
    override class func primaryKey() -> String? {
        return "id"
    }
}


class FrameSkinFrame: Object, Identifiable {
    
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var frameIndex: Int
    @Persisted var frameData: Data?
    @Persisted var drawingData: Data?
    
    override class func primaryKey() -> String? {
        return "id"
    }
}

