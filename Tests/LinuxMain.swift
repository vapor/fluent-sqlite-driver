#if os(Linux)

import XCTest
@testable import FluentSQLiteTests

XCTMain([
    testCase(SQLiteBenchmarkTests.allTests),
])

#endif
