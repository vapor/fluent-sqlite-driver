import FluentBenchmark
import FluentSQLiteDriver
import XCTest
import Logging

final class FluentSQLiteDriverTests: XCTestCase {
    func testAll() throws {
        try self.benchmarker.testAll()
    }

    func testCreate() throws {
        try self.benchmarker.testCreate()
    }

    func testRead() throws {
        try self.benchmarker.testRead()
    }

    func testUpdate() throws {
        try self.benchmarker.testUpdate()
    }

    func testDelete() throws {
        try self.benchmarker.testDelete()
    }

    func testEagerLoadChildren() throws {
        try self.benchmarker.testEagerLoadChildren()
    }

    func testEagerLoadParent() throws {
        try self.benchmarker.testEagerLoadParent()
    }

    func testEagerLoadParentJoin() throws {
        try self.benchmarker.testEagerLoadParentJoin()
    }

    func testEagerLoadParentJSON() throws {
        try self.benchmarker.testEagerLoadParentJSON()
    }

    func testEagerLoadChildrenJSON() throws {
        try self.benchmarker.testEagerLoadChildrenJSON()
    }

    func testMigrator() throws {
        try self.benchmarker.testMigrator()
    }

    func testMigratorError() throws {
        try self.benchmarker.testMigratorError()
    }

    func testJoin() throws {
        try self.benchmarker.testJoin()
    }

    func testBatchCreate() throws {
        try self.benchmarker.testBatchCreate()
    }

    func testBatchUpdate() throws {
        try self.benchmarker.testBatchUpdate()
    }

    func testNestedModel() throws {
        try self.benchmarker.testNestedModel()
    }

    func testAggregates() throws {
        try self.benchmarker.testAggregates()
    }

    func testIdentifierGeneration() throws {
        try self.benchmarker.testIdentifierGeneration()
    }

    func testNullifyField() throws {
        try self.benchmarker.testNullifyField()
    }

    func testChunkedFetch() throws {
        try self.benchmarker.testChunkedFetch()
    }

    func testUniqueFields() throws {
        try self.benchmarker.testUniqueFields()
    }

    func testAsyncCreate() throws {
        try self.benchmarker.testAsyncCreate()
    }

    func testSoftDelete() throws {
        try self.benchmarker.testSoftDelete()
    }

    func testTimestampable() throws {
        try self.benchmarker.testTimestampable()
    }

    func testLifecycleHooks() throws {
        try self.benchmarker.testLifecycleHooks()
    }

    func testSort() throws {
        try self.benchmarker.testSort()
    }

    func testUUIDModel() throws {
        try self.benchmarker.testUUIDModel()
    }

    func testNewModelDecode() throws {
        try self.benchmarker.testNewModelDecode()
    }

    func testSiblingsAttach() throws {
        try self.benchmarker.testSiblingsAttach()
    }

    func testSiblingsEagerLoad() throws {
        try self.benchmarker.testSiblingsEagerLoad()
    }

    var benchmarker: FluentBenchmarker {
        return .init(database: self.connectionPool)
    }
    var connectionPool: ConnectionPool<SQLiteConnectionSource>!
    var threadPool: NIOThreadPool!
    var eventLoopGroup: EventLoopGroup!

    override func setUp() {
        XCTAssert(isLoggingConfigured)
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.threadPool = .init(numberOfThreads: 2)
        let db = SQLiteConnectionSource(configuration: .init(storage: .memory), threadPool: self.threadPool, on: self.eventLoopGroup.next())
        self.connectionPool = ConnectionPool(config: .init(maxConnections: 8), source: db)
    }

    override func tearDown() {
        try! self.connectionPool.close().wait()
        self.connectionPool = nil
        try! self.threadPool.syncShutdownGracefully()
        self.threadPool = nil
        try! self.eventLoopGroup.syncShutdownGracefully()
        self.eventLoopGroup = nil
    }
}

let isLoggingConfigured: Bool = {
    LoggingSystem.bootstrap { label in
        var handler = StreamLogHandler.standardOutput(label: label)
        handler.logLevel = .debug
        return handler
    }
    return true
}()
