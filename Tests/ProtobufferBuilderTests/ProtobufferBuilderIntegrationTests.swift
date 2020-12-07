import XCTest
import Apodini
import Vapor

final class ProtobufferBuilderIntegrationTests: XCTestCase {
    func testPokemonWebService() throws {
        struct Pokemon: Component, ResponseEncodable {
            let id: Int64
            let name: String
            
            func handle() -> Pokemon {
                self
            }
            
            func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
                fatalError("Missing implementation for test.")
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

                message Pokemon {
                  Int64 id = 0;
                  String name = 1;
                }
                """
        )
        .execute(in: self)
    }
}
