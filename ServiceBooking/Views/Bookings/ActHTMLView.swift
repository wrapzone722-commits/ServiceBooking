//
//  ActHTMLView.swift
//  ServiceBooking
//
//  Просмотр HTML «Акт выполненных работ»
//

import SwiftUI
import WebKit

struct ActHTMLView: View {
    let html: String
    var onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            HTMLWebView(html: html)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("Акт выполненных работ")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Готово") { onDismiss() }
                    }
                }
        }
    }
}

private struct HTMLWebView: UIViewRepresentable {
    let html: String

    /// Адаптирует HTML под ширину экрана (viewport + responsive CSS)
    private func htmlForScreenWidth(_ raw: String) -> String {
        let viewport = """
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=5, user-scalable=yes">
        <style>
          html,body{width:100%;margin:0;padding:0;-webkit-text-size-adjust:100%;}
          .page{max-width:100%!important;width:100%!important;box-sizing:border-box!important;margin:0!important;}
          @media screen and (max-width:560px){
            .doc{padding:16px 14px 20px!important;}
            .grid{grid-template-columns:1fr!important;}
            .row{grid-template-columns:1fr!important;}
            .sign{grid-template-columns:1fr!important;}
          }
        </style>
        """
        if raw.lowercased().contains("</head>") {
            return raw.replacingOccurrences(of: "</head>", with: "\(viewport)</head>", options: .caseInsensitive)
        }
        if raw.lowercased().contains("<head>") {
            return raw.replacingOccurrences(of: "<head>", with: "<head>\(viewport)", options: .caseInsensitive)
        }
        return "<!DOCTYPE html><html><head>\(viewport)</head><body>\(raw)</body></html>"
    }

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView(frame: .zero)
        view.isOpaque = false
        view.backgroundColor = .clear
        view.scrollView.backgroundColor = .clear
        view.scrollView.bounces = true
        view.loadHTMLString(htmlForScreenWidth(html), baseURL: nil)
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlForScreenWidth(html), baseURL: nil)
    }
}

#Preview {
    ActHTMLView(html: "<html><body><h1>Акт</h1><p>Пример</p></body></html>", onDismiss: {})
}

