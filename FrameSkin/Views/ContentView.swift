import SwiftUI
import AVFoundation
import RealmSwift

struct ContentView: View {
	@StateObject var realmManager = RealmManager()
	@StateObject var shortcutManager = ShortcutManager()
	@State var logs: [String] = []
	
	
	
	var body: some View {
		OpenProjectView(realmManager: realmManager, shortcutManager: shortcutManager, logs: $logs)
	}
	
	
	
}
