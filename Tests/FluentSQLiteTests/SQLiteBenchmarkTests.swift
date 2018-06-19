import Async
import Fluent
import FluentBenchmark
import FluentSQLite
import SQLite
import XCTest
import FluentSQL

final class SQLiteBenchmarkTests: XCTestCase {
    var benchmarker: Benchmarker<SQLiteDatabase>!
    var database: SQLiteDatabase!

    override func setUp() {
        database = try! SQLiteDatabase(storage: .memory)
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        benchmarker = try! Benchmarker(database, on: group, onFail: XCTFail)
    }

    func testBenchmark() throws {
        try benchmarker.runAll()
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

    func testContains() throws {
        struct User: SQLiteModel, SQLiteMigration {
            var id: Int?
            var name: String
            var age: Int
        }
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { benchmarker.pool.releaseConnection(conn) }
        
        try User.prepare(on: conn).wait()
        defer { try! User.revert(on: conn).wait() }
        
        // create
        let tanner1 = User(id: nil, name: "tanner", age: 23)
        _ = try tanner1.save(on: conn).wait()
        let tanner2 = User(id: nil, name: "ner", age: 23)
        _ = try tanner2.save(on: conn).wait()
        let tanner3 = User(id: nil, name: "tan", age: 23)
        _ = try tanner3.save(on: conn).wait()
        
        let tas = try User.query(on: conn).filter(\.name =~ "ta").count().wait()
        if tas != 2 {
            XCTFail("tas == \(tas)")
        }
        //        let ers = try User.query(on: conn).filter(\.name ~= "er").count().wait()
        //        if ers != 2 {
        //            XCTFail("ers == \(tas)")
        //        }
        let annes = try User.query(on: conn).filter(\.name ~~ "anne").count().wait()
        if annes != 1 {
            XCTFail("annes == \(tas)")
        }
        let ns = try User.query(on: conn).filter(\.name ~~ "n").count().wait()
        if ns != 3 {
            XCTFail("ns == \(tas)")
        }
        
        let nertan = try User.query(on: conn).filter(\.name ~~ ["ner", "tan"]).count().wait()
        if nertan != 2 {
            XCTFail("nertan == \(tas)")
        }
        
        let notner = try User.query(on: conn).filter(\.name !~ ["ner"]).count().wait()
        if notner != 2 {
            XCTFail("nertan == \(tas)")
        }
    }
    
    func testSQLiteEnums() throws {
        enum PetType: Int, Codable, CaseIterable {
            static let allCases: [PetType] = [.cat, .dog]
            case cat, dog
        }

        enum NumLegs: Int, SQLiteEnumType {
            case four = 4
            case two = 2

            static func reflectDecoded() -> (NumLegs, NumLegs) {
                return (.four, .two)
            }
        }

        enum FavoriteTreat: String, SQLiteEnumType {
            case bone = "b"
            case tuna = "t"

            static func reflectDecoded() -> (FavoriteTreat, FavoriteTreat) {
                return (.bone, .tuna)
            }
        }

        struct Pet: SQLiteModel, Migration {
            var id: Int?
            var name: String
            var type: PetType
            var numLegs: NumLegs
            var treat: FavoriteTreat
        }

        let conn = try benchmarker.pool.requestConnection().wait()
        defer { benchmarker.pool.releaseConnection(conn) }

        defer { try? Pet.revert(on: conn).wait() }
        try Pet.prepare(on: conn).wait()

        let cat = try Pet(id: nil, name: "Ziz", type: .cat, numLegs: .two, treat: .tuna).save(on: conn).wait()
        let dog = try Pet(id: nil, name: "Spud", type: .dog, numLegs: .four, treat: .bone).save(on: conn).wait()
        let fetchedCat = try Pet.find(cat.requireID(), on: conn).wait()
        XCTAssertEqual(dog.type, .dog)
        XCTAssertEqual(cat.id, fetchedCat?.id)
    }

    func testSQLiteJSON() throws {
        enum PetType: Int, Codable {
            case cat, dog
        }

        struct Pet: SQLiteJSONType {
            var name: String
            var type: PetType
        }

        struct User: SQLiteModel, Migration {
            var id: Int?
            var pet: Pet
        }

        let conn = try benchmarker.pool.requestConnection().wait()
        defer { benchmarker.pool.releaseConnection(conn) }

        defer { try? User.revert(on: conn).wait() }
        try User.prepare(on: conn).wait()

        let cat = Pet(name: "Ziz", type: .cat)
        let tanner = try User(id: nil, pet: cat).save(on: conn).wait()
        let fetched = try User.find(tanner.requireID(), on: conn).wait()
        XCTAssertEqual(tanner.id, fetched?.id)
        XCTAssertEqual(fetched?.pet.name, "Ziz")
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
    
    // https://github.com/vapor/fluent-sqlite/issues/5
    func testRelativeDB() throws {
        let sqlite = try SQLiteDatabase(storage: .file(path: "foo.sqlite"))
        let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let conn = try sqlite.newConnection(on: eventLoop).wait()
        let version = try conn.query("SELECT 1").wait()
        print(version)
    }
    
    // https://github.com/vapor/fluent-sqlite/issues/8
    func testDefaultValues() throws {
        struct User: SQLiteModel, SQLiteMigration {
            var id: Int?
            var name: String
            var test: String?
            
            static func prepare(on conn: SQLiteConnection) -> Future<Void> {
                return SQLiteDatabase.create(User.self, on: conn) { builder in
                    builder.field(for: \.id, isIdentifier: true)
                    builder.field(for: \.name)
                    builder.field(for: \.test, type: .text, .default(.literal("foo")))
                }
            }
            
            static func revert(on conn: SQLiteConnection) -> Future<Void> {
                return SQLiteDatabase.delete(User.self, on: conn)
            }
        }
        
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { benchmarker.pool.releaseConnection(conn) }
        
        try User.prepare(on: conn).wait()
        defer { try! User.revert(on: conn).wait() }
        
        var user = User(id: nil, name: "Vapor", test: nil)
        user = try user.save(on: conn).wait()
        try XCTAssertEqual(User.find(1, on: conn).wait()?.test, "foo")
    }
    
    // https://github.com/vapor/fluent-sqlite/issues/9
    func testReferenceEnforcement() throws {
        struct City: SQLiteModel, SQLiteMigration {
            var id: Int?
            let regionId: Int
            let name: String
            
            static func prepare(on connection: SQLiteConnection) -> Future<Void> {
                return Database.create(self, on: connection) { builder in
                    try addProperties(to: builder)
                    builder.reference(from: \.regionId, to: \Region.id)
                }
            }
        }
        struct Region: SQLiteModel, SQLiteMigration {
            var id: Int?
            var name: String
        }
        
        let sqlite: DatabaseConnectionPool<ConfiguredDatabase<SQLiteDatabase>>
        do {
            var databases = DatabasesConfig()
            try! databases.add(database: SQLiteDatabase(storage: .memory), as: .sqlite)
            databases.enableReferences(on: .sqlite)
            let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
            let dbs = try databases.resolve(on: BasicContainer(config: .init(), environment: .testing, services: .init(), on: group))
            sqlite = try dbs.requireDatabase(for: .sqlite).newConnectionPool(config: .init(maxConnections: 4), on: group)
        }
        let conn = try sqlite.requestConnection().wait()
        defer { sqlite.releaseConnection(conn) }
        
        try Region.prepare(on: conn).wait()
        defer { try! Region.revert(on: conn).wait() }
        try City.prepare(on: conn).wait()
        defer { try! City.revert(on: conn).wait() }
        
        do {
            _ = try City(id: nil, regionId: 42, name: "city").save(on: conn).wait()
            XCTFail("should have errored")
        } catch {
            XCTAssert(error is SQLiteError)
        }
    }

    static let allTests = [
        ("testBenchmark", testBenchmark),
        ("testMinimumViableModelDeclaration", testMinimumViableModelDeclaration),
        ("testUUIDPivot", testUUIDPivot),
        ("testSQLiteEnums", testSQLiteEnums),
        ("testSQLiteJSON", testSQLiteJSON),
        ("testRelativeDB", testRelativeDB),
    ]
}
