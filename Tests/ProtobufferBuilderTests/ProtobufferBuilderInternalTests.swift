import XCTest
@testable import ProtobufferBuilder

final class ProtobufferBuilderInternalTests: XCTestCase {}

// MARK: - Test Supported Types

extension ProtobufferBuilderInternalTests {
    func testVoid() throws {
        XCTAssertNoThrow(try buildMessage(Void.self))
    }
    
    func testTuple() throws {
        XCTAssertThrowsError(try buildMessage((Int, String).self))
    }
    
    func testTriple() throws {
        XCTAssertThrowsError(try buildMessage((Int, String, Void).self))
    }
    
    func testClass() throws {
        class Person {
            var name: String = ""
            var age: Int = 0
        }
        
        XCTAssertNoThrow(try buildMessage(Person.self))
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
        
        XCTAssertThrowsError(try buildMessage(JSON.self))
    }
}

// MARK: - Test Messages

extension ProtobufferBuilderInternalTests {
    func testScalarType() throws {
        let expected = """
            syntax = "proto3";

            message StringMessage {
              string value = 1;
            }
            """
        
        XCTAssertEqual(try buildMessage(String.self), expected)
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
        
        XCTAssertEqual(try buildMessage(Location.self), expected)
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
        
        XCTAssertEqual(try buildMessage(Account.self), expected)
    }
    
    func testRecursiveType() throws {
        return ()
        
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
        
        XCTAssertEqual(try buildMessage(Node<Int64>.self), expected)
    }
}

// MARK: - Private

@discardableResult
private func buildMessage<T>(_ type: T.Type) throws -> String {
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
