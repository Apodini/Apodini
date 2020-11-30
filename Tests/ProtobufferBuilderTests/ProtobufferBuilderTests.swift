import XCTest
import ProtobufferBuilder

final class ProtobufferBuilderTests: XCTestCase {
    func testVoid() throws {
        XCTAssertNoThrow(try code(Void.self))
    }
    
    func testTuple() throws {
        XCTAssertThrowsError(try code((Int, String).self))
    }
    
    func testTriple() throws {
        XCTAssertThrowsError(try code((Int, String, Void).self))
    }
    
    func testStruct() throws {
        struct Person {
            let name: String
            let age: Int
        }
        
        XCTAssertNoThrow(try code(Person.self))
    }
    
    func testClass() throws {
        class Person {
            var name: String = ""
            var age: Int = 0
        }
        
        XCTAssertNoThrow(try code(Person.self))
    }
    
    func testEnum() throws {
        enum JSON {
            case null
            case bool(Bool)
            case number(Double)
            case string(String)
            case array([JSON])
            case object([String: JSON])
        }
        
        XCTAssertThrowsError(try code(JSON.self))
    }
}

extension ProtobufferBuilderTests {
    func testTypeTwoLevelsDeep() throws {
        struct Account {
            let transactions: [Transaction]
        }
        
        struct Transaction {
            let amount: Int
        }
        
        XCTAssertNoThrow(try code(Account.self))
    }
    
    func testRecursiveType() throws {
        struct Node<T> {
            let value: T
            let children: [Node]
        }
        
        XCTAssertNoThrow(try code(Node<Int>.self))
    }
}

extension ProtobufferBuilderTests {
    func testGenericPolymorphism() {
        XCTAssertFalse(Array<Any>.self == Array<Int>.self)
    }
}

private func code<T>(_ type: T.Type) throws {
    let builder = ProtobufferBuilder()
    try builder.add(type)
    print("""
        ----
        \(builder.description)
        ----
        """)
}
