import SwiftUI
import Translation

struct TextInspectorView: View {
  @State var text: String?
  
  private var textWithoutNewlines: String {
    text?.replacingOccurrences(of: "\n", with: " ") ?? ""
  }
  
  var body: some View {
    GeometryReader { geometry in
        VStack {
            JapaneseTextWithFuriganaView(text: JapaneseText(textWithoutNewlines))
                .offset(y: -20)
        }
        .padding()
    }
  }
}

#Preview {
  TextInspectorView(text: "人類の90%が猫を飼うこの社会に於いてパンデミックに陥るまでそう時間は掛からなかった")
}
