import XCTest
import Apodini
import ProtobufferBuilder

// MARK: - Test Supported Types

final class ProtobufferBuilderTests: XCTestCase {
    func testVoid() throws {
        XCTAssertNoThrow(try build(Void.self))
    }
    
    func testTuple() throws {
        XCTAssertThrowsError(try build((Int, String).self))
    }
    
    func testTriple() throws {
        XCTAssertThrowsError(try build((Int, String, Void).self))
    }
    
    func testClass() throws {
        class Person {
            var name: String = ""
            var age: Int = 0
        }
        
        XCTAssertNoThrow(try build(Person.self))
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
        
        XCTAssertThrowsError(try build(JSON.self))
    }
}

// MARK: - Test Output

extension ProtobufferBuilderTests {
    func testScalarType() throws {
        let expected = """
            syntax = "proto3";

            message StringMessage {
              string value = 1;
            }
            """
        
        XCTAssertNotEqual(try build(String.self), expected)
    }
    
    func testTypeOneLevelDeep() throws {
        struct Location {
            let latitude: UInt32
            let longitude: UInt32
        }
        
        let expected = """
            syntax = "proto3";

            message LocationMessage {
              uint32 latitude = 1;
              uint32 longitude = 2;
            }
            """
        
        XCTAssertEqual(try build(Location.self), expected)
    }
    
    func testTypeTwoLevelsDeep() throws {
        struct Account {
            let transactions: [Transaction]
        }
        
        struct Transaction {
            let amount: Int32
        }
        
        let expected = """
            syntax = "proto3";

            message AccountMessage {
              repeated TransactionMessage transactions = 1;
            }

            message TransactionMessage {
              int32 amount = 1;
            }
            """
        
        XCTAssertEqual(try build(Account.self), expected)
    }
    
    func testRecursiveType() throws {
        return
        
        #warning("TODO: Enforce DAG")
        
        struct Node<T> {
            let value: T
            let children: [Node]
        }
        
        let expected = """
            syntax = "proto3";

            message NodeOfInt64Message {
              int64 value = 1;
              repeated NodeOfInt64Message children = 2;
            }
            """
        
        XCTAssertEqual(try build(Node<Int64>.self), expected)
    }
}

// MARK: - Test Components

extension ProtobufferBuilderTests {
    func testGreeterComponent() throws {
        struct Greeter: Component {
            @Parameter
            var name: String
            
            func handle() -> String {
                "Hello \(name)"
            }
        }
        
        XCTAssertNoThrow(try build(Greeter.self))
    }
}

// MARK: - Test Misc

extension ProtobufferBuilderTests {
    func testGenericPolymorphism() {
        XCTAssertFalse(Array<Any>.self == Array<Int>.self)
    }
}

// MARK: - Private

@discardableResult
private func build<T>(_ type: T.Type) throws -> String {
    let builder = ProtobufferBuilder()
    try builder.addMessage(of: type)
    let description = builder.description
    
    print("""
        ----
        \(description)
        ----
        """)
    
    return description
}
