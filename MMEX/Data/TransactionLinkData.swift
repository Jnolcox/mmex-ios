//
//  TransactionLinkData.swift
//  MMEX
//
//  Created 2024-09-26 by George Ef (george.a.ef@gmail.com)
//

import Foundation
import SQLite


/// copy from MMEX4Desktop
enum CHECKING_TYPE: DataId {
    case AS_INCOME_EXPENSE = 32701
    case AS_TRANSFER
}

struct TransactionLinkData: ExportableEntity {
    var id      : DataId  = 0
    var transId : DataId  = 0
    var refType : RefType = RefType.asset
    var refId   : DataId  = 0
    static let refTypes: Set<RefType> = [ .asset, .stock ]
}

extension TransactionLinkData: DataProtocol {
    static let dataName = ("Transaction Link", "Transaction Links")

    func shortDesc() -> String {
        "\(self.id)"
    }
}

extension TransactionLinkData {
    static let sampleData: [TransactionLinkData] = [
    ]
}
