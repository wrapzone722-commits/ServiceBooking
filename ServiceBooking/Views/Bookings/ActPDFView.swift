//
//  ActPDFView.swift
//  ServiceBooking
//
//  Просмотр и отправка PDF «Акт выполненных работ»
//

import SwiftUI
import PDFKit

struct ActPDFView: View {
    let url: URL
    var onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            PDFKitView(url: url)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("Акт выполненных работ")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Готово") { onDismiss() }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        ShareLink(item: url) {
                            Label("Поделиться", systemImage: "square.and.arrow.up")
                        }
                    }
                }
        }
    }
}

private struct PDFKitView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFKit.PDFView {
        let view = PDFKit.PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        if let doc = PDFDocument(url: url) {
            view.document = doc
        }
        return view
    }
    
    func updateUIView(_ uiView: PDFKit.PDFView, context: Context) {}
}

#Preview {
    ActPDFView(url: URL(fileURLWithPath: "/tmp/sample.pdf"), onDismiss: {})
}
