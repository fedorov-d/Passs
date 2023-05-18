//
//  UnlockView.swift
//  Passs
//
//  Created by Dmitry on 09.05.2023.
//

import SwiftUI

struct UnlockForm<InputView: View>: View {
    internal init(buttonDisabled: Bool, @ViewBuilder inputView: @escaping () -> InputView) {
        self.buttonDisabled = buttonDisabled
        self.inputView = inputView
    }

    @State private var faceID: Bool = false
    @State private var unlock = ["FaceID", "Passcode"]
    private var buttonDisabled: Bool
    @ViewBuilder private var inputView: () -> InputView

    var body: some View {
        NavigationView {
            Form {
                unlockDataSection
                quickUnlockSection
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        print("Help tapped!")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        print("Help tapped!")
                    }, label: {
                        Text("Unlock").bold()
                    })
                    .disabled(buttonDisabled)
                }
            }
            .navigationTitle("Unlock")
            .navigationBarTitleDisplayMode(.inline)
        }

    }

    private var unlockDataSection: some View {
        Section(content: {
            VStack{
                inputView()
                HStack {
                    Button {
                        print("select key file")
                    } label: {
                        Text("Select key file")
                    }
                    .foregroundColor(.blue)
                    .buttonStyle(PlainButtonStyle())
                    Spacer()
                }
                .frame(height: 32)
            }
        }, header: {
            Text("Unlock data")
        }, footer: {
            Text("Key file is not selected")
        })
    }

    private var quickUnlockSection: some View {
        Section {
            VStack(spacing: 20) {
                Toggle(isOn: $faceID) {
                    Text("Face ID")
                }
                NavigationLink {
                    PasscodeView(scenario: .init(steps: [
                        .init(type: .create),
                        .init(type: .repeat)
                    ], onDismiss: {
                        faceID = false
                    }))
                } label: {
                    HStack {
                        Text("Passcode")
                        Spacer()
                        Text("Not set")
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                }
            }
        } header: {
            Text("Save unlock data")
        } footer: {
            Text("Pssword and master key will be saved to device keychain")
        }
    }
}

struct UnlockViewContainer: View {
    var body: some View {
        if #available(iOS 15, *) {
            UnlockViewNew()
        } else {
            UnlockView()
        }
    }
}

struct UnlockView: View {
    @State private var password: String = ""
    var body: some View {
        UnlockForm(buttonDisabled: password.isEmpty) {
            SecureField("Password", text: $password)
        }
    }
}

@available(iOS 15.0, *)
struct UnlockViewNew: View {
    @State private var password: String = ""
    @FocusState private var isEditing: Bool

    var body: some View {
        UnlockForm(buttonDisabled: password.isEmpty) {
            SecureField("Password", text: $password)
                .focused($isEditing)
        }
        .onAppear {
            isEditing = true
        }
    }
}

extension View {
    
}

struct UnlockView_Previews: PreviewProvider {
    static var previews: some View {
        UnlockView()
            .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))
        UnlockView()
            .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro Max"))
    }
}
