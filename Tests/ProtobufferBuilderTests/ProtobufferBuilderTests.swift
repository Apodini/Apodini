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
        
        let expected = """
            message Account {
              repeated Transaction transactions = 0;
            }

            message Transaction {
              Int amount = 0;
            }
            """
        
        XCTAssertEqual(try code(Account.self), expected)
    }
    
    func testRecursiveType() throws {
        struct Node<T> {
            let value: T
            let children: [Node]
        }
        
        let expected = """
            message NodeOfInt {
              Int value = 0;
              repeated NodeOfInt children = 1;
            }
            """
        
        XCTAssertEqual(try code(Node<Int>.self), expected)
    }
}

extension ProtobufferBuilderTests {
    func testGenericPolymorphism() {
        XCTAssertFalse(Array<Any>.self == Array<Int>.self)
    }
}

@discardableResult
private func code<T>(_ type: T.Type) throws -> String {
    let builder = ProtobufferBuilder()
    try builder.add(type)
    let description = builder.description
    
    print("""
        ----
        \(description)
        ----
        """)
    
    return description
}
