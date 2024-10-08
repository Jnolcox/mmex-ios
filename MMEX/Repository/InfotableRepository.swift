//
//  InfotableRepository.swift
//  MMEX
//
//  Created by Lisheng Guan on 2024/9/18.
//

import Foundation
import SQLite

struct InfotableRepository: RepositoryProtocol {
    typealias RepositoryData = InfotableData

    let db: Connection
    init(_ db: Connection) {
        self.db = db
    }
    init?(_ db: Connection?) {
        guard let db else { return nil }
        self.db = db
    }

    static let repositoryName = "INFOTABLE_V1"
    static let table = SQLite.Table(repositoryName)

    // column    | type    | other
    // ----------+---------+------
    // INFOID    | INTEGER | NOT NULL PRIMARY KEY
    // INFONAME  | TEXT    | NOT NULL UNIQUE COLLATE NOCASE
    // INFOVALUE | TEXT    | NOT NULL

    // column expressions
    static let col_id    = SQLite.Expression<Int64>("INFOID")
    static let col_name  = SQLite.Expression<String>("INFONAME")
    static let col_value = SQLite.Expression<String>("INFOVALUE")

    static func selectData(from table: SQLite.Table) -> SQLite.Table {
        return table.select(
            col_id,
            col_name,
            col_value
        )
    }

    static func fetchData(_ row: SQLite.Row) -> InfotableData {
        return InfotableData(
            id    : row[col_id],
            name  : row[col_name],
            value : row[col_value]
        )
    }

    static func itemSetters(_ data: InfotableData) -> [SQLite.Setter] {
        return [
            col_name  <- data.name,
            col_value <- data.value
        ]
    }
}

extension InfotableRepository {
    // load all keys
    func load() -> [InfotableData] {
        return select(from: Self.table)
    }

    // load specific keys into a dictionary
    func load(for keys: [InfoKey]) -> [InfoKey: InfotableData] {
        var results: [InfoKey: InfotableData] = [:]
        for key in keys {
            if let info: InfotableData = (pluck(
                key: key.rawValue,
                from: Self.table.filter(Self.col_name == key.rawValue)
            )) {
                results[key] = info
            }
        }
        return results
    }

    // New Methods for Key-Value Pairs
    // Fetch value for a specific key, allowing for String or Int64
    func getValue<T>(for key: String, as type: T.Type) -> T? {
        if let info: InfotableData = (pluck(
            key: key,
            from: Self.table.filter(Self.col_name == key)
        )) {
            if type == String.self {
                return info.value as? T
            } else if type == Int64.self {
                return Int64(info.value) as? T
            }
        }
        return nil
    }

    // Update or insert a setting with support for String or Int64 values
    func setValue<T>(_ value: T, for key: String) {
        var stringValue: String
        if let stringVal = value as? String {
            stringValue = stringVal
        } else if let intVal = value as? Int64 {
            stringValue = String(intVal)
        } else {
            log.warning("Unsupported type for value")
            return
        }

        if var info: InfotableData = (pluck(
            key: key,
            from: Self.table.filter(Self.col_name == key)
        )) {
            // Update existing setting
            info.value = stringValue
            _ = update(info)
        } else {
            // Insert new setting
            var info = InfotableData(id: 0, name: key, value: stringValue)
            _ = insert(&info)
        }
    }
}
