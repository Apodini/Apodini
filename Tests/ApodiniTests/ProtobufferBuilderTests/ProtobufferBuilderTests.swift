import XCTVapor
@testable import Apodini

final class ProtobufferBuilderTests: XCTestCase {
    func testWebService<S: WebService>(_ type: S.Type, expectation: String) throws {
        let app = Application(.testing)
        S.main(app: app)
        defer { app.shutdown() }
        
        try app.test(.GET, "apodini/proto") { res in
            XCTAssertEqual(res.body.string, expectation)
        }
    }
}

// MARK: - Test Components

extension ProtobufferBuilderTests {
    func testServiceParametersZero() throws {
        struct WebService: Apodini.WebService {
            var content: some Component {
                HelloWorld()
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
              rpc helloworld (VoidMessage) returns (StringMessage);
            }

            message StringMessage {
              string value = 1;
            }

            message VoidMessage {}
            """
        
        try testWebService(WebService.self, expectation: expected)
    }
    
    func testServiceParametersOne() throws {
        struct WebService: Apodini.WebService {
            var content: some Component {
                Greeter()
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
              rpc greeter (StringMessage) returns (StringMessage);
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
        }
        
        struct Multiplier: Handler {
            @Parameter
            var x: Int32
            
            @Parameter
            var y: Int32
            
            func handle() -> Int32 {
                x * y
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
              int32 x = 1;
              int32 y = 2;
            }
            """
        
        try testWebService(WebService.self, expectation: expected)
    }
}

// MARK: - Test Misc

extension ProtobufferBuilderTests {
    func testGenericPolymorphism() {
        XCTAssertFalse(Array<Any>.self == Array<Int>.self)
    }
}
