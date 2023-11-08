//
//  PasscodeView.swift
//  Passs
//
//  Created by Dmitry Fedorov on 08.05.2023.
//

import SwiftUI

struct PasscodeView: View {
    @State private var isValidInput = true
    @State var scenario: Scenario

    var body: some View {
        GeometryReader { _ in
            VStack(spacing: 10) {
                Spacer(minLength: 0)
                titleAndDotsPages
                Spacer(minLength: 0)
                numPad
                    .padding(.bottom, 24)
            }
            .background(Color(UIColor.systemBackground))
        }
        .ignoresSafeArea(.keyboard)
        .onDisappear {
            scenario.onDismiss?()
        }
    }

    private let passcodeLenght = 6

    private var titleAndDotsPages: some View {
        TabView(selection: $scenario.currentStepIndex) {
            ForEach(scenario.steps.indices, id: \.self) { index in
                let step = scenario.steps[index]
                VStack(spacing: 15) {
                    Text(step.type.title)
                        .foregroundColor(Color(UIColor.label))
                        .font(.system(.title2))
                    dots
                        .frame(height: 14)
                        .offset(x: isValidInput ? 0 : index == scenario.steps.indices.last ? 40 : 0)
                }
                .transition(.slide)
                    .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .padding(.top, 20)
    }

    private var dots: some View {
        HStack(spacing: 20) {
            ForEach(0..<passcodeLenght, id: \.self) { index in
                Circle()
                    .strokeBorder(index <= scenario.currentStep.input.count - 1
                                  ? Color.clear
                                  : Color(UIColor.secondaryLabel),
                                  lineWidth: 1)
                    .background(Circle()
                        .foregroundColor(index > scenario.currentStep.input.count - 1
                                         ? Color.clear
                                         : Color(UIColor.secondaryLabel)))
                    .frame(width: 12)
            }
        }
    }

    private var numPad: some View {
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
                Spacer(minLength: 0)
                numberView(primary: "0")
                Spacer(minLength: 0)
            }
            HStack(spacing: 30) {
                if scenario.onDismiss != nil {
                    dismissButton
                }
                Spacer(minLength: 0)
                bottomButton
            }
            .padding(.top, 20)
        }
        .padding(.horizontal, 38)
    }

    private func numberView(primary: String, secondary: String? = nil) -> some View {
        Button {
            guard scenario.currentStep.input.count < passcodeLenght else { return }
            scenario.steps[scenario.currentStepIndex].input.append(primary)
            guard scenario.currentStep.input.count == passcodeLenght else { return }
            validateInput()
        } label: {
            Circle()
                .foregroundColor(Color(UIColor.secondarySystemBackground))
                .overlay(numberLabel(primary: primary, secondary: secondary))
                .frame(width: 75, height: 75)
        }
    }

    private func numberLabel(primary: String, secondary: String? = nil) -> some View {
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
            scenario.onDismiss?()
            scenario.onDismiss = nil
        }
        .foregroundColor(Color(UIColor.keepCyan))
    }

    private func validateInput() {
        if scenario.isValidInput {
            withAnimation(.easeInOut(duration: 0.25)) {
                scenario.proceedToNextStepOrComplete()
            }
        } else {
            isValidInput = false
            let impactMed = UIImpactFeedbackGenerator(style: .heavy)
            impactMed.impactOccurred()
            withAnimation(Animation.spring(response: 0.2,
                                           dampingFraction: 0.17,
                                           blendDuration: 0.2)) {
                isValidInput = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(400)) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    scenario.resetInput()
                }
            }

        }
    }
}

extension PasscodeView {
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

        var onDismiss: (() -> Void)?
        var onComplete: ((String) -> Void)?

        mutating func resetInput() {
            for index in steps.indices {
                steps[index].input = ""
            }
            currentStepIndex = 0
        }

        var isValidInput: Bool {
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
