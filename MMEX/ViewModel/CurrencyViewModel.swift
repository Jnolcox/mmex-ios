//
//  CurrencyViewModel.swift
//  MMEX
//
//  2024-10-20: Created by George Ef (george.a.ef@gmail.com)
//

import SwiftUI

enum CurrencyGroupChoice: String, RepositoryGroupChoiceProtocol {
    case all      = "All"
    case used     = "Used"
    static let defaultValue = Self.all
    static let isSingleton: Set<Self> = [.all]
}

struct CurrencyGroup: RepositoryLoadGroupProtocol {
    typealias GroupChoice    = CurrencyGroupChoice
    typealias MainRepository = CurrencyRepository
    
    var choice: GroupChoice = .defaultValue
    var state: RepositoryLoadState<[RepositoryGroupData]> = .init()
    var isVisible  : [Bool] = []
    var isExpanded : [Bool] = []
}

extension RepositoryViewModel {
    func loadCurrencyList() async {
        log.trace("DEBUG: RepositoryViewModel.loadCurrencyList(main=\(Thread.isMainThread))")
        let queueOk = await withTaskGroup(of: Bool.self) { queue -> Bool in
            load(queue: &queue, keyPath: \Self.currencyData)
            load(queue: &queue, keyPath: \Self.currencyOrder)
            load(queue: &queue, keyPath: \Self.currencyUsed)
            return await allOk(queue: queue)
        }
        currencyList.state = queueOk ? .ready(()) : .error("Cannot load data.")
        if queueOk {
            log.info("INFO: RepositoryViewModel.loadCurrencyList(main=\(Thread.isMainThread)): Ready.")
        } else {
            log.debug("ERROR: RepositoryViewModel.loadCurrencyList(main=\(Thread.isMainThread)): Cannot load data.")
            return
        }
    }

    func unloadCurrencyList() {
        log.trace("DEBUG: RepositoryViewModel.unloadCurrencyList(main=\(Thread.isMainThread))")
        currencyData.unload()
        currencyOrder.unload()
        currencyUsed.unload()
        currencyList.state = .idle
    }
}

extension RepositoryViewModel {
    func unloadCurrencyGroup() -> Bool? {
        log.trace("DEBUG: RepositoryViewModel.unloadCurrencyGroup(main=\(Thread.isMainThread))")
        if case .loading = currencyGroup.state { return nil }
        currencyGroup.state = .idle
        currencyGroup.isVisible  = []
        currencyGroup.isExpanded = []
        return true
    }
}
