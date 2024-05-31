import SwiftUI

struct ControlView: View {
    @Binding var isPlaying: Bool
    let startAnimation: () -> Void
    let stopAnimation: () -> Void
    
    

    var body: some View {
        VStack {
            Spacer()
            Button(action: {
                isPlaying.toggle()
                if isPlaying {
                    startAnimation()
                } else {
                    stopAnimation()
                }
            }) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .padding()
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .keyboardShortcut("p")
            .padding()
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
