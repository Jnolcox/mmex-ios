//
//  AccountDetailView.swift
//  MMEX
//
//  Created by Lisheng Guan on 2024/9/5.
//

import SwiftUI

struct AccountDetailView: View {
    @State var account: Account
    let databaseURL: URL
    
    @State private var editingAccount = Account.empty
    @State private var isPresentingEditView = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        List {
            Section(header: Text("Account Name")) {
                Text(account.name)
            }
            Section(header: Text("Account Type")) {
                Text(account.type)
            }
            Section(header: Text("Status")) {
                Text(account.status.id)
            }
            Section(header: Text("Balance")) {
                Text("\(account.balance ?? 0.0)")
            }
            Section(header: Text("Notes")) {
                if let notes = account.notes {
                    Text(notes)  // Display notes if they are not nil
                } else {
                    Text("No notes available")  // Fallback text if notes are nil
                }
            }
            Button("Delete Payee") {
                deleteAccount()
            }
        }
        .toolbar {
            Button("Edit") {
                isPresentingEditView = true
                editingAccount = account
            }
        }
        .sheet(isPresented: $isPresentingEditView) {
            NavigationStack {
                AccountEditView(account: $editingAccount)
                    .navigationTitle(account.name)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                isPresentingEditView = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                isPresentingEditView = false
                                account = editingAccount
                                saveChanges()
                            }
                        }
                    }
            }
        }
        .navigationTitle("Account Details")
    }
    
    func saveChanges() {
        let repository = DataManager(databaseURL: databaseURL).getAccountRepository()
        if repository.updateAccount(account: account) {
            // Successfully updated
        } else {
            // Handle failure
        }
    }
    
    func deleteAccount() {
        let repository = DataManager(databaseURL: databaseURL).getAccountRepository()
        if repository.deleteAccount(account: account) {
            presentationMode.wrappedValue.dismiss()
        } else {
            // Handle deletion failure
        }
    }
}