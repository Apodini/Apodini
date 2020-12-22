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
              required string value = 1;
            }
            """
        
        XCTAssertEqual(try buildMessage(String.self), expected)
    }
    
    func testOptionalProperty() throws {
        struct Message {
            let value: String?
        }
        
        let expected = """
            syntax = "proto3";

            message MessageMessage {
              optional string value = 1;
            }
            """
        
        XCTAssertEqual(try buildMessage(Message.self), expected)
    }
    
    func testHierarchyFirstOrder() throws {
        struct Location {
            let latitude: UInt32
            let longitude: UInt32
        }
        
        let expected = """
            syntax = "proto3";

            message LocationMessage {
              required uint32 latitude = 1;
              required uint32 longitude = 2;
            }
            """
        
        XCTAssertEqual(try buildMessage(Location.self), expected)
    }
    
    func testHierarchySecondOrder() throws {
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
              required int32 amount = 1;
            }
            """
        
        XCTAssertEqual(try buildMessage(Account.self), expected)
    }
    
    func testRecursionFirstOrder() throws {
        struct Node {
            let children: [Node]
        }
        
        let expected = """
            syntax = "proto3";

            message NodeMessage {
              repeated NodeMessage children = 1;
            }
            """
        
        XCTAssertEqual(try buildMessage(Node.self), expected)
    }
    
    func testRecursionSecondOrder() throws {
        struct First {
            let value: Second
        }
        
        struct Second {
            let value: [First]
        }
        
        let expected = """
            syntax = "proto3";

            message FirstMessage {
              required SecondMessage value = 1;
            }

            message SecondMessage {
              repeated FirstMessage value = 1;
            }
            """
        
        XCTAssertEqual(try buildMessage(First.self), expected)
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
