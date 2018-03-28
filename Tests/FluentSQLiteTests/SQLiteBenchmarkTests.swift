import Async
import Fluent
import FluentBenchmark
import FluentSQLite
import SQLite
import XCTest

final class SQLiteBenchmarkTests: XCTestCase {
    var benchmarker: Benchmarker<SQLiteDatabase>!
    var database: SQLiteDatabase!

    override func setUp() {
        database = try! SQLiteDatabase(storage: .memory)
        let group = MultiThreadedEventLoopGroup(numThreads: 1)
        benchmarker = Benchmarker(database, on: group, onFail: XCTFail)
    }

    func testSchema() throws {
        try benchmarker.benchmarkSchema()
    }

    func testModels() throws {
        try benchmarker.benchmarkModels_withSchema()
    }

    func testRelations() throws {
        try benchmarker.benchmarkRelations_withSchema()
    }

    func testTimestampable() throws {
        try benchmarker.benchmarkTimestampable_withSchema()
    }

    func testTransactions() throws {
        try benchmarker.benchmarkTransactions_withSchema()
    }

    func testChunking() throws {
        try benchmarker.benchmarkChunking_withSchema()
    }

    func testAutoincrement() throws {
        try benchmarker.benchmarkAutoincrement_withSchema()
    }

    func testCache() throws {
        try benchmarker.benchmarkCache_withSchema()
    }

    func testJoins() throws {
        try benchmarker.benchmarkJoins_withSchema()
    }

    func testSoftDeletable() throws {
        try benchmarker.benchmarkSoftDeletable_withSchema()
    }

    func testReferentialActions() throws {
        try benchmarker.benchmarkReferentialActions_withSchema()
    }

    func testMinimumViableModelDeclaration() throws {
        /// NOTE: these must never fail to build
        struct Foo: SQLiteModel {
            var id: Int?
            var name: String
        }
        final class Bar: SQLiteModel {
            var id: Int?
            var name: String
        }
        struct Baz: SQLiteUUIDModel {
            var id: UUID?
            var name: String
        }
        final class Qux: SQLiteUUIDModel {
            var id: UUID?
            var name: String
        }
        final class Uh: SQLiteStringModel {
            var id: String?
            var name: String
        }
    }
  
    func testIndexSupporting() throws {
        try benchmarker.benchmarkIndexSupporting_withSchema()
    }

    func testContains() throws {
        try benchmarker.benchmarkContains_withSchema()
    }

    func testUUIDPivot() throws {
        struct A: SQLiteUUIDModel, Migration {
            var id: UUID?
        }
        struct B: SQLiteUUIDModel, Migration {
            var id: UUID?
        }
        struct C: SQLiteUUIDPivot, Migration {
            static var leftIDKey = \C.aID
            static var rightIDKey = \C.bID

            typealias Left = A
            typealias Right = B
            var id: UUID?
            var aID: UUID
            var bID: UUID
        }

        database.enableLogging(using: .print)

        let conn = try benchmarker.pool.requestConnection().wait()
        defer { benchmarker.pool.releaseConnection(conn) }

        defer {
            try? C.prepare(on: conn).wait()
            try? B.prepare(on: conn).wait()
            try? A.prepare(on: conn).wait()
        }
        try A.prepare(on: conn).wait()
        try B.prepare(on: conn).wait()
        try C.prepare(on: conn).wait()

        let a = try A(id: nil).save(on: conn).wait()
        let b = try B(id: nil).save(on: conn).wait()
        let c = try C(id: nil, aID: a.requireID(), bID: b.requireID()).save(on: conn).wait()

        let fetched = try C.find(c.requireID(), on: conn).wait()
        XCTAssertEqual(fetched?.id, c.id)
    }

    static let allTests = [
        ("testSchema", testSchema),
        ("testModels", testModels),
        ("testRelations", testRelations),
        ("testTimestampable", testTimestampable),
        ("testTransactions", testTransactions),
        ("testChunking", testChunking),
        ("testAutoincrement", testAutoincrement),
        ("testCache", testCache),
        ("testJoins", testJoins),
        ("testSoftDeletable", testSoftDeletable),
        ("testReferentialActions", testReferentialActions),
        ("testMinimumViableModelDeclaration", testMinimumViableModelDeclaration),
        ("testIndexSupporting", testIndexSupporting),
        ("testUUIDPivot", testUUIDPivot),
    ]
}
