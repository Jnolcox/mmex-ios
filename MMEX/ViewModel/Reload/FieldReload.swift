//
//  FieldReload.swift
//  MMEX
//
//  2024-11-23: Created by George Ef (george.a.ef@gmail.com)
//

import SwiftUI
import SQLite

extension ViewModel {
    func reloadField(_ oldData: FieldData?, _ newData: FieldData?) async {
        log.trace("DEBUG: ViewModel.reloadField(main=\(Thread.isMainThread))")

        // save isExpanded
        let groupIsExpanded: [Bool]? = fieldGroup.readyValue?.map { $0.isExpanded }

        unloadFieldGroup()
        fieldList.unload()

        if (oldData != nil) != (newData != nil) {
            fieldList.count.unload()
        }

        if fieldList.data.state.unloading() {
            if let newData {
                fieldList.data.value[newData.id] = newData
            } else if let oldData {
                fieldList.data.value[oldData.id] = nil
            }
            fieldList.data.state.loaded()
        }

        fieldList.order.unload()

        await loadFieldList()
        loadFieldGroup(choice: fieldGroup.choice)

        // restore isExpanded
        if let groupIsExpanded { switch fieldGroup.choice {
        default:
            if fieldGroup.value.count == groupIsExpanded.count {
                for g in 0 ..< groupIsExpanded.count {
                    fieldGroup.value[g].isExpanded = groupIsExpanded[g]
                }
            }
        } }

        log.info("INFO: ViewModel.reloadField(main=\(Thread.isMainThread))")
    }

    func reloadFieldUsed(_ oldId: DataId?, _ newId: DataId?) {
        log.trace("DEBUG: ViewModel.reloadFieldUsed(main=\(Thread.isMainThread), \(oldId?.value ?? 0), \(newId?.value ?? 0))")
        guard let fieldUsed = fieldList.used.readyValue else { return }
        if let oldId, newId != oldId {
            if fieldGroup.choice == .used {
                unloadFieldGroup()
            }
            fieldList.unload()
            fieldList.used.unload()
        } else if let newId, !fieldUsed.contains(newId) {
            if fieldGroup.choice == .used {
                unloadFieldGroup()
            }
            if fieldList.used.state.unloading() {
                fieldList.used.value.insert(newId)
                fieldList.used.state.loaded()
            }
        }
    }
}