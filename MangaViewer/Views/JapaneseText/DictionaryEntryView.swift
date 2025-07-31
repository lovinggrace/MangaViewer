import SwiftUI

struct DictionaryEntryView: View {
    @State var element: JapaneseText.Element
    @Environment(\.openURL) var openURL

    var body: some View {
        VStack(alignment: .leading) {
            HStack() {
                Text(element.dictionaryForm)
                    .bold()
                    .font(.largeTitle)
                    .textSelection(.enabled)
                Button(action: {
                    openURL(element.openInNihongoURL)
                }, label: {
                    Image("nihongoapp")
                        .resizable()
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                        .frame(width: 20, height: 20)
                        .padding(.trailing)
                })
            }

            Text(element.translation ?? "No translation")
                .textSelection(.enabled)
        }
        .foregroundColor(.white)
    }
}
