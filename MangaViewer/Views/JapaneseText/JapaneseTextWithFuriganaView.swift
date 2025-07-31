import SwiftUI
import WrappingStack

struct JapaneseTextWithFuriganaView: View {
    var text: JapaneseText
    
    var body: some View {
        WrappingHStack(id: \.self, horizontalSpacing: 0, verticalSpacing: 10) {
            ForEach(text.elements, id: \.self) { element in
                JapaneseTextElementView(element: element)
            }
        }
    }
}

struct JapaneseTextElementView: View {
    @State var element: JapaneseText.Element
    @State var showsPopover: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Text(element.transliteration)
                .font(.caption2)
                .bold()
                .foregroundColor(.white)
                .hidden(!element.hasFurigana)
                .textSelection(.enabled)
            Text(element.text)
                .font(.title2)
                .bold()
                .foregroundColor(.white)
                .customStroke(color: element.color, width: 0.5)
                .textSelection(.enabled)
        }
        .onTapGesture {
            showsPopover = true
        }
        .popover(present: $showsPopover, attributes: {
            $0.position = .absolute(
                originAnchor: .top,
                popoverAnchor: .bottom
            )
            $0.sourceFrameInset = .init(-20)
        }) {
            PopupView(element: element)
                .onTapGesture {
                    showsPopover = false
                }
        }

    }
}

#Preview {
    JapaneseTextWithFuriganaView(text: JapaneseText("蜂蜜は熊の大好物です。"))
}
