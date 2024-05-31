import SwiftUI

struct ShortcutSettingsView: View {
    @ObservedObject var shortcutManager: ShortcutManager

    var body: some View {
        Form {
            Section(header: Text("Shortcuts")) {
                HStack {
                    Text("Play/Pause")
                    KeyCombinationInputView(keyCombination: Binding(
                        get: { shortcutManager.shortcut(for: "playPause") ?? "" },
                        set: { shortcutManager.updateShortcut(for: "playPause", to: $0) }
                    ))
                }
                HStack {
                    Text("Next Frame")
                    KeyCombinationInputView(keyCombination: Binding(
                        get: { shortcutManager.shortcut(for: "nextFrame") ?? "" },
                        set: { shortcutManager.updateShortcut(for: "nextFrame", to: $0) }
                    ))
                }
                HStack {
                    Text("Previous Frame")
                    KeyCombinationInputView(keyCombination: Binding(
                        get: { shortcutManager.shortcut(for: "previousFrame") ?? "" },
                        set: { shortcutManager.updateShortcut(for: "previousFrame", to: $0) }
                    ))
                }
            }
        }
        .padding()
    }
}
