//
// Created by Sadik Ekin Ozbay on 02.02.21.
//
// swiftlint:disable identifier_name

import XCTest
import Vapor
import GraphQL
@testable import Apodini


class GraphQLInterfaceExporterTests: ApodiniTests {
    struct Parameters: Apodini.Content, Decodable, Equatable {
        var param0: String
        var param1: String?
        var param2: Int
    }

    struct ParameterTestHandler: Handler {
        @Parameter var param0: String
        @Parameter var param1: String?
        @Parameter var param2: Int


        func handle() -> Parameters {
            Parameters(param0: param0, param1: param1, param2: param2)
        }
    }

    struct RequestStruct: Encodable {
        let query: String
    }

    struct GraphQLResultContainer<D: Decodable>: Decodable {
        let data: D
    }

    func testHelper<W: Apodini.WebService, R: Decodable & Equatable>(webService: W, query: String, result: R) {
        let builder = SemanticModelBuilder(app)
            .with(exporter: GraphQLInterfaceExporter.self)
        webService.register(builder)

        do {
            let bodyData = ByteBuffer(data: try JSONEncoder().encode(RequestStruct(query: query)))

            do {
                try app.vapor.app.testable(method: .inMemory).test(.POST, "/graphql", body: bodyData) { response in
                    XCTAssertEqual(response.status, .ok)

                    let container = try response.content.decode(GraphQLResultContainer<R>.self)
                    XCTAssertEqual(container.data, result)
                }
            } catch {
                XCTFail("Vapor app request error!")
            }
        } catch {
            XCTFail("Couldn't encode the query!")
            return
        }
    }


    func testParameterRetrieval() throws {
        struct ParameterTestService: Apodini.WebService {
            var content: some Component {
                Group("param") {
                    ParameterTestHandler()
                }
            }
        }


        struct ParameterResponse: Apodini.Content, Decodable, Equatable {
            var param = Parameters(param0: "The First Parameter", param1: nil, param2: 11)
        }

        struct V1Container: Apodini.Content, Decodable, Equatable {
            var v1 = ParameterResponse()
        }

        let query = """
                    query {
                        v1  {
                            param(param0: "The First Parameter", param2: 11) {
                                    param0
                                    param2
                                }
                            
                        }
                    }
                    """

        testHelper(webService: ParameterTestService(), query: query, result: V1Container())
    }

    func testRelationRetrieval() throws {
        struct ParameterNestedService: Apodini.WebService {
            var content: some Component {
                Group("param") {
                    ParameterTestHandler()
                    Group("myparam") {
                        Text("Hello")
                    }
                }
            }
        }


        struct RelationParameter: Apodini.Content, Decodable, Equatable {
            var parameters: Parameters
            var myparam: String
        }


        struct ParameterResponse: Apodini.Content, Decodable, Equatable {
            var param = RelationParameter(parameters: Parameters(param0: "The First Parameter", param1: nil, param2: 11), myparam: "Hello")
        }

        struct V1Container: Apodini.Content, Decodable, Equatable {
            var v1 = ParameterResponse()
        }


        let query = """
                    query {
                    v1 {
                        param{
                            parameters(param0: "The First Parameter", param2: 11) {
                                param0
                                param2
                            }
                            myparam
                        }
                    }
                    }
                    """

        testHelper(webService: ParameterNestedService(), query: query, result: V1Container())
    }
}
