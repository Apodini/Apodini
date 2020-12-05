import XCTest

import Apodini
import Vapor
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
    func testScalarType() throws {
        let expected = """
            message StringMessage {
              string value = 0;
            }
            """
        
        XCTAssertEqual(try code(String.self), expected)
    }
    
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
    func testPokemonWebService() throws {
        guard let url = URL(string: "http://127.0.0.1:8080/apodini/proto") else {
            XCTAssertNotNil(nil)
            return
        }
        
        struct Pokemon: Component, ResponseEncodable {
            let id: Int64
            let name: String
            
            func handle() -> Pokemon {
                self
            }
            
            func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
                fatalError()
            }
        }
        
        struct PokemonWebService: WebService {
            var content: some Component {
                Group("pokemon") {
                    Pokemon(id: 25, name: "Pikachu")
                }
            }
        }
        
        DispatchQueue.global().async {
            PokemonWebService.main()
        }
        
        let expected = """
            message Pokemon {
              Int64 id = 0;
              String name = 1;
            }
            """
        
        let expectation = XCTestExpectation()
        
        URLSession.shared.dataTask(with: url, completionHandler: { (data, _, _) in
            data.map { data in
                guard let string = String(data: data, encoding: .utf8) else {
                    XCTAssertNotNil(nil)
                    return
                }
                
                XCTAssertEqual(string, expected)
                expectation.fulfill()
            }
        }).resume()
        
        wait(for: [expectation], timeout: 1.0)
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
    try builder.addMessage(of: type)
    let description = builder.description
    
    print("""
        ----
        \(description)
        ----
        """)
    
    return description
}
