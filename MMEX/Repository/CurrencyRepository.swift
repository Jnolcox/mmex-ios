//
//  CurrencyRepository.swift
//  MMEX
//
//  Created by Lisheng Guan on 2024/9/13.
//

import Foundation
import SQLite

struct CurrencyRepository: RepositoryProtocol {
    typealias RepositoryData = CurrencyData

    let db: Connection
    init(_ db: Connection) {
        self.db = db
    }
    init?(_ db: Connection?) {
        guard let db else { return nil }
        self.db = db
    }

    static let repositoryName = "CURRENCYFORMATS_V1"
    static let table = SQLite.Table(repositoryName)

    // column          | type    | other
    // ----------------+---------+------
    // CURRENCYID      | INTEGER | PRIMARY KEY
    // CURRENCYNAME    | TEXT    | NOT NULL COLLATE NOCASE UNIQUE
    // PFX_SYMBOL      | TEXT    |
    // SFX_SYMBOL      | TEXT    |
    // DECIMAL_POINT   | TEXT    |
    // GROUP_SEPARATOR | TEXT    |
    // UNIT_NAME       | TEXT    | COLLATE NOCASE
    // CENT_NAME       | TEXT    | COLLATE NOCASE
    // SCALE           | INTEGER |
    // BASECONVRATE    | NUMERIC |
    // CURRENCY_SYMBOL | TEXT    | NOT NULL COLLATE NOCASE UNIQUE
    // CURRENCY_TYPE   | TEXT    | NOT NULL (Fiat, Crypto)

    // column expressions
    static let col_id             = SQLite.Expression<Int64>("CURRENCYID")
    static let col_name           = SQLite.Expression<String>("CURRENCYNAME")
    static let col_prefixSymbol   = SQLite.Expression<String?>("PFX_SYMBOL")
    static let col_suffixSymbol   = SQLite.Expression<String?>("SFX_SYMBOL")
    static let col_decimalPoint   = SQLite.Expression<String?>("DECIMAL_POINT")
    static let col_groupSeparator = SQLite.Expression<String?>("GROUP_SEPARATOR")
    static let col_unitName       = SQLite.Expression<String?>("UNIT_NAME")
    static let col_centName       = SQLite.Expression<String?>("CENT_NAME")
    static let col_scale          = SQLite.Expression<Int?>("SCALE")
    static let col_baseConvRate   = SQLite.Expression<Double?>("BASECONVRATE")
    static let col_symbol         = SQLite.Expression<String>("CURRENCY_SYMBOL")
    static let col_type           = SQLite.Expression<String>("CURRENCY_TYPE")

    // cast NUMERIC to REAL
    static let cast_baseConvRate = cast(col_baseConvRate) as SQLite.Expression<Double?>

    static func selectData(from table: SQLite.Table) -> SQLite.Table {
        return table.select(
            col_id,
            col_name,
            col_prefixSymbol,
            col_suffixSymbol,
            col_decimalPoint,
            col_groupSeparator,
            col_unitName,
            col_centName,
            col_scale,
            cast_baseConvRate,
            col_symbol,
            col_type
        )
    }

    static func fetchData(_ row: SQLite.Row) -> CurrencyData {
        return CurrencyData(
            id             : row[col_id],
            name           : row[col_name],
            prefixSymbol   : row[col_prefixSymbol] ?? "",
            suffixSymbol   : row[col_suffixSymbol] ?? "",
            decimalPoint   : row[col_decimalPoint] ?? "",
            groupSeparator : row[col_groupSeparator] ?? "",
            unitName       : row[col_unitName] ?? "",
            centName       : row[col_centName] ?? "",
            scale          : row[col_scale] ?? 0,
            baseConvRate   : row[cast_baseConvRate] ?? 0.0,
            symbol         : row[col_symbol],
            type           : CurrencyType(collateNoCase: row[col_type])
        )
    }

    static func itemSetters(_ data: CurrencyData) -> [SQLite.Setter] {
        return [
            col_name           <- data.name,
            col_prefixSymbol   <- data.prefixSymbol,
            col_suffixSymbol   <- data.suffixSymbol,
            col_decimalPoint   <- data.decimalPoint,
            col_groupSeparator <- data.groupSeparator,
            col_unitName       <- data.unitName,
            col_centName       <- data.centName,
            col_scale          <- data.scale,
            col_baseConvRate   <- data.baseConvRate,
            col_symbol         <- data.symbol,
            col_type           <- data.type.rawValue
        ]
    }
}

extension CurrencyRepository {
    // load all currencies, sorted by name
    func load() -> [CurrencyData] {
        log.trace("CurrencyRepository.load()")
        return select(from: Self.table
            .order(Self.col_name)
        )
    }

    // load all currency names
    func loadName() -> [(id: Int64, name: String)] {
        log.trace("CurrencyRepository.loadName()")
        return select(from: Self.table
            .order(Self.col_name)
        ) { row in
            (id: row[Self.col_id], name: row[Self.col_name])
        }
    }

    // load all currency symbols
    func loadSymbol() -> [(Int64, String)] {
        log.trace("CurrencyRepository.loadName()")
        return select(from: Self.table
            .order(Self.col_symbol)
        ) { row in
            (id: row[Self.col_id], name: row[Self.col_symbol])
        }
    }

    // load used currencies, indexed by id
    func dictUsed() -> [Int64: CurrencyData] {
        typealias A = AccountRepository
        typealias E = AssetRepository
        let cond = "EXISTS (" + A.table.select(1)
            .where(A.table[A.col_currencyId] == Self.table[Self.col_id])
            .union(E.table.select(1)
                .where(E.table[E.col_currencyId] == Self.table[Self.col_id])
            ).expression.description + ")"
        return dict(from: Self.table
            .filter(SQLite.Expression<Bool>(literal: cond))
        )
    }

    // load currency of an account
    func pluck(for account: AccountData) -> CurrencyData? {
        return pluck(
            key: "\(account.currencyId)",
            from: Self.table.filter(Self.col_id == account.currencyId)
        )
    }

    // load currency of an asset
    func pluck(for asset: AssetData) -> CurrencyData? {
        return pluck(
            key: "\(asset.currencyId)",
            from: Self.table.filter(Self.col_id == asset.currencyId)
        )
    }
}