//
//  PasscodeView.swift
//  Passs
//
//  Created by Dmitry Fedorov on 08.05.2023.
//

import SwiftUI

struct PasscodeView: View {
    struct Scenario {
        struct Step {
            enum `Type` {
                case create
                case `repeat`
                case check(validate: (String?) -> Bool)

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

            let type: Type
            var input: String = ""
        }

        var steps: [Step]
        var currentStepIndex = 0

        var currentStep: Step {
            steps[currentStepIndex]
        }

        var onDismiss: () -> Void
        var onComplete: ((String) -> Void)?

        mutating func resetInput() {
            for index in steps.indices {
                steps[index].input = ""
            }
            currentStepIndex = 0
        }

        var isValidInput: Bool {
            guard currentStepIndex == steps.indices.last else { return true }
            switch currentStep.type {
            case .create:
                return true
            case .repeat:
                return Set(steps.map(\.input)).count == 1
            case .check(let validate):
                return validate(steps.last?.input)
            }
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
                numberView(primary: "1", secondary: " ")
                numberView(primary: "2", secondary: "abc")
                numberView(primary: "3", secondary: "def")
            }
            HStack(spacing: 30) {
                numberView(primary: "4", secondary: "ghi")
                numberView(primary: "5", secondary: "jkl")
                numberView(primary: "6", secondary: "mno")
            }
            HStack(spacing: 30) {
                numberView(primary: "7", secondary: "pqrs")
                numberView(primary: "8", secondary: "tuv")
                numberView(primary: "9", secondary: "wxyz")
            }
            HStack(spacing: 30) {
                Spacer()
                numberView(primary: "0")
                Spacer()
            }
            HStack(spacing: 30) {
                dismissButton
                Spacer(minLength: 0)
                bottomButton
            }
            .padding(.top, 20)
        }
        .padding(.horizontal, 38)
    }

    private func numberView(primary: String, secondary: String? = nil) -> some View {
            Button {
                guard scenario.currentStep.input.count < 6 else { return }
                scenario.steps[scenario.currentStepIndex].input.append(primary)
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
                        withAnimation(.easeInOut(duration: 0.4)) {
                            scenario.resetInput()
                        }
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        scenario.proceedToNextStepOrComplete()
                    }
                }
            } label: {
                numberLabel(primary: primary, secondary: secondary)
            }
    }

    private func numberLabel(primary: String, secondary: String? = nil) -> some View {
        Circle()
            .foregroundColor(Color(UIColor.secondarySystemBackground))
            .overlay(
                VStack(spacing: -3) {
                    Text(primary)
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

    private var bottomButton: some View {
        Button("Delete") {
            guard !scenario.currentStep.input.isEmpty else {
                return
            }
            scenario.steps[scenario.currentStepIndex].input.removeLast()
        }
        .foregroundColor(Color(UIColor.keepCyan))
    }

    private var dismissButton: some View {
        Button("Dismiss") {
            scenario.onDismiss()
        }
        .foregroundColor(Color(UIColor.keepCyan))
    }
}

struct PasscodeView_PreviewsProvider: PreviewProvider {
    static var previews: some View {
        PasscodeView(
            scenario: .init(
                steps: [PasscodeView.Scenario.Step(type: .create), PasscodeView.Scenario.Step(type: .repeat)],
                onDismiss: {}
            )
        )
        .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))

        PasscodeView(
            scenario: .init(
                steps: [PasscodeView.Scenario.Step(type: .create), PasscodeView.Scenario.Step(type: .repeat)],
                onDismiss: {}
            )
        )
            .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro Max"))
    }
}
