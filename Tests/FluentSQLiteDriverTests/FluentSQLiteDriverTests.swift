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

    func testModelMiddleware() throws {
        try self.benchmarker.testModelMiddleware()
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

    func testMultipleJoinSameTable() throws {
        try self.benchmarker.testMultipleJoinSameTable()
    }

    func testOptionalParent() throws {
        try self.benchmarker.testOptionalParent()
    }
    
    func testFieldFilter() throws {
        try self.benchmarker.testFieldFilter()
    }
    
    func testJoinedFieldFilter() throws {
        try self.benchmarker.testJoinedFieldFilter()
    }

    func testSameChildrenFromKey() throws {
        try self.benchmarker.testSameChildrenFromKey()
    }

    func testArray() throws {
        try self.benchmarker.testArray()
    }

    func testPerformance() throws {
        try self.benchmarker.testPerformance()
    }

    func testSoftDeleteWithQuery() throws {
        try self.benchmarker.testSoftDeleteWithQuery()
    }

    var benchmarker: FluentBenchmarker {
        return .init(database: self.database)
    }
    
    var database: Database {
        self.dbs.database(
            logger: .init(label: "codes.vapor.test"),
            on: self.eventLoopGroup.next()
        )!
    }
    
    var threadPool: NIOThreadPool!
    var eventLoopGroup: EventLoopGroup!
    var dbs: Databases!

    override func setUp() {
        XCTAssert(isLoggingConfigured)
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.threadPool = .init(numberOfThreads: 2)
        self.threadPool.start()
        self.dbs = Databases(threadPool: self.threadPool, on: self.eventLoopGroup)
        self.dbs.sqlite(
            configuration: .init(storage: .memory),
            maxConnectionsPerEventLoop: 2
        )
    }

    override func tearDown() {
        self.dbs.shutdown()
        self.dbs = nil
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
