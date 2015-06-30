//
//  DBValue.swift
//  GRDB
//
//  Created by Gwendal Roué on 30/06/2015.
//  Copyright © 2015 Gwendal Roué. All rights reserved.
//

public protocol DBValue {
    func bindInStatement(statement: Statement, atIndex index:Int)
}

extension Int: DBValue {
    public func bindInStatement(statement: Statement, atIndex index: Int) {
        let code = sqlite3_bind_int64(statement.cStatement, Int32(index), Int64(self))
        assert(code == SQLITE_OK)
    }
}

extension Int64: DBValue {
    public func bindInStatement(statement: Statement, atIndex index: Int) {
        let code = sqlite3_bind_int64(statement.cStatement, Int32(index), self)
        assert(code == SQLITE_OK)
    }
}

extension Double: DBValue {
    public func bindInStatement(statement: Statement, atIndex index: Int) {
        let code = sqlite3_bind_double(statement.cStatement, Int32(index), self)
        assert(code == SQLITE_OK)
    }
}

extension String: DBValue {
    public func bindInStatement(statement: Statement, atIndex index: Int) {
        let code = nulTerminatedUTF8.withUnsafeBufferPointer { codeUnits in
            return sqlite3_bind_text(statement.cStatement, Int32(index), UnsafePointer<Int8>(codeUnits.baseAddress), -1, SQLITE_TRANSIENT)
        }
        assert(code == SQLITE_OK)
    }
}
