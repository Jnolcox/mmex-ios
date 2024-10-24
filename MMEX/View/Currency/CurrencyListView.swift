//
//  CurrencyListView.swift
//  MMEX
//
//  Created by Lisheng Guan on 2024/9/17.
//

import SwiftUI

struct CurrencyListView: View {
    @EnvironmentObject var env: EnvironmentManager // Access EnvironmentManager

    @State private var allCurrencyData: [CurrencyData] = [] // sorted by name
    @State private var isExpanded: [Bool : Bool] = [true: true, false: false]
    @State private var isPresentingAddView = false
    @State private var newCurrency = emptyCurrency

    static let emptyCurrency = CurrencyData(
        decimalPoint   : ".",
        groupSeparator : ",",
        scale          : 100,
        baseConvRate   : 1.0
    )

    var body: some View {
        Group {
            List { ForEach([true, false], id: \.self) { inUse in
                Section(header: HStack {
                    Button(action: {
                        isExpanded[inUse]?.toggle()
                    }) {
                        env.theme.group.view(
                            name: { Text(inUse ? "Used" : "Not Used") },
                            isExpanded: isExpanded[inUse] == true
                        )
                    }
                }) {
                    if isExpanded[inUse] == true {
                        ForEach($allCurrencyData) { $currency in
                            if (env.currencyCache[currency.id] != nil) == inUse {
                                NavigationLink(destination: CurrencyDetailView(
                                    currency: $currency
                                ) ) { HStack {
                                    Text(currency.name)
                                    Spacer()
                                    Text(currency.symbol)
                                } }
                            }
                        }
                    }
                }//.listSectionSpacing(10)
                //Text("end")
            } }
            .toolbar {
                Button(action: {
                    isPresentingAddView = true
                }, label: {
                    Image(systemName: "plus")
                })
            }
        }
        .navigationTitle("Currencies")
        .onAppear {
            loadCurrencyData()
        }
        .sheet(isPresented: $isPresentingAddView) {
            CurrencyAddView(
                newCurrency: $newCurrency,
                isPresentingAddView: $isPresentingAddView
            ) { currency in
                addCurrency(&currency)
                newCurrency = Self.emptyCurrency
            }
        }
    }

    func loadCurrencyData() {
        let repository = CurrencyRepository(env)
        DispatchQueue.global(qos: .background).async {
            let data = repository?.load() ?? []
            // Update UI on the main thread
            DispatchQueue.main.async {
                self.allCurrencyData = data
            }
        }
    }

    func addCurrency(_ currency: inout CurrencyData) {
        guard let repository = CurrencyRepository(env) else { return }
        if repository.insert(&currency) {
            self.loadCurrencyData()
        } else {
            // TODO
        }
    }
}

#Preview {
    CurrencyListView(
    )
    .environmentObject(EnvironmentManager.sampleData)
}
