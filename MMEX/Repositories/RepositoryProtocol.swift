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

    var db: Connection { get }

    static var repositoryName: String { get }
    static var table: SQLite.Table { get }
    static func selectData(from table: SQLite.Table) -> SQLite.Table
    static func fetchData(_ row: SQLite.Row) -> RepositoryData
    static var col_id: SQLite.Expression<Int64> { get }
    static func itemSetters(_ item: RepositoryData) -> [SQLite.Setter]
}

extension RepositoryProtocol {
    func pluck<Result>(
        key: String,
        from table: SQLite.Table,
        with result: (SQLite.Row) -> Result = Self.fetchData
    ) -> Result? {
        do {
            if let row = try db.pluck(Self.selectData(from: table)) {
                let data = result(row)
                print("Successfull pluck of \(key) from \(Self.repositoryName)")
                return data
            } else {
                print("Unsuccefull pluck of \(key) from \(Self.repositoryName)")
                return nil
            }
        } catch {
            print("Failed pluck of \(key) from \(Self.repositoryName): \(error)")
            return nil
        }
    }

    func pluck<Result>(
        id: Int64,
        with result: (SQLite.Row) -> Result = Self.fetchData
    ) -> Result? {
        pluck(
            key: "id \(id)",
            from: Self.table.filter(Self.col_id == id),
            with: result
        )
    }

    func select<Result>(
        from table: SQLite.Table,
        with result: (SQLite.Row) -> Result = Self.fetchData
    ) -> [Result] {
        do {
            var data: [Result] = []
            for row in try db.prepare(Self.selectData(from: table)) {
                data.append(result(row))
            }
            print("Successfull select from \(Self.repositoryName): \(data.count)")
            return data
        } catch {
            print("Failed select from \(Self.repositoryName): \(error)")
            return []
        }
    }

    func dictionary<Result>(
        from table: SQLite.Table,
        with result: (SQLite.Row) -> Result = Self.fetchData
    ) -> [Int64: Result] {
        do {
            var dict: [Int64: Result] = [:]
            for row in try db.prepare(Self.selectData(from: table)) {
                dict[row[Self.col_id]] = result(row)
            }
            print("Successfull dictionary from \(Self.repositoryName): \(dict.count)")
            return dict
        } catch {
            print("Failed dictionary from \(Self.repositoryName): \(error)")
            return [:]
        }
    }

    func insert(_ data: inout RepositoryData) -> Bool {
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

    func deleteAll() -> Bool {
        do {
            let query = Self.table.delete()
            try db.run(query)
            print("Successfull delete all in \(RepositoryData.dataName)")
            return true
        } catch {
            print("Failed delete all in \(RepositoryData.dataName): \(error)")
            return false
        }
    }
}

/*
extension RepositoryProtocol {
    func create() {
        var query: String = "CREATE TABLE \(Self.repositoryName)("
        var comma = false
        for (name, type, other) in Self.columns {
            if comma { query.append(", ") }
            var space = false
            if !name.isEmpty {
                query.append("\(name) \(type)")
                space = true
            }
            if !other.isEmpty {
                if space { query.append(" ") }
                query.append("\(other)")
            }
            comma = true
        }
        query.append(")")
        print("Executing query: \(query)")
        do {
            try db.execute(query)
        } catch {
            print("Failed to create table \(Self.repositoryName): \(error)")
        }
    }
*/