import SwiftUI
import AppKit

// ウィンドウをドラッグ可能にするヘルパー
struct WindowDraggableView: NSViewRepresentable {
    func makeNSView(context: Context) -> DragNSView {
        let view = DragNSView()
        return view
    }
    
    func updateNSView(_ nsView: DragNSView, context: Context) {}
}

class DragNSView: NSView {
    override var mouseDownCanMoveWindow: Bool {
        return true
    }
    
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}
