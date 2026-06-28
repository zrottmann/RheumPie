import SwiftUI
import PencilKit

enum SketchTool { case pen, marker, eraser }

/// A PencilKit drawing sheet. The author draws with pen/marker/eraser in chosen
/// colors (with an optional ruler), then taps "Insert drawing" to rasterize the
/// canvas to an image the post embeds — ideal for hand-drawn joint diagrams.
struct SketchCanvasView: View {
    /// Delivers the flattened drawing when the author taps Insert.
    let onInsert: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var canvas = PKCanvasView()
    @State private var tool: SketchTool = .pen
    @State private var color: Color = .black
    @State private var rulerOn = false

    private let palette: [Color] = [.black, .red, .orange, .blue, .green, .purple, .brown]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SketchCanvasRepresentable(canvas: canvas, tool: tool, color: color, rulerOn: rulerOn)
                    .background(Color.white)
                controls
            }
            .navigationTitle("Sketch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Insert drawing") { insert() }.bold()
                }
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                toolButton(.pen, "pencil.tip")
                toolButton(.marker, "highlighter")
                toolButton(.eraser, "eraser")
                Spacer()
                Toggle(isOn: $rulerOn) { Image(systemName: "ruler") }
                    .toggleStyle(.button)
                    .accessibilityLabel("Ruler")
                Button(role: .destructive) { canvas.drawing = PKDrawing() } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Clear")
            }
            HStack(spacing: 12) {
                ForEach(palette, id: \.self) { c in
                    Circle()
                        .fill(c)
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(.primary.opacity(color == c ? 0.9 : 0.18), lineWidth: color == c ? 3 : 1))
                        .onTapGesture {
                            color = c
                            if tool == .eraser { tool = .pen }
                        }
                }
                Spacer()
                ColorPicker("", selection: $color).labelsHidden()
            }
        }
        .padding()
        .background(.bar)
    }

    private func toolButton(_ t: SketchTool, _ icon: String) -> some View {
        Button { tool = t } label: {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 46, height: 38)
                .background(tool == t ? color.opacity(0.18) : Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func insert() {
        let drawing = canvas.drawing
        let area: CGRect = drawing.bounds.isEmpty
            ? CGRect(origin: .zero, size: canvas.bounds.size)
            : drawing.bounds.insetBy(dx: -16, dy: -16)
        guard area.width > 1, area.height > 1 else { dismiss(); return }
        let rendered = drawing.image(from: area, scale: 2.0)
        // Flatten onto white so the PNG reads cleanly in light + dark mode.
        let flattened = UIGraphicsImageRenderer(size: rendered.size).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: rendered.size))
            rendered.draw(at: .zero)
        }
        onInsert(flattened)
        dismiss()
    }
}

private struct SketchCanvasRepresentable: UIViewRepresentable {
    let canvas: PKCanvasView
    let tool: SketchTool
    let color: Color
    let rulerOn: Bool

    func makeUIView(context: Context) -> PKCanvasView {
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .white
        canvas.alwaysBounceVertical = false
        apply(canvas)
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        apply(uiView)
        uiView.isRulerActive = rulerOn
    }

    private func apply(_ cv: PKCanvasView) {
        switch tool {
        case .pen: cv.tool = PKInkingTool(.pen, color: UIColor(color), width: 5)
        case .marker: cv.tool = PKInkingTool(.marker, color: UIColor(color), width: 18)
        case .eraser: cv.tool = PKEraserTool(.vector)
        }
    }
}
