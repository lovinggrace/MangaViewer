import SwiftUI

struct GlowBorder: ViewModifier {
    var color: Color
    var lineWidth: Int
    
    func body(content: Content) -> some View {
        applyShadow(content: AnyView(content), lineWidth: lineWidth)
    }
    
    func applyShadow(content: AnyView, lineWidth: Int) -> AnyView {
        if lineWidth == 0 {
            return content
        } else {
            return applyShadow(content: AnyView(content.shadow(color: color, radius: 1)), lineWidth: lineWidth - 1)
        }
    }
}

extension View {
    func glowBorder(color: Color, lineWidth: Int) -> some View {
        self.modifier(GlowBorder(color: color, lineWidth: lineWidth))
    }
    
    func customStroke(color: Color, width: CGFloat = 1) -> some View {
        self.modifier(StrokeModifier(strokeSize: width, strokeColor: color))
    }
}

struct StrokeModifier : ViewModifier {
    private let id = UUID()
    var strokeSize: CGFloat = 1
    var strokeColor: Color = . blue
    func body (content: Content) -> some View {
        content
            .padding(strokeSize*2)
            .background(Rectangle().foregroundStyle(strokeColor))
            .mask({
                 outline(context: content)
            })
    }
    
    func outline(context:Content) -> some View {
        Canvas{ context, size in
            context.addFilter(.alphaThreshold(min: 0.01))
            context.drawLayer { layer in
                if let text = context.resolveSymbol (id: id){
                    layer.draw(text, at: .init(x: size.width/2, y: size.height/2))
                }
            }
        } symbols: {
            context.tag(id)
                .blur(radius: strokeSize)
        }
    }
}
