import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var showTextDrawer = false
    @State private var showFolderPicker = false
    @State private var showToolBar = false
    @State private var showTranslation = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack {
                    if Model.shared.mokuroDocument == nil {
                        EmptyView()
                    } else {
                        ZoomableScrollView {
                            MangaImageView()
                                .gesture(DragGesture(minimumDistance: 20, coordinateSpace: .local)
                                    .onEnded({ value in
                                        if value.translation.width < 0 { Model.shared.nextImage() }
                                        if value.translation.width > 0 { Model.shared.prevImage()}
                                    }))
                        }
                        .ignoresSafeArea()
                    }
                }
                
                if showTextDrawer {
                    ScrollView {
                        Spacer()
                        TextInspectorView(text: Model.shared.lastSelectedTextBox?.text)
                            .padding()
                        Spacer()
                    }
                    .frame(maxWidth: 600, maxHeight: 140)
                    .glassEffect()
                    .offset(y: -50)
                }
            }
            .translationPresentation(isPresented: $showTranslation, text: Model.shared.lastSelectedTextBox?.text ?? "")
            .fileImporter(isPresented: $showFolderPicker, allowedContentTypes: [.folder], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let folder):
                    Model.shared.loadMokuroDocument(folder: folder.first!)
                default:
                    break
                }
                showFolderPicker = false
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showFolderPicker = true
                    }, label: {
                        Image(systemName: "plus")
                    })
                }
                
                if showToolBar {
                    ToolbarItem {
                        Button(action: {
                            Model.shared.lastSelectedTextBox?.text.speakInJapanese()
                        }, label: {
                            Image(systemName: "message")
                        })
                    }
                    ToolbarItem {
                        Button(action: {
                            showTranslation.toggle()
                        }, label: {
                            Image(systemName: "translate")
                        })
                    }
                }
            }
            .onAppear {
                if Model.shared.mokuroDocument == nil {
                    showFolderPicker = true
                }
            }
            .onChange(of: Model.shared.mokuroDocument) { oldValue, newValue in
                if newValue == nil {
                    showFolderPicker = true
                }
            }
            .onChange(of: Model.shared.showToolBar) { oldValue, newValue in
                showToolBar = newValue
                showTextDrawer = newValue
            }
            .onChange(of: Model.shared.lastSelectionDate, {
                if let text = Model.shared.lastSelectedTextBox?.text {
                    showTextDrawer = !text.isEmpty
                    Model.shared.showToolBar = showTextDrawer
                }
            })
        }
    }
}

#Preview {
    ContentView()
}
