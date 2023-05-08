//
//  PasscodeView.swift
//  Passs
//
//  Created by Dmitry Fedorov on 08.05.2023.
//

import SwiftUI

struct PasscodeView: View {
    @State var passcode = [String]()

    @State private var start = false
    @State private var isOpened = false

    var onCancel: () -> Void
    var onCompleted: () -> Void
    var validation: (String) -> Bool

    var body: some View {
        ZStack {
            VisualEffectView(effect: UIBlurEffect(style: .light))
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                Image(systemName: isOpened ? "lock.open" : "lock")
                    .resizable()
                    .foregroundColor(.secondary)
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 30)
                    .padding(.top, 20)
                Spacer()
                Text("Enter Passcode")
                dotsView
                    .offset(x: start ? 40 : 0)
                Spacer()
                numPadView
                    .padding(.bottom, 44)
            }
            .background(Color.clear)
        }
    }

    private var dotsView: some View {
        HStack(spacing: 20) {
            ForEach(0..<6) { index in
                Circle()
                    .strokeBorder(index <= passcode.count - 1 ? Color.clear : Color.secondary, lineWidth: 1)
                    .background(Circle().foregroundColor(index > passcode.count - 1 ? Color.clear : Color.secondary))
                    .frame(width: 14)
            }
        }
    }

    private var numPadView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(minimum: 60, maximum: 100)),
            GridItem(.flexible(minimum: 60, maximum: 100)),
            GridItem(.flexible(minimum: 60, maximum: 100)),
        ], spacing: 20) {
            Group {
                numberView(for: "1")
                numberView(for: "2", secondary: "abc")
                numberView(for: "3", secondary: "def")
                numberView(for: "4", secondary: "ghi")
                numberView(for: "5", secondary: "jkl")
                numberView(for: "6", secondary: "mno")
            }
            Group {
                numberView(for: "7", secondary: "pqrs")
                numberView(for: "8", secondary: "tuv")
                numberView(for: "9", secondary: "wxyz")
                Spacer()
                numberView(for: "0")
                Spacer()
            }
            Group {
                Spacer()
                Spacer()
                bottomButton
            }
        }
        .padding(.horizontal, 28)
    }

    private func numberView(for string: String, secondary: String? = nil) -> some View {
            Button {
                if passcode.count < 6 {
                    passcode.append(string)
                    if passcode.count == 6 {
                        if validation(passcode.joined()) {
                            withAnimation(.linear(duration: 0.25)) {
                                isOpened = true
                            }
                        } else {
                            start = true
                            withAnimation(Animation.spring(response: 0.2, dampingFraction: 0.17, blendDuration: 0.2)) {
                                start = false
                                passcode = []
                            }
                        }
                    }
                }
            } label: {
                Circle()
                    .foregroundColor(.secondary)
                    .overlay(
                        VStack(spacing: 0) {
                            Text(string)
                                .font(.system(.largeTitle))
                                .scaledToFit()
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                            if let secondary {
                                Text(secondary.uppercased())
                                    .font(.system(.callout).uppercaseSmallCaps())
                            }
                        }
                            .foregroundColor(.white)
                    )
                    .frame(width: 75)
            }
    }

    private var bottomButton: some View {
        Button(passcode.isEmpty ? "Cancel" : "Delete") {
            if passcode.isEmpty {
                onCancel()
            } else {
                isOpened = false
                passcode.removeLast()
            }
        }
    }
}

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}

//struct PasscodeView_PreviewsProvider: PreviewProvider {
//    static var previews: some View {
//        PasscodeView { _ in
//            true
//        }
//        PasscodeView(validation: { _ in
//            true
//        })
//            .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro Max"))
//    }
//}
