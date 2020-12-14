import XCTest
import Apodini
import ProtobufferBuilder

final class ProtobufferBuilderTests: XCTestCase {}

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
        
        let expected = """
            syntax = "proto3";

            service GreeterService {
              rpc handle (StringMessage) returns (StringMessage);
            }

            message StringMessage {
              string value = 1;
            }
            """
        
        XCTAssertEqual(try buildService(Greeter.self), expected)
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
private func buildService<T: Component>(_ type: T.Type) throws -> String {
    let builder = ProtobufferBuilder()
    try builder.addService(of: type, returning: type.Response.self)
    let description = builder.description
    
    print("""
        ----
        \(description)
        ----
        """)
    
    return description
}
