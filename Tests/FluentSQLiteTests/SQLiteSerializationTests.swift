import Async
import Fluent
import FluentBenchmark
import FluentSQLite
import SQLite
import XCTest

final class SQLiteSerializationTests: XCTestCase {

    func testCreateTableWithForeignKeyShouldEscapeIdentifiersWithDoubleQuotes() {
        let serializer = SQLiteSQLSerializer()
        var query = DataDefinitionQuery(statement: .create, table: "testTableName")
        let localDataColmun = DataColumn(table: nil, name: "sourceColumnName")
        let foreignDataColumn = DataColumn(table: "destinationTableName", name: "destinationColumnName")
        query.addColumns.append(DataDefinitionColumn(name: "sourceColumnName", dataType: "text"))
        query.addForeignKeys.append(DataDefinitionForeignKey(name: "testForeignKeyName", local: localDataColmun, foreign: foreignDataColumn))
        
        // Execute
        let sqlString = serializer.serialize(query: query)
        
        let tableNameQuotes = sqlString.quotes(of: "testTableName")
            .union(sqlString.quotes(of: "destinationTableName"))
        XCTAssertEqual(tableNameQuotes.count, 1, "Incoherent quoting of table names")
        XCTAssert(tableNameQuotes.contains("\""), "Table names should be quoted by \"")

        let columnNameQuotes = sqlString.quotes(of: "sourceColumnName")
            .union(sqlString.quotes(of: "destinationColumnName"))
        XCTAssertEqual(columnNameQuotes.count, 1, "Incoherent quoting of column names")
        XCTAssert(columnNameQuotes.contains("\""), "Column names should be quoted by \"")
}
    
    static let allTests = [
        ("testCreateTableWithForeignKeyShouldEscapeIdentifiersWithDoubleQuotes", testCreateTableWithForeignKeyShouldEscapeIdentifiersWithDoubleQuotes),
    ]
}

private extension String {
    func quotes(of substring: String) -> Set<Character> {
        var quoteCharacters = Set<Character>()
        
        var range = self.range(of: substring)
        while range != nil {
            guard let substringStartIndex = range?.lowerBound, let substringEndIndex = range?.upperBound else {
                break
            }

            quoteCharacters.insert(self[index(before: substringStartIndex)])
            quoteCharacters.insert(self[substringEndIndex])
            
            range = self.range(of: substring, options: [], range: substringEndIndex..<self.endIndex, locale: nil)
        }
        return quoteCharacters
    }
}
