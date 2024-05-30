import SwiftUI

struct CanvasView: View {
    @Binding var selectedFrameImage: UIImage?
    @Binding var drawings: [Int: Path]
    @Binding var currentDrawing: Path
    @Binding var currentIndex: Int
    let saveDrawing: () -> Void

    var body: some View {
        ZStack {
            if let selectedFrameImage = selectedFrameImage {
                Image(uiImage: selectedFrameImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 600, height: 600)
            } else {
                Text("Loading...")
            }

            Canvas { context, size in
                if let frameDrawing = drawings[currentIndex] {
                    context.stroke(frameDrawing, with: .color(.white), lineWidth: 2)
                }
                context.stroke(currentDrawing, with: .color(.white), lineWidth: 2)
            }
            .frame(width: 600, height: 600)
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { value in
                            if currentDrawing.isEmpty {
                                currentDrawing.move(to: value.location)
                            } else {
                                currentDrawing.addLine(to: value.location)
                            }
                        }
                        .onEnded { value in
                            if drawings[currentIndex] == nil {
                                drawings[currentIndex] = Path()
                            }
                            drawings[currentIndex]?.addPath(currentDrawing)
                            saveDrawing()
                            currentDrawing = Path()
                        })
        }
    }
}
