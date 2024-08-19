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
			VStack{
				ForEach(realmManager.projects, id: \.self){ project in
					VStack {
						NavigationLink {
							OpenProjectView(project: project, realmManager: realmManager, shortcutManager: shortcutManager, logs: $logs)
						} label: {
							HStack{
								Text("Project: \(project.title)")
								Text("\(project.createdDate.formatted()) \(project.lastModifiedDate.formatted())")
									.padding()
							}
						}
					}
				}
				.toolbar { Spacer() }
				Spacer()
				HStack{
					Text("Delete \(realmManager.projects.count) projects")
					Button {
						realmManager.deleteAllProjects()
					} label: {
						Image(systemName: "xmark.bin.fill")
							.foregroundStyle(Color.red.opacity(0.7))
							.padding()
					}

				}
			}
		}
	}

}
