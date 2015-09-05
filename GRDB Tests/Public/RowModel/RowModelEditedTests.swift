import XCTest
import GRDB

class IntegerPropertyOnRealAffinityColumn : RowModel {
    var value: Int!
    
    override var storedDatabaseDictionary: [String: DatabaseValueConvertible?] {
        return ["value": value]
    }
    
    override func setDatabaseValue(dbv: DatabaseValue, forColumn column: String) {
        switch column {
        case "value": value = dbv.value()
        default: super.setDatabaseValue(dbv, forColumn: column)
        }
    }
}

class RowModelEditedTests: RowModelTestCase {
    
    func testRowModelIsEditedAfterInit() {
        // Create a RowModel. No fetch has happen, so we don't know if it is
        // identical to its eventual row in the database. So it is edited.
        let person = Person(name: "Arthur", age: 41)
        XCTAssertTrue(person.databaseEdited)
    }
    
    func testRowModelIsEditedAfterInitFromRow() {
        // Create a RowModel from a row. The row may not come from the database.
        // So it is edited.
        let row = Row(dictionary: ["name": "Arthur", "age": 41])
        let person = Person(row: row)
        XCTAssertTrue(person.databaseEdited)
    }
    
    func testRowModelIsNotEditedAfterFullFetch() {
        // Fetch a model from a row that contains all the columns in
        // storedDatabaseDictionary: An update statement, which only saves the
        // columns in storedDatabaseDictionary would perform no change. So the
        // model is not edited.
        assertNoError {
            try dbQueue.inDatabase { db in
                try Person(name: "Arthur", age: 41).insert(db)
                let person = Person.fetchOne(db, "SELECT * FROM persons")!
                XCTAssertFalse(person.databaseEdited)
            }
        }
    }
    
    func testRowModelIsNotEditedAfterFullFetchWithIntegerPropertyOnRealAffinityColumn() {
        assertNoError {
            try dbQueue.inDatabase { db in
                try db.execute("CREATE TABLE t (value REAL)")
                try db.execute("INSERT INTO t (value) VALUES (1)")
                let rowModel = IntegerPropertyOnRealAffinityColumn.fetchOne(db, "SELECT * FROM t")!
                XCTAssertFalse(rowModel.databaseEdited)
            }
        }
    }
    
    func testRowModelIsNotEditedAfterWiderThanFullFetch() {
        // Fetch a model from a row that contains all the columns in
        // storedDatabaseDictionary, plus extra ones: An update statement, which
        // only saves the columns in storedDatabaseDictionary would perform no
        // change. So the model is not edited.
        assertNoError {
            try dbQueue.inDatabase { db in
                try Person(name: "Arthur", age: 41).insert(db)
                let person = Person.fetchOne(db, "SELECT *, 1 AS foo FROM persons")!
                XCTAssertFalse(person.databaseEdited)
            }
        }
    }
    
    func testRowModelIsEditedAfterPartialFetch() {
        // Fetch a model from a row that does not contain all the columns in
        // storedDatabaseDictionary: An update statement saves the columns in
        // storedDatabaseDictionary, so it may perform unpredictable change.
        // So the model is edited.
        assertNoError {
            try dbQueue.inDatabase { db in
                try Person(name: "Arthur", age: 41).insert(db)
                let person =  Person.fetchOne(db, "SELECT name FROM persons")!
                XCTAssertTrue(person.databaseEdited)
            }
        }
    }
    
    func testRowModelIsNotEditedAfterInsert() {
        // After insertion, a model is not edited.
        assertNoError {
            try dbQueue.inDatabase { db in
                let person = Person(name: "Arthur", age: 41)
                try person.insert(db)
                XCTAssertFalse(person.databaseEdited)
            }
        }
    }
    
    func testRowModelIsEditedAfterValueChange() {
        // Any change in a value exposed in storedDatabaseDictionary yields a
        // row model that is edited.
        assertNoError {
            try dbQueue.inDatabase { db in
                let person = Person(name: "Arthur", age: 41)
                try person.insert(db)
                
                person.name = "Bobby"           // non-nil vs. non-nil
                XCTAssertTrue(person.databaseEdited)
                try person.reload(db)
                
                person.name = nil               // non-nil vs. nil
                XCTAssertTrue(person.databaseEdited)
                try person.reload(db)
                
                person.creationDate = NSDate()  // nil vs. non-nil
                XCTAssertTrue(person.databaseEdited)
                try person.reload(db)
            }
        }
    }
    
    func testRowModelIsNotEditedAfterUpdate() {
        // After update, a model is not edited.
        assertNoError {
            try dbQueue.inDatabase { db in
                let person = Person(name: "Arthur", age: 41)
                try person.insert(db)
                person.name = "Bobby"
                try person.update(db)
                XCTAssertFalse(person.databaseEdited)
            }
        }
    }
    
    func testRowModelIsNotEditedAfterSave() {
        // After save, a model is not edited.
        assertNoError {
            try dbQueue.inDatabase { db in
                let person = Person(name: "Arthur", age: 41)
                try person.save(db)
                XCTAssertFalse(person.databaseEdited)
                person.name = "Bobby"
                XCTAssertTrue(person.databaseEdited)
                try person.save(db)
                XCTAssertFalse(person.databaseEdited)
            }
        }
    }
    
    func testRowModelIsNotEditedAfterReload() {
        // After reload, a model is not edited.
        assertNoError {
            try dbQueue.inDatabase { db in
                let person = Person(name: "Arthur", age: 41)
                try person.insert(db)
                
                person.name = "Bobby"
                XCTAssertTrue(person.databaseEdited)
                
                try person.reload(db)
                XCTAssertFalse(person.databaseEdited)
            }
        }
    }
    
    func testRowModelIsEditedAfterPrimaryKeyChange() {
        // After reload, a model is not edited.
        assertNoError {
            try dbQueue.inDatabase { db in
                let commonAttributes = Row(dictionary:["name": "Arthur", "age": 41])
                
                let person1 = Person(row: commonAttributes)
                try person1.insert(db)
                
                let person2 = Person(row: commonAttributes)
                try person2.insert(db)
                
                XCTAssertFalse(person1.databaseEdited)
                XCTAssertFalse(person2.databaseEdited)
                person1.copyDatabaseValuesFrom(person2)
                XCTAssertTrue(person1.databaseEdited)
            }
        }
    }
}
