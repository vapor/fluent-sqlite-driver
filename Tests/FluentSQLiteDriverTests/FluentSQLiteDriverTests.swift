import FluentBenchmark
import FluentSQLiteDriver
import XCTest
import Logging

final class FluentSQLiteDriverTests: FluentBenchmarker {
    override var database: Database! {
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
        self.dbs.use(.sqlite(.memory), as: .sqlite)
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
