import XCTVapor
@testable import Apodini
@testable import ApodiniProtobuffer
@testable import ApodiniGRPC

final class ProtobufferBuilderTests: XCTestCase {
    func testWebService<S: WebService>(_ type: S.Type, expectation: String) throws {
        let app = Application()
        S.start(app: app)
        defer { app.shutdown() }
        
        try app.vapor.app.test(.GET, "apodini/proto") { res in
            XCTAssertEqual(res.body.string, expectation)
        }
    }
    
    func buildMessage(_ type: Any.Type) throws -> String {
        try ProtobufferInterfaceExporter.Builder(configuration: GRPC.ExporterConfiguration())
            .buildMessage(type)
            .collectValues()
            .description
    }
}

// MARK: - Test Supported Types

extension ProtobufferBuilderTests {
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

extension ProtobufferBuilderTests {
    func testScalarType() throws {
        let expected = """
            message StringMessage {
              string value = 1;
            }
            """
        
        XCTAssertEqual(try buildMessage(String.self), expected)
    }
    
    func testOptionalProperty() throws {
        struct Message {
            let value: String?
        }
        
        let expected = """
            message MessageMessage {
              optional string value = 1;
            }
            """
        
        XCTAssertEqual(try buildMessage(Message.self), expected)
    }
    
    func testVariableWidthInteger() throws {
        let bitWidth = Int.bitWidth
        
        let expected = """
            message IntMessage {
              int\(bitWidth) value = 1;
            }
            """
        
        XCTAssertEqual(try buildMessage(Int.self), expected)
    }
    
    func testGenericTypeFirstOrder() throws {
        struct Tuple<U, V> {
            let first: U
            let second: V
        }
        
        let expected = """
            message TupleOfUInt32AndUInt64Message {
              uint32 first = 1;
              uint64 second = 2;
            }
            """
        
        XCTAssertEqual(try buildMessage(Tuple<UInt32, UInt64>.self), expected)
    }
    
    func testGenericTypeSecondOrder() throws {
        struct Box<T> {
            let value: T
        }
        
        struct Tuple<U, V> {
            let first: U
            let second: V
        }
        
        let expected = """
            message BoxOfTupleOfUInt32AndUInt64Message {
              TupleOfUInt32AndUInt64Message value = 1;
            }

            message TupleOfUInt32AndUInt64Message {
              uint32 first = 1;
              uint64 second = 2;
            }
            """
        
        XCTAssertEqual(try buildMessage(Box<Tuple<UInt32, UInt64>>.self), expected)
    }
    
    func testHierarchyFirstOrder() throws {
        struct Location {
            let latitude: UInt32
            let longitude: UInt32
        }
        
        let expected = """
            message LocationMessage {
              uint32 latitude = 1;
              uint32 longitude = 2;
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
            message AccountMessage {
              repeated TransactionMessage transactions = 1;
            }

            message TransactionMessage {
              int32 amount = 1;
            }
            """
        
        XCTAssertEqual(try buildMessage(Account.self), expected)
    }
    
    func testRecursionFirstOrder() throws {
        struct Node {
            let children: [Node]
        }
        
        let expected = """
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
            message FirstMessage {
              SecondMessage value = 1;
            }

            message SecondMessage {
              repeated FirstMessage value = 1;
            }
            """
        
        XCTAssertEqual(try buildMessage(First.self), expected)
    }
    
    func testUUID() throws {
        struct User {
            let id: UUID
        }
        
        let expected = """
            message UserMessage {
              string id = 1;
            }
            """
        
        XCTAssertEqual(try buildMessage(User.self), expected)
    }
}

// MARK: - Test Handlers

extension ProtobufferBuilderTests {
    func testServiceParametersZero() throws {
        struct WebService: Apodini.WebService {
            var content: some Component {
                HelloWorld()
            }

            var configuration: Configuration {
                GRPC {
                    Protobuffer()
                }
            }
        }
        
        struct HelloWorld: Handler {
            func handle() -> String {
                "Hello, World!"
            }
        }
        
        let expected = """
            syntax = "proto3";

            service V1Service {
              rpc helloworld (HelloWorldMessage) returns (StringMessage);
            }

            message HelloWorldMessage {}

            message StringMessage {
              string value = 1;
            }
            """
        
        try testWebService(WebService.self, expectation: expected)
    }
    
    func testServiceParametersOne() throws {
        struct WebService: Apodini.WebService {
            var content: some Component {
                Greeter()
            }

            var configuration: Configuration {
                GRPC {
                    Protobuffer()
                }
            }
        }
        
        struct Greeter: Handler {
            @Parameter
            var name: String
            
            func handle() -> String {
                "Hello \(name)"
            }
        }
        
        let expected = """
            syntax = "proto3";

            service V1Service {
              rpc greeter (GreeterMessage) returns (StringMessage);
            }

            message GreeterMessage {
              string name = 1;
            }

            message StringMessage {
              string value = 1;
            }
            """
        
        try testWebService(WebService.self, expectation: expected)
    }
    
    func testServiceParametersTwo() throws {
        struct WebService: Apodini.WebService {
            var content: some Component {
                Multiplier()
            }

            var configuration: Configuration {
                GRPC {
                    Protobuffer()
                }
            }
        }
        
        struct Multiplier: Handler {
            @Parameter
            var fst: Int32
            
            @Parameter
            var snd: Int32
            
            func handle() -> Int32 {
                fst * snd
            }
        }
        
        let expected = """
            syntax = "proto3";

            service V1Service {
              rpc multiplier (MultiplierMessage) returns (Int32Message);
            }

            message Int32Message {
              int32 value = 1;
            }

            message MultiplierMessage {
              int32 fst = 1;
              int32 snd = 2;
            }
            """
        
        try testWebService(WebService.self, expectation: expected)
    }
    
    func testServiceParameterOptionGRPC() throws {
        struct WebService: Apodini.WebService {
            var content: some Component {
                LogarithmTester()
            }

            var configuration: Configuration {
                GRPC {
                    Protobuffer()
                }
            }
        }
        
        struct LogarithmTester: Handler {
            @Parameter(.gRPC(.fieldTag(3)))
            var base: Double
            
            @Parameter
            var exponent: Double
            
            @Parameter(.gRPC(.fieldTag(1)))
            var solution: Double
            
            func handle() -> Bool {
                log(exponent) / log(base) == solution
            }
        }
        
        let expected = """
            syntax = "proto3";

            service V1Service {
              rpc logarithmtester (LogarithmTesterMessage) returns (BoolMessage);
            }

            message BoolMessage {
              bool value = 1;
            }

            message LogarithmTesterMessage {
              double solution = 1;
              double exponent = 2;
              double base = 3;
            }
            """
        
        try testWebService(WebService.self, expectation: expected)
    }
    
    func testIntegerWidthConfiguration() throws {
        struct WebService: Apodini.WebService {
            var content: some Component {
                Locator()
            }
            
            var configuration: Configuration {
                GRPC(integerWidth: .thirtyTwo) {
                    Protobuffer()
                }
            }
        }
        
        struct Locator: Handler {
            func handle() -> Coordinate {
                .init(langitude: 0, longitude: 0)
            }
        }
        
        struct Coordinate: Apodini.Content {
            let langitude: UInt
            let longitude: UInt
        }
        
        let expected = """
            syntax = "proto3";

            service V1Service {
              rpc locator (LocatorMessage) returns (CoordinateMessage);
            }

            message CoordinateMessage {
              uint32 langitude = 1;
              uint32 longitude = 2;
            }

            message LocatorMessage {}
            """
        
        try testWebService(WebService.self, expectation: expected)
    }
}
