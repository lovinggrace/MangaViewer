import SwiftUI
import Translation

struct TextInspectorView: View {
  @State var text: String?
  @State private var showTranslation = false
  
  private var textWithoutNewlines: String {
    text?.replacingOccurrences(of: "\n", with: " ") ?? ""
  }
  
  var body: some View {
    GeometryReader { geometry in
      VStack {
        Button(action: {
          showTranslation.toggle()
        }, label: {
          Image(systemName: "translate")
        })
        .offset(x: geometry.size.width / 2 - 15, y: -25)
        
        JapaneseTextWithFuriganaView(text: JapaneseText(textWithoutNewlines))
          .offset(y: -20)
      }
      .padding()
      .translationPresentation(isPresented: $showTranslation, text: textWithoutNewlines)
    }
  }
}

#Preview {
  TextInspectorView(text: "人類の90%が猫を飼うこの社会に於いてパンデミックに陥るまでそう時間は掛からなかった")
}
