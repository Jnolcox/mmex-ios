//
//  RepositoryProtocaol.swift
//  MMEX
//
//  Created 2024-09-22 by George Ef (george.a.ef@gmail.com)
//

import Foundation
import SQLite

protocol RepositoryProtocol {
    associatedtype RepositoryData: DataProtocol

    var db: Connection? { get }

    static var repositoryName: String { get }
    static var table: SQLite.Table { get }
    static func selectQuery(from table: SQLite.Table) -> SQLite.Table
    static func selectData(_ row: SQLite.Row) -> RepositoryData
    static var col_id: SQLite.Expression<Int64> { get }
    static func itemSetters(_ item: RepositoryData) -> [SQLite.Setter]
}

extension RepositoryProtocol {
    func pluck(from table: SQLite.Table, key: String) -> RepositoryData? {
        guard let db else { return nil }
        do {
            if let row = try db.pluck(Self.selectQuery(from: table)) {
                let data = Self.selectData(row)
                print("Successfull pluck for \(key) in \(Self.repositoryName): \(data.shortDesc())")
                return data
            }
            else {
                print("Unsuccefull pluck for \(key) in \(Self.repositoryName)")
                return nil
            }
        } catch {
            print("Failed pluck for \(key) in \(Self.repositoryName): \(error)")
            return nil
        }
    }

    func select(from table: SQLite.Table) -> [RepositoryData] {
        guard let db else { return [] }
        do {
            var data: [RepositoryData] = []
            for row in try db.prepare(Self.selectQuery(from: table)) {
                data.append(Self.selectData(row))
            }
            print("Successfull select from \(Self.repositoryName): \(data.count)")
            return data
        } catch {
            print("Failed select from \(Self.repositoryName): \(error)")
            return []
        }
    }

    func insert(_ data: inout RepositoryData) -> Bool {
        guard let db else { return false }
        do {
            let query = Self.table
                .insert(Self.itemSetters(data))
            let rowid = try db.run(query)
            data.id = rowid
            print("Successfull insert in \(RepositoryData.dataName): \(data.shortDesc())")
            return true
        } catch {
            print("Failed insert in \(RepositoryData.dataName): \(error)")
            return false
        }
    }

    func update(_ data: RepositoryData) -> Bool {
        guard let db else { return false }
        guard data.id > 0 else { return false }
        do {
            let query = Self.table
                .filter(Self.col_id == data.id)
                .update(Self.itemSetters(data))
            try db.run(query)
            print("Successfull update in \(RepositoryData.dataName): \(data.shortDesc())")
            return true
        } catch {
            print("Failed update in \(RepositoryData.dataName): \(error)")
            return false
        }
    }

    func delete(_ data: RepositoryData) -> Bool {
        guard let db else { return false }
        guard data.id > 0 else { return false }
        do {
            let query = Self.table
                .filter(Self.col_id == data.id)
                .delete()
            try db.run(query)
            print("Successfull delete in \(RepositoryData.dataName): \(data.shortDesc())")
            return true
        } catch {
            print("Failed delete in \(RepositoryData.dataName): \(error)")
            return false
        }
    }
}