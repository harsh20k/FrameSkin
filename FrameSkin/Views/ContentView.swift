import SwiftUI
import AVFoundation
import RealmSwift

struct ContentView: View {
	@StateObject var realmManager = RealmManager()
	@StateObject var shortcutManager = ShortcutManager()
	@State var logs: [String] = []
	@State private var path = NavigationPath()
	
	
	var body: some View {
		
		NavigationStack(path: $path.animation()) {
			
			ForEach(realmManager.projects, id: \.self){ project in
				VStack {
					NavigationLink("Project: \(project.title)", value: 3)
					HStack {
						Text ("\(project.createdDate) \(project.lastModifiedDate) ")
					}
				}
				.navigationDestination(for: Int.self) { value in
					OpenProjectView(project: project, realmManager: realmManager, shortcutManager: shortcutManager, logs: $logs)
				}
			}
			.toolbar { Spacer() }
		}
	}

}
