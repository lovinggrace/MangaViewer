import SwiftUI

struct ContentView: View {
  @State private var showTextDrawer = false
  
  var body: some View {
    VStack {
      ZoomableScrollView {
        LiveTextMangaView()
          .gesture(DragGesture(minimumDistance: 20, coordinateSpace: .local)
            .onEnded({ value in
              if value.translation.width < 0 { Model.shared.nextImage() }
              if value.translation.width > 0 { Model.shared.prevImage()}
            }))
      }
    }
    .sheet(isPresented: $showTextDrawer) {
      ScrollView {
        Spacer()
        TextInspectorView(text: Model.shared.lastSelectedTextBox?.text)
        Spacer()
      }
      .padding()
      .background(.regularMaterial)
      .presentationDetents([.height(210), .medium])
      .containerRelativeFrame([.horizontal, .vertical])
    }
    .onChange(of: Model.shared.lastSelectionDate, {
      if let text = Model.shared.lastSelectedTextBox?.text {
        showTextDrawer = !text.isEmpty
      }
    })
  }
}

#Preview {
  ContentView()
}
