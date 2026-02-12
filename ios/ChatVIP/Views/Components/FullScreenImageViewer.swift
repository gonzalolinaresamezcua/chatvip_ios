//
//  FullScreenImageViewer.swift
//  ChatVIP
//

import SwiftUI

struct FullScreenImageViewer: View {
    let imageFile: URL
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let uiImage = UIImage(contentsOfFile: imageFile.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { s in scale = lastScale * s }
                            .onEnded { _ in lastScale = scale }
                    )
            }
            VStack {
                HStack {
                    Spacer()
                    Button("Cerrar") { onDismiss() }
                        .foregroundColor(.white)
                        .padding()
                }
                Spacer()
            }
        }
        .onTapGesture(count: 2) { scale = scale > 1 ? 1 : 2; lastScale = scale }
    }
}
