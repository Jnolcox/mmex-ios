//
//  CurrencyEditView.swift
//  MMEX
//
//  Created by Lisheng Guan on 2024/9/17.
//

import SwiftUI

struct CurrencyEditView: View {
    @Binding var currency: Currency

    var body: some View {
        Form {
            Section(header: Text("Currency Name")) {
                TextField("Currency Name", text: $currency.name)
            }
            Section(header: Text("Prefix Symbol")) {
                TextField("Prefix Symbol", text: Binding(
                    get: { currency.prefixSymbol ?? "" },
                    set: { currency.prefixSymbol = $0.isEmpty ? nil : $0 }
                ))
            }
            Section(header: Text("Suffix Symbol")) {
                TextField("Suffix Symbol", text: Binding(
                    get: { currency.suffixSymbol ?? "" },
                    set: { currency.suffixSymbol = $0.isEmpty ? nil : $0 }
                ))
            }
            Section(header: Text("Scale")) {
                TextField("Scale", value: $currency.scale, format: .number)
            }
            Section(header: Text("Conversion Rate")) {
                TextField("Conversion Rate", value: $currency.baseConversionRate, format: .number)
            }
            Section(header: Text("Currency Type")) {
                TextField("Currency Type", text: $currency.type)
            }
        }
        .navigationTitle("Edit Currency")
    }
}

#Preview {
    CurrencyEditView(currency: .constant(Currency.sampleData[0]))
}