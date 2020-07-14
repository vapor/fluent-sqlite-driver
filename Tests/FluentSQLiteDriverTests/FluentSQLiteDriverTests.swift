import FluentBenchmark
import FluentSQLiteDriver
import XCTest
import Logging
import NIO

final class FluentSQLiteDriverTests: XCTestCase {
    func testAll() throws { try self.benchmarker.testAll() }
    func testAggregate() throws { try self.benchmarker.testAggregate() }
    func testArray() throws { try self.benchmarker.testArray() }
    func testBatch() throws { try self.benchmarker.testBatch() }
    func testChildren() throws { try self.benchmarker.testChildren() }
    func testCodable() throws { try self.benchmarker.testCodable() }
    func testChunk() throws { try self.benchmarker.testChunk() }
    func testCRUD() throws { try self.benchmarker.testCRUD() }
    func testEagerLoad() throws { try self.benchmarker.testEagerLoad() }
    func testEnum() throws { try self.benchmarker.testEnum() }
    func testFilter() throws { try self.benchmarker.testFilter() }
    func testGroup() throws { try self.benchmarker.testGroup() }
    func testID() throws { try self.benchmarker.testID() }
    func testJoin() throws { try self.benchmarker.testJoin() }
    func testMiddleware() throws { try self.benchmarker.testMiddleware() }
    func testMigrator() throws { try self.benchmarker.testMigrator() }
    func testModel() throws { try self.benchmarker.testModel() }
    func testOptionalParent() throws { try self.benchmarker.testOptionalParent() }
    func testPagination() throws { try self.benchmarker.testPagination() }
    func testParent() throws { try self.benchmarker.testParent() }
    func testPerformance() throws { try self.benchmarker.testPerformance() }
    func testRange() throws { try self.benchmarker.testRange() }
    func testSchema() throws { try self.benchmarker.testSchema() }
    func testSet() throws { try self.benchmarker.testSet() }
    func testSiblings() throws { try self.benchmarker.testSiblings() }
    func testSoftDelete() throws { try self.benchmarker.testSoftDelete() }
    func testSort() throws { try self.benchmarker.testSort() }
    func testTimestamp() throws { try self.benchmarker.testTimestamp() }
    func testTransaction() throws { try self.benchmarker.testTransaction() }
    func testUnique() throws { try self.benchmarker.testUnique() }

    func testDatabaseError() throws {
        let sql = (self.database as! SQLDatabase)
        do {
            try sql.raw("asdf").run().wait()
        } catch let error as DatabaseError where error.isSyntaxError {
            // pass
        } catch {
            XCTFail("\(error)")
        }
        do {
            try sql.raw("CREATE TABLE foo (name TEXT UNIQUE)").run().wait()
            try sql.raw("INSERT INTO foo (name) VALUES ('bar')").run().wait()
            try sql.raw("INSERT INTO foo (name) VALUES ('bar')").run().wait()
        } catch let error as DatabaseError where error.isConstraintFailure {
            // pass
        } catch {
            XCTFail("\(error)")
        }
        do {
            try (sql as! SQLiteDatabase).withConnection { conn in
                conn.close().flatMap {
                    conn.sql().raw("INSERT INTO foo (name) VALUES ('bar')").run()
                }
            }.wait()
        } catch let error as DatabaseError where error.isConnectionClosed {
            // pass
        } catch {
            XCTFail("\(error)")
        }
    }

    // https://github.com/vapor/fluent-sqlite-driver/issues/62
    func testUnsupportedUpdateMigration() throws {
        struct UserMigration_v1_0_0: Migration {
            func prepare(on database: Database) -> EventLoopFuture<Void> {
                database.schema("users")
                    .id()
                    .field("email", .string, .required)
                    .field("password", .string, .required)
                    .unique(on: "email")
                    .create()
            }

            func revert(on database: Database) -> EventLoopFuture<Void> {
                database.schema("users").delete()
            }
        }
        struct UserMigration_v1_2_0: Migration {
            func prepare(on database: Database) -> EventLoopFuture<Void> {
                database.schema("users")
                    .field("apple_id", .string)
                    .unique(on: "apple_id")
                    .update()
            }

            func revert(on database: Database) -> EventLoopFuture<Void> {
                database.schema("users")
                    .deleteField("apple_id")
                    .update()
            }
        }
        try UserMigration_v1_0_0().prepare(on: self.database).wait()
        do {
            try UserMigration_v1_2_0().prepare(on: self.database).wait()
            try UserMigration_v1_2_0().revert(on: self.database).wait()
        } catch {
            print(error)
            XCTAssertTrue("\(error)".contains("adding columns"))
        }
        try UserMigration_v1_0_0().revert(on: self.database).wait()
    }
    
    var benchmarker: FluentBenchmarker {
        return .init(databases: self.dbs)
    }
    
    var database: Database {
        self.benchmarker.database
    }
    
    var threadPool: NIOThreadPool!
    var eventLoopGroup: EventLoopGroup!
    var dbs: Databases!

    let benchmarkPath = FileManager.default.temporaryDirectory.appendingPathComponent("benchmark.sqlite").absoluteString

    override func setUpWithError() throws {
        try super.setUpWithError()

        XCTAssert(isLoggingConfigured)
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        self.threadPool = .init(numberOfThreads: System.coreCount)
        self.threadPool.start()
        self.dbs = Databases(threadPool: self.threadPool, on: self.eventLoopGroup)
        self.dbs.use(.sqlite(.memory), as: .sqlite)
        self.dbs.use(.sqlite(.file(self.benchmarkPath)), as: .benchmark)
    }

    override func tearDownWithError() throws {
        self.dbs.shutdown()
        self.dbs = nil
        try self.threadPool.syncShutdownGracefully()
        self.threadPool = nil
        try self.eventLoopGroup.syncShutdownGracefully()
        self.eventLoopGroup = nil

        try super.tearDownWithError()
    }
}

func env(_ name: String) -> String? {
    return ProcessInfo.processInfo.environment[name]
}

let isLoggingConfigured: Bool = {
    LoggingSystem.bootstrap { label in
        var handler = StreamLogHandler.standardOutput(label: label)
        handler.logLevel = env("LOG_LEVEL").flatMap { Logger.Level(rawValue: $0) } ?? .debug
        return handler
    }
    return true
}()

extension DatabaseID {
    static let benchmark = DatabaseID(string: "benchmark")
}
