import XCTVapor
@testable import Apodini

final class ProtobufferBuilderTests: XCTestCase {
    func testWebService<S: WebService>(_ type: S.Type, expectation: String) throws {
        let app = Application()
        S.main(app: app)
        defer { app.shutdown() }
        
        try app.vapor.app.test(.GET, "apodini/proto") { res in
            XCTAssertEqual(res.body.string, expectation)
        }
    }
    
    override func tearDown() {
        RHIInterfaceExporter.resetSingleton()
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
    
    func testGreeterService() throws {
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
}

// MARK: - Test Misc

extension ProtobufferBuilderTests {
    func testGenericPolymorphism() {
        XCTAssertFalse(Array<Any>.self == Array<Int>.self)
    }
}
