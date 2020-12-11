import XCTest
import Apodini
import Vapor

/// `ProtobufferBuilderIntegrationTests` tests the interplay of two modules,
/// **Apodini** and **ProtobufferBuilder**.
final class ProtobufferBuilderIntegrationTests: XCTestCase {
    func testPokemonWebService() throws {
        struct Pokemon: Component, ResponseEncodable {
            let id: Int64
            let name: String
            
            func handle() -> Pokemon {
                self
            }
            
            func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
                fatalError("Missing implementation for test")
            }
        }
        
        struct PokemonWebService: WebService {
            var content: some Component {
                Group("pokemon") {
                    Pokemon(id: 25, name: "Pikachu")
                }
            }
        }
        
        IntegrationTest<PokemonWebService>(
            url: "http://127.0.0.1:8080/apodini/proto",
            expectedResponse: """
                syntax = "proto3";
                
                service PokemonService {
                  rpc handle (VoidMessage) returns (PokemonMessage);
                }

                message PokemonMessage {
                  int64 id = 1;
                  string name = 2;
                }

                message VoidMessage {}
                """
        )
        .execute(in: self)
    }
}
