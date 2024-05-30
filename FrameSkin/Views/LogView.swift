import SwiftUI

struct LogView: View {
    @Binding var logs: [String]

    var body: some View {
        ScrollView() {
            ForEach(logs.reversed(), id: \.self) { log in
                    Text(log)
                        .monospaced()
                        .foregroundColor(.white)
                        .font(.footnote)
                }
            .padding(.top, 10)
            .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: .infinity)
        }
        .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: 200, alignment: .topLeading)
        .background(Color.black)
        .padding(.top, 10)
    }
}
