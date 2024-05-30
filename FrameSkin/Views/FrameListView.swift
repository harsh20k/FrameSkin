import SwiftUI

struct FrameListView: View {
    @Binding var frameImages: [UIImage]
    @Binding var selectedFrameImage: UIImage?
    @Binding var currentIndex: Int
    let onSelectFrame: (Int) -> Void

    var body: some View {
        if !frameImages.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(frameImages.indices, id: \.self) { index in
                        Image(uiImage: frameImages[index])
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .shadow(color: currentIndex == index ? .white : .clear, radius: 20)
                            .onTapGesture {
                                selectedFrameImage = frameImages[index]
                                currentIndex = index
                                onSelectFrame(index)
                            }
                    }
                }
                .padding()
            }
        }
    }
}
