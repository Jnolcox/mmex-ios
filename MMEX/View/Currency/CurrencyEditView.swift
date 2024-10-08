//
//  CurrencyEditView.swift
//  MMEX
//
//  Created by Lisheng Guan on 2024/9/17.
//  Edited 2024-10-05 by George Ef (george.a.ef@gmail.com)
//

import SwiftUI

struct CurrencyEditView: View {
    @EnvironmentObject var env: EnvironmentManager
    @Binding var currency: CurrencyData
    @State var edit: Bool
    var onDelete: () -> Void = { }

    var format: String {
        let amount: Double = 12345.67
        return amount.formatted(by: currency.formatter)
    }

    var body: some View {
        return Form {
            Section {
                env.theme.field.text(edit, "Name") {
                    TextField("Cannot be empty!", text: $currency.name)
                        .textInputAutocapitalization(.sentences)
                } show: {
                    env.theme.field.valueOrError("Cannot be empty!", text: currency.name)
                }

                env.theme.field.text(edit, "Symbol") {
                    TextField("Cannot be empty!", text: $currency.symbol)
                        .textInputAutocapitalization(.characters)
                } show: {
                    env.theme.field.valueOrError("Cannot be empty!", text: currency.symbol)
                }

                env.theme.field.picker(edit, "Type") {
                    Picker("", selection: $currency.type) {
                        ForEach(CurrencyType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                } show: {
                    Text(currency.type.rawValue)
                }

                if edit || !currency.unitName.isEmpty {
                    env.theme.field.text(edit, "Unit Name") {
                        TextField("N/A", text: $currency.unitName)
                            .textInputAutocapitalization(.sentences)
                    }

                    if edit || !currency.centName.isEmpty {
                        env.theme.field.text(edit, "Cent Name") {
                            TextField("N/A", text: $currency.centName)
                                .textInputAutocapitalization(.sentences)
                        }
                    }
                }

                env.theme.field.text(edit, "Conversion Rate") {
                    TextField("Default is 0", value: $currency.baseConvRate, format: .number)
                        .keyboardType(.decimalPad)
                }
            }

            Section {
                env.theme.field.text(edit, "Format") {
                    Text(format)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.gray)
                }
                if edit {
                    env.theme.field.text(edit, "Prefix Symbol") {
                        TextField("N/A", text: $currency.prefixSymbol)
                            .textInputAutocapitalization(.characters)
                    }
                    env.theme.field.text(edit, "Suffix Symbol") {
                        TextField("N/A", text: $currency.suffixSymbol)
                            .textInputAutocapitalization(.characters)
                    }
                    env.theme.field.text(edit, "Decimal Point") {
                        TextField("N/A", text: $currency.decimalPoint)
                    }
                    env.theme.field.text(edit, "Thousands Separator") {
                        TextField("N/A", text: $currency.groupSeparator)
                    }
                    env.theme.field.text(edit, "Scale") {
                        TextField("Default is 0", value: $currency.scale, format: .number)
                            .keyboardType(.decimalPad)
                    }
                }
            }

            // delete currency if not in use
            if env.currencyCache[currency.id] == nil {
                Button("Delete Currency") {
                    onDelete()
                }
                .foregroundColor(.red)
            }
        }
        .textSelection(.enabled)
    }
}

#Preview("\(CurrencyData.sampleData[0].symbol) (show)") {
    CurrencyEditView(
        currency: .constant(CurrencyData.sampleData[0]),
        edit: false
    )
    .environmentObject(EnvironmentManager.sampleData)
}

#Preview("\(CurrencyData.sampleData[0].symbol) (edit)") {
    CurrencyEditView(
        currency: .constant(CurrencyData.sampleData[0]),
        edit: true
    )
    .environmentObject(EnvironmentManager.sampleData)
}

#Preview("\(CurrencyData.sampleData[1].symbol) (show)") {
    CurrencyEditView(
        currency: .constant(CurrencyData.sampleData[1]),
        edit: false
    )
    .environmentObject(EnvironmentManager.sampleData)
}

#Preview("\(CurrencyData.sampleData[1].symbol) (edit)") {
    CurrencyEditView(
        currency: .constant(CurrencyData.sampleData[1]),
        edit: true
    )
    .environmentObject(EnvironmentManager.sampleData)
}
