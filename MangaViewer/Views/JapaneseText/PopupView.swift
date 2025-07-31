import SwiftUI
import Popovers

struct PopupView: View {
    @State var element: JapaneseText.Element

    var body: some View {
        Templates.Container(arrowSide: .bottom(.centered), backgroundColor: Color(.black.opacity(0.9)), padding: 30) {
            VStack {
                DictionaryEntryView(element: element)
            }
            .frame(maxWidth: 400)

        }
    }
}

struct PopupView_Previews: PreviewProvider {
    static var previews: some View {
        PopupView(element: JapaneseText("蜂蜜は熊の大好物です。").elements.first!)
            .environmentObject(Popover.Context())
    }
}
