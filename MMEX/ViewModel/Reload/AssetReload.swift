//
//  AssetReload.swift
//  MMEX
//
//  2024-10-28: Created by George Ef (george.a.ef@gmail.com)
//

import SwiftUI
import SQLite

extension ViewModel {
    func reloadAssetList(_ oldData: AssetData?, _ newData: AssetData?) async {
        log.trace("DEBUG: ViewModel.reloadAssetList(main=\(Thread.isMainThread))")

        if let newData {
            if env.currencyCache[newData.currencyId] == nil {
                env.loadCurrency()
            }
        }

        if let currencyUsed = currencyList.used.readyValue {
            let oldCurrency = oldData?.currencyId
            let newCurrency = newData?.currencyId
            if let oldCurrency, newCurrency != oldCurrency {
                currencyList.used.unload()
            } else if let newCurrency, !currencyUsed.contains(newCurrency) {
                if currencyList.used.state.unloading() {
                    currencyList.used.value.insert(newCurrency)
                    currencyList.used.state.loaded()
                }
            }
        }

        // save isExpanded
        let groupIsExpanded: [Bool]? = assetGroup.readyValue?.map { $0.isExpanded }
        let currencyIndex: [DataId: Int] = Dictionary(
            uniqueKeysWithValues: assetGroup.groupCurrency.enumerated().map { ($0.1, $0.0) }
        )

        unloadAssetGroup()
        assetList.state.unload()

        if (oldData != nil) != (newData != nil) {
            manageList.unload()
            assetList.count.unload()
        }

        if assetList.data.state.unloading() {
            if let newData {
                assetList.data.value[newData.id] = newData
            } else if let oldData {
                assetList.data.value[oldData.id] = nil
            }
            assetList.data.state.loaded()
        }

        if assetList.name.state.unloading() {
            if let newData {
                assetList.name.value[newData.id] = newData.name
            } else if let oldData {
                assetList.name.value[oldData.id] = nil
            }
            assetList.name.state.loaded()
        }

        assetList.order.unload()

        if let _ = newData {
            assetList.att.state.unload()
        } else if let oldData {
            if assetList.att.state.unloading() {
                assetList.att.value[oldData.id] = nil
                assetList.att.state.loaded()
            }
        }

        await loadAssetList()
        loadAssetGroup(choice: assetGroup.choice)

        // restore isExpanded
        if let groupIsExpanded { switch assetGroup.choice {
        case .currency:
            for (g, currencyId) in assetGroup.groupCurrency.enumerated() {
                guard let i = currencyIndex[currencyId] else { continue }
                assetGroup.value[g].isExpanded = groupIsExpanded[i]
            }
        default:
            if assetGroup.value.count == groupIsExpanded.count {
                for g in 0 ..< groupIsExpanded.count {
                    assetGroup.value[g].isExpanded = groupIsExpanded[g]
                }
            }
        } }
    }
}