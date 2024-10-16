//
//  Report.swift
//  MMEX
//
//  Created 2024-09-26 by George Ef (george.a.ef@gmail.com)
//

import Foundation
import SQLite

struct ReportData: ExportableEntity {
    var id              : DataId = 0
    var name            : String = ""
    var groupName       : String = ""
    var active          : Bool   = false
    var sqlContent      : String = ""
    var luaContent      : String = ""
    var templateContent : String = ""
    var description     : String = ""
}

extension ReportData: DataProtocol {
    static let dataName = ("Report", "Reports")

    func shortDesc() -> String {
        "\(self.name)"
    }
}

extension ReportData {
    static let sampleData: [ReportData] = [
    ]
}
