//
//  PasscodeView.swift
//  Passs
//
//  Created by Dmitry Fedorov on 08.05.2023.
//

import SwiftUI

struct PasscodeView: View {
    enum StepType: String {
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

        var onDismiss: () -> Void
        var onComplete: ((String) -> Void)?
        var validate: ((String) -> Bool)?

        mutating func resetInput() {
            for index in steps.indices {
                steps[index].input = ""
            }
            currentStepIndex = 0
        }

        var isValidInput: Bool {
            guard currentStepIndex == steps.indices.last else { return true }
            if case .repeat = currentStep.type {
                return Set(steps.map(\.input)).count == 1
            }
            return true
        }

        mutating func proceedToNextStepOrComplete() {
            if currentStepIndex == steps.indices.last, let input = steps.last?.input {
                onComplete?(input)
            } else {
                currentStepIndex += 1
            }
        }
    }

    @State private var isValidInput = true
    @State private var isOpened = false

    @State var scenario: Scenario

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 0)
            TabView(selection: $scenario.currentStepIndex) {
                ForEach(0..<scenario.steps.count, id: \.self) { index in
                    let step = scenario.steps[index]
                    VStack(spacing: 15) {
                        Text(step.type.title)
                            .foregroundColor(Color(UIColor.label))
                            .font(.system(.title2))
                        dotsView
                            .frame(height: 14)
                            .offset(x: isValidInput ? 0 : 40)
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
                    .strokeBorder(index <= scenario.currentStep.input.count - 1 ? Color.clear : Color(UIColor.secondaryLabel), lineWidth: 1)
                    .background(Circle().foregroundColor(index > scenario.currentStep.input.count - 1 ? Color.clear : Color(UIColor.secondaryLabel)))
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
                guard scenario.currentStep.input.count < 6 else { return }
                scenario.steps[scenario.currentStepIndex].input.append(string)
                guard scenario.currentStep.input.count == 6 else { return }
                if !scenario.isValidInput {
                    isValidInput = false
                    let impactMed = UIImpactFeedbackGenerator(style: .heavy)
                    impactMed.impactOccurred()
                    withAnimation(Animation.spring(response: 0.2,
                                                   dampingFraction: 0.17,
                                                   blendDuration: 0.2)) {
                        isValidInput = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            scenario.resetInput()
                        }
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        scenario.proceedToNextStepOrComplete()
                    }
                }
            } label: {
                numberLabel(for: string, secondaryLabel: secondary)
            }
    }

    private func numberLabel(for primaryLabel: String, secondaryLabel: String? = nil) -> some View {
        Circle()
            .foregroundColor(Color(UIColor.secondarySystemBackground))
            .overlay(
                VStack(spacing: -3) {
                    Text(primaryLabel)
                        .font(.system(.largeTitle))
                        .scaledToFit()
                        .lineLimit(nil)
                        .fixedSize(horizontal: true, vertical: false)
                    if let secondaryLabel {
                        Text(secondaryLabel.uppercased())
                            .font(.system(.footnote, design: .rounded))
                    }
                }
                    .foregroundColor(Color(UIColor.label))
            )
            .frame(width: 75, height: 75)
    }

    private var bottomButton: some View {
        Button(scenario.currentStep.input.isEmpty ? "Cancel" : "Delete") {
            if scenario.currentStep.input.isEmpty {
                scenario.onDismiss()
            } else {
                isOpened = false
                scenario.steps[scenario.currentStepIndex].input.removeLast()
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
        PasscodeView(
            scenario: .init(
                steps: [PasscodeView.Step(type: .create), PasscodeView.Step(type: .repeat)],
                onDismiss: {}
            )
        )
        .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))

        PasscodeView(
            scenario: .init(
                steps: [PasscodeView.Step(type: .create), PasscodeView.Step(type: .repeat)],
                onDismiss: {}
            )
        )
            .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro Max"))
    }
}
