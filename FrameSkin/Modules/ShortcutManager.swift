import Foundation
import SwiftUI

class ShortcutManager: ObservableObject {
    @Published private(set) var shortcuts: [String: String]

    private let userDefaultsKey = "CustomShortcuts"

    init() {
        
        //resetting the values on every launch for testing
                shortcuts = [
                    "playPause": "space",
                    "nextFrame": "rightArrow",
                    "previousFrame": "leftArrow"
                ]
                UserDefaults.standard.setValue(shortcuts, forKey: userDefaultsKey)
        
        //code for reading from userdefaults
//        if let savedShortcuts = UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: String] {
//            shortcuts = savedShortcuts
//        } else {
//            shortcuts = [
//                "playPause": "space",
//                "nextFrame": "rightArrow",
//                "previousFrame": "leftArrow"
//            ]
//        }
    }

    func shortcut(for action: String) -> String? {
        return shortcuts[action]
    }

    func updateShortcut(for action: String, to newShortcut: String) {
        shortcuts[action] = newShortcut
        saveShortcuts()
    }

    private func saveShortcuts() {
        UserDefaults.standard.setValue(shortcuts, forKey: userDefaultsKey)
    }

    

    func keyEquivalent(for action: String) -> KeyEquivalent {
        guard let shortcut = shortcuts[action] else { return KeyEquivalent(" ") }
        switch shortcut {
        case "space": return KeyEquivalent(" ")
		case "rightArrow": return KeyEquivalent.rightArrow
		case "x": return KeyEquivalent.rightArrow
        case "leftArrow": return KeyEquivalent.leftArrow
		case "z": return KeyEquivalent.leftArrow
        default: return KeyEquivalent(Character(shortcut))
        }
    }
}
