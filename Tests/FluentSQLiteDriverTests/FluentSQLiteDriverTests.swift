import FluentBenchmark
import FluentSQLiteDriver
import XCTest
import Logging
import NIO
import FluentSQL
import SQLiteNIO
import FluentKit
import SQLKit

func XCTAssertThrowsErrorAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath, line: UInt = #line,
    _ callback: (any Error) -> Void = { _ in }
) async {
    do {
        _ = try await expression()
        XCTAssertThrowsError({}(), message(), file: file, line: line, callback)
    } catch {
        XCTAssertThrowsError(try { throw error }(), message(), file: file, line: line, callback)
    }
}

func XCTAssertNoThrowAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath, line: UInt = #line
) async {
    do {
        _ = try await expression()
    } catch {
        XCTAssertNoThrow(try { throw error }(), message(), file: file, line: line)
    }
}

final class FluentSQLiteDriverTests: XCTestCase {
    func testAggregate() throws { try self.benchmarker.testAggregate() }
    func testArray() throws { try self.benchmarker.testArray() }
    func testBatch() throws { try self.benchmarker.testBatch() }
    func testChild() throws { try self.benchmarker.testChild() }
    func testChildren() throws { try self.benchmarker.testChildren() }
    func testCodable() throws { try self.benchmarker.testCodable() }
    func testChunk() throws { try self.benchmarker.testChunk() }
    func testCompositeID() throws { try self.benchmarker.testCompositeID() }
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
    func testSQL() throws { try self.benchmarker.testSQL() }
    func testTimestamp() throws { try self.benchmarker.testTimestamp() }
    func testTransaction() throws { try self.benchmarker.testTransaction() }
    func testUnique() throws { try self.benchmarker.testUnique() }

    func testDatabaseError() async throws {
        let sql = (self.database as! any SQLDatabase)
        
        await XCTAssertThrowsErrorAsync(try await sql.raw("asdf").run()) {
            XCTAssertTrue(($0 as? any DatabaseError)?.isSyntaxError ?? false, "\(String(reflecting: $0))")
            XCTAssertFalse(($0 as? any DatabaseError)?.isConstraintFailure ?? true, "\(String(reflecting: $0))")
            XCTAssertFalse(($0 as? any DatabaseError)?.isConnectionClosed ?? true, "\(String(reflecting: $0))")
        }
        
        try await sql.drop(table: "foo").ifExists().run()
        try await sql.create(table: "foo").column("name", type: .text, .unique).run()
        try await sql.insert(into: "foo").columns("name").values("bar").run()
        await XCTAssertThrowsErrorAsync(try await sql.insert(into: "foo").columns("name").values("bar").run()) {
            XCTAssertTrue(($0 as? any DatabaseError)?.isConstraintFailure ?? false, "\(String(reflecting: $0))")
            XCTAssertFalse(($0 as? any DatabaseError)?.isSyntaxError ?? true, "\(String(reflecting: $0))")
            XCTAssertFalse(($0 as? any DatabaseError)?.isConnectionClosed ?? true, "\(String(reflecting: $0))")
        }
    }

    // https://github.com/vapor/fluent-sqlite-driver/issues/62
    func testUnsupportedUpdateMigration() async throws {
        struct UserMigration_v1_0_0: AsyncMigration {
            func prepare(on database: any Database) async throws {
                try await database.schema("users")
                    .id()
                    .field("email", .string, .required)
                    .field("password", .string, .required)
                    .unique(on: "email")
                    .create()
            }

            func revert(on database: any Database) async throws {
                try await database.schema("users").delete()
            }
        }
        
        struct UserMigration_v1_2_0: AsyncMigration {
            func prepare(on database: any Database) async throws {
                try await database.schema("users")
                    .field("apple_id", .string)
                    .unique(on: "apple_id")
                    .update()
            }

            func revert(on database: any Database) async throws {
                try await database.schema("users")
                    .deleteUnique(on: "apple_id")
                    .update()
            }
        }
        
        try await UserMigration_v1_0_0().prepare(on: self.database)
        await XCTAssertThrowsErrorAsync(try await UserMigration_v1_2_0().prepare(on: self.database)) {
            XCTAssert(String(describing: $0).contains("adding columns"))
        }
        await XCTAssertThrowsErrorAsync(try await UserMigration_v1_2_0().revert(on: self.database)) {
            XCTAssert(String(describing: $0).contains("adding columns"))
        }
        await XCTAssertNoThrowAsync(try await UserMigration_v1_0_0().revert(on: self.database))
    }
    
    // https://github.com/vapor/fluent-sqlite-driver/issues/91
    func testDeleteFieldMigration() async throws {
        struct UserMigration_v1_0_0: AsyncMigration {
            func prepare(on database: any Database) async throws {
                try await database.schema("users").id().field("email", .string, .required).field("password", .string, .required).create()
            }
            func revert(on database: any Database) async throws {
                try await database.schema("users").delete()
            }
        }
        struct UserMigration_v1_1_0: AsyncMigration {
            func prepare(on database: any Database) async throws {
                try await database.schema("users").deleteField("password").update()
            }
            func revert(on database: any Database) async throws {
                try await database.schema("users").field("password", .string, .required).update()
            }
        }
        
        await XCTAssertNoThrowAsync(try await UserMigration_v1_0_0().prepare(on: self.database))
        await XCTAssertNoThrowAsync(try await UserMigration_v1_1_0().prepare(on: self.database))
        await XCTAssertNoThrowAsync(try await UserMigration_v1_1_0().revert(on: self.database))
        await XCTAssertNoThrowAsync(try await UserMigration_v1_0_0().revert(on: self.database))
    }

    func testCustomJSON() async throws {
        struct Metadata: Codable { let createdAt: Date }
        final class Event: Model, @unchecked Sendable {
            static let schema = "events"
            @ID(custom: "id", generatedBy: .database) var id: Int?
            @Field(key: "metadata") var metadata: Metadata
        }
        final class EventStringlyTyped: Model, @unchecked Sendable {
            static let schema = "events"
            @ID(custom: "id", generatedBy: .database) var id: Int?
            @Field(key: "metadata") var metadata: [String: String]
        }
        struct EventMigration: AsyncMigration {
            func prepare(on database: any Database) async throws {
                try await database.schema(Event.schema)
                    .field("id", .int, .identifier(auto: false))
                    .field("metadata", .json, .required)
                    .create()
            }
            func revert(on database: any Database) async throws {
                try await database.schema(Event.schema).delete()
            }
        }
        
        let jsonEncoder = JSONEncoder(); jsonEncoder.dateEncodingStrategy = .iso8601
        let jsonDecoder = JSONDecoder(); jsonDecoder.dateDecodingStrategy = .iso8601
        let iso8601 = DatabaseID(string: "iso8601")

        self.dbs.use(.sqlite(.memory, dataEncoder: .init(json: jsonEncoder), dataDecoder: .init(json: jsonDecoder)), as: iso8601)
        let db = self.dbs.database(iso8601, logger: .init(label: "test"), on: self.dbs.eventLoopGroup.any())!

        try await EventMigration().prepare(on: db)
        do {
            let date = Date()
            let event = Event()
            event.id = 1
            event.metadata = Metadata(createdAt: date)
            try await event.save(on: db)

            let rows = try await EventStringlyTyped.query(on: db).filter(\.$id == 1).all()
            XCTAssertEqual(rows[0].metadata["createdAt"], ISO8601DateFormatter().string(from: date))
        } catch {
            try? await EventMigration().revert(on: db)
            throw error
        }
        try await EventMigration().revert(on: db)
    }

    var benchmarker: FluentBenchmarker { .init(databases: self.dbs) }
    var database: (any Database)!
    var dbs: Databases!
    let benchmarkPath = FileManager.default.temporaryDirectory.appendingPathComponent("benchmark.sqlite").absoluteString

    override class func setUp() {
        XCTAssert(isLoggingConfigured)
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.dbs = Databases(threadPool: NIOThreadPool.singleton, on: MultiThreadedEventLoopGroup.singleton)
        self.dbs.use(.sqlite(.memory), as: .sqlite)
        self.dbs.use(.sqlite(.file(self.benchmarkPath)), as: .init(string: "benchmark"))
        self.database = self.dbs.database(.sqlite, logger: .init(label: "test.fluent.sqlite"), on: MultiThreadedEventLoopGroup.singleton.any())
    }

    override func tearDownWithError() throws {
        self.dbs.shutdown()
        self.dbs = nil
        try super.tearDownWithError()
    }
}

func env(_ name: String) -> String? {
    ProcessInfo.processInfo.environment[name]
}

let isLoggingConfigured: Bool = {
    LoggingSystem.bootstrap { label in
        var handler = StreamLogHandler.standardOutput(label: label)
        handler.logLevel = env("LOG_LEVEL").flatMap { .init(rawValue: $0) } ?? .debug
        return handler
    }
    return true
}()
