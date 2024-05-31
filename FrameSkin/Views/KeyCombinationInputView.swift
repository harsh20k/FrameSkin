import SwiftUI

struct KeyCombinationInputView: View {
    @Binding var keyCombination: String

    @State private var isEditing = false

    var body: some View {
        HStack {
            TextField("Key Combination", text: $keyCombination)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(!isEditing)
            Button(action: { isEditing.toggle() }) {
                Text(isEditing ? "Done" : "Edit")
            }
        }
    }
}
