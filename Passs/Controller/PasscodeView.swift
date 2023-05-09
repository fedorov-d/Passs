//
//  PasscodeView.swift
//  Passs
//
//  Created by Dmitry Fedorov on 08.05.2023.
//

import SwiftUI

struct PasscodeView: View {
    enum StepType {
        case create
        case `repeat`
        case check

        var title: String {
            switch self {
            case .create:
                return "Create Passcode"
            case .repeat:
                return "Repeat Passcode"
            case .check:
                return "Enter Passcode"
            }
        }
    }

    struct Step {
        let type: StepType
        var input: String = ""
    }

    struct Scenario {
        var steps: [Step]
        var currentStepIndex = 0

        var currentStep: Step {
            steps[currentStepIndex]
        }

        mutating func completeCurrentStep() -> Bool {
            if currentStepIndex == steps.indices.last {
                return false
            }
            currentStepIndex += 1
            return true
        }
    }

    struct Config {
        var scenario: Scenario

        var onCancel: () -> Void
        var onCompleted: () -> Void
        var validation: (String) -> Bool
    }

    @State private var start = false
    @State private var isOpened = false

    @State var config: Config

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 0)
            TabView(selection: $config.scenario.currentStepIndex) {
                ForEach(0..<config.scenario.steps.count, id: \.self) { index in
                    let step = config.scenario.steps[index]
                    VStack(spacing: 15) {
                        Text(step.type.title)
                            .foregroundColor(Color(UIColor.label))
                            .font(.system(.title2))
                        dotsView
                            .frame(height: 14)
                            .offset(x: start ? 40 : 0)
                    }
                    .tag(index)
                    .transition(.slide)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .padding(.top, 20)
            Spacer()
            numPadView
                .padding(.bottom, 24)
        }
        .background(Color(UIColor.systemBackground))
    }

    private var dotsView: some View {
        HStack(spacing: 20) {
            ForEach(0..<6) { index in
                Circle()
                    .strokeBorder(index <= config.scenario.currentStep.input.count - 1 ? Color.clear : Color(UIColor.secondaryLabel), lineWidth: 1)
                    .background(Circle().foregroundColor(index > config.scenario.currentStep.input.count - 1 ? Color.clear : Color(UIColor.secondaryLabel)))
                    .frame(width: 12)
            }
        }
    }

    private var numPadView: some View {
        VStack(spacing: 20) {
            HStack(spacing: 30) {
                numberView(for: "1", secondary: " ")
                numberView(for: "2", secondary: "abc")
                numberView(for: "3", secondary: "def")
            }
            HStack(spacing: 30) {
                numberView(for: "4", secondary: "ghi")
                numberView(for: "5", secondary: "jkl")
                numberView(for: "6", secondary: "mno")
            }
            HStack(spacing: 30) {
                numberView(for: "7", secondary: "pqrs")
                numberView(for: "8", secondary: "tuv")
                numberView(for: "9", secondary: "wxyz")
            }
            HStack(spacing: 30) {
                Spacer()
                numberView(for: "0")
                Spacer()
            }
            HStack(spacing: 30) {
                Spacer(minLength: 0)
                bottomButton
            }
            .padding(.top, 20)
        }
        .padding(.horizontal, 38)
    }

    private func numberView(for string: String, secondary: String? = nil) -> some View {
            Button {
                guard config.scenario.currentStep.input.count <= 6 else { return }
                config.scenario.steps[config.scenario.currentStepIndex].input.append(string)
                guard config.scenario.currentStep.input.count == 6 else { return }
                withAnimation(.easeInOut(duration: 0.25)) {
                    _ = config.scenario.completeCurrentStep()
                }
//                if config.validation(passcode.joined()) {
//                    withAnimation(.linear(duration: 0.25)) {
//                        isOpened = true
//                    }
//                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
//                        config.onCompleted()
//                    }
//                } else {
//                    start = true
//                    withAnimation(Animation.spring(response: 0.2, dampingFraction: 0.17, blendDuration: 0.2)) {
//                        start = false
//                        passcode = []
//                    }
//                }
            } label: {
                Circle()
                    .foregroundColor(Color(UIColor.secondarySystemBackground))
                    .overlay(
                        VStack(spacing: -3) {
                            Text(string)
                                .font(.system(.largeTitle))
                                .scaledToFit()
                                .lineLimit(nil)
                                .fixedSize(horizontal: true, vertical: false)
                            if let secondary {
                                Text(secondary.uppercased())
                                    .font(.system(.footnote, design: .rounded))
                            }
                        }
                            .foregroundColor(Color(UIColor.label))
                    )
                    .frame(width: 75, height: 75)
            }
    }

    private var bottomButton: some View {
        Button(config.scenario.currentStep.input.isEmpty ? "Cancel" : "Delete") {
            if config.scenario.currentStep.input.isEmpty {
                config.onCancel()
            } else {
                isOpened = false
                config.scenario.steps[config.scenario.currentStepIndex].input.removeLast()
            }
        }
        .foregroundColor(Color(UIColor.keepCyan))
    }
}

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}

struct PasscodeView_PreviewsProvider: PreviewProvider {
    static var previews: some View {
        PasscodeView(config: PasscodeView.Config(
            scenario: .init(steps: [PasscodeView.Step(type: .create), PasscodeView.Step(type: .repeat)]),
            onCancel: {

            }, onCompleted: {

            }, validation: { _ in
                true
            }))
        .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))

        PasscodeView(config: PasscodeView.Config(
            scenario: .init(steps: [PasscodeView.Step(type: .create), PasscodeView.Step(type: .repeat)]),
            onCancel: {

            }, onCompleted: {

            }, validation: { _ in
                false
            }))
            .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro Max"))
    }
}
