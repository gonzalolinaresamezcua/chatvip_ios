//
//  CommonUI.swift
//  ChatVIP
//

import SwiftUI

struct ChatVIPHeader<Title: View>: View {
    let title: Title
    var navigationIcon: (() -> Void)?
    var actions: () -> AnyView

    init(
        @ViewBuilder title: () -> Title,
        navigationIcon: (() -> Void)? = nil,
        @ViewBuilder actions: @escaping () -> some View = { EmptyView() }
    ) {
        self.title = title()
        self.navigationIcon = navigationIcon
        self.actions = { AnyView(actions()) }
    }

    var body: some View {
        HStack {
            if let nav = navigationIcon {
                Button(action: nav) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                }
            }
            Spacer()
            title
            Spacer()
            actions()
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct ChatVIPBackground: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<15, id: \.self) { row in
                    ForEach(0..<4, id: \.self) { col in
                        Text("ChatVIP")
                            .font(.system(size: (row + col) % 2 == 0 ? 14 : 10, weight: .bold))
                            .foregroundColor(Color(red: 0.38, green: 0.49, blue: 0.55)
                                .opacity((row + col) % 3 == 0 ? 0.15 : 0.08))
                            .position(
                                x: geo.size.width * CGFloat(col + 1) / 5,
                                y: geo.size.height * CGFloat(row + 1) / 16
                            )
                    }
                }
            }
            .rotationEffect(.degrees(-15))
        }
        .ignoresSafeArea()
    }
}

struct PoweredByFooter: View {
    var body: some View {
        Link("Powered by IA digitacode.es", destination: URL(string: "https://digitacode.es")!)
            .font(.caption)
            .foregroundColor(Color(red: 0.72, green: 0.53, blue: 0.04))
            .padding(.bottom, 16)
    }
}
