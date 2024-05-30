import Foundation

class Logger {
    static func log(_ message: String) {
        DispatchQueue.main.async {
            print(message)  // Print to console for debugging
            // Add any other logging mechanisms, like saving to a file or remote server
        }
    }
}
