//
//  TransactionLinkData.swift
//  MMEX
//
//  Created 2024-09-26 by George Ef (george.a.ef@gmail.com)
//

import Foundation
import SQLite

struct TransactionLinkData: ExportableEntity {
    var id      : Int64   = 0
    var transId : Int64   = 0
    var refType : RefType = RefType.asset
    var refId   : Int64   = 0
    static let refTypes: Set<RefType> = [ .asset, .stock ]
}

extension TransactionLinkData: DataProtocol {
    static let dataName = "TransactionLink"

    func shortDesc() -> String {
        "\(self.id)"
    }
}

extension TransactionLinkData {
    static let sampleData: [TransactionLinkData] = [
    ]
}