//
//  RepositoryCopyView.swift
//  MMEX
//
//  2024-11-16: Created by George Ef (george.a.ef@gmail.com)
//

import SwiftUI

struct RepositoryCopyView<
    MainData: DataProtocol,
    FormView: View
>: View {
    @EnvironmentObject var vm: ViewModel
    @Binding var isPresented: Bool
    let features: RepositoryFeatures
    @State var data: MainData
    @Binding var newData: MainData?
    var dismiss: DismissAction?
    @ViewBuilder var formView: (_ focus: Binding<Bool>, _ data: Binding<MainData>, _ edit: Bool) -> FormView

    @State private var focus = false
    @State private var alertIsPresented = false
    @State private var alertMessage: String?

    var body: some View {
        Form {
            formView($focus, $data, true)
        }
        .textSelection(.enabled)
        .scrollDismissesKeyboard(.immediately)
        
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    isPresented = false
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    if let updateError = data.update(vm) {
                        alertMessage = updateError
                        alertIsPresented = true
                    } else {
                        newData = data
                        isPresented = false
                        if let dismiss { dismiss() }
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                KeyboardFocus(focus: $focus)
            }
        }
        
        .alert(isPresented: $alertIsPresented) {
            Alert(
                title: Text("Error"),
                message: Text(alertMessage!),
                dismissButton: .default(Text("OK"))
            )
        }

        .onAppear {
            data.copy()
        }
    }
}

#Preview(AccountData.sampleData[0].name) {
    let data = AccountData.sampleData[0]
    let formView = { $focus, $data, edit in AccountFormView(
        focus: $focus,
        data: $data,
        edit: edit
    ) }
    MMEXPreview.manageSheet("Copy") { pref, vm in
        RepositoryCopyView(
            isPresented: .constant(true),
            features: RepositoryFeatures(),
            data: data,
            newData: .constant(nil),
            formView: formView
        )
    }
}
