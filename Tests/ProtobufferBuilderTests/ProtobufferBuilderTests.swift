import XCTVapor
@testable import Apodini
import ProtobufferBuilder

final class ProtobufferBuilderTests: XCTestCase {
    func testWebService<S: WebService>(_ type: S.Type, expectation: String) throws {
        let app = try S.prepare(testing: true)
        defer { app.shutdown() }
        try app.test(.GET, "apodini/proto") { res in
            XCTAssertEqual(res.body.string, expectation)
        }
    }
}

// MARK: - Test Components

extension ProtobufferBuilderTests {
    func testHelloWorldService() throws {
        struct WebService: Apodini.WebService {
            var content: some Component {
                HelloWorld()
            }
        }
        
        struct HelloWorld: Component {
            func handle() -> String {
                "Hello, World!"
            }
        }
        
        let expected = """
            syntax = "proto3";

            service V1Service {
              rpc handle (VoidMessage) returns (StringMessage);
            }

            message StringMessage {
              string value = 1;
            }

            message VoidMessage {}
            """
        
        try testWebService(WebService.self, expectation: expected)
    }
    
    func testGreeterService() throws {
        struct WebService: Apodini.WebService {
            var content: some Component {
                Greeter()
            }
        }
        
        struct Greeter: Component {
            @Parameter
            var name: String
            
            func handle() -> String {
                "Hello \(name)"
            }
        }
        
        let expected = """
            syntax = "proto3";

            service V1Service {
              rpc handle (StringMessage) returns (StringMessage);
            }

            message StringMessage {
              string value = 1;
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
