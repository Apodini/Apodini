//
//  EndpointsTreeTests.swift
//  
//
//  Created by Lorena Schlesinger on 06.12.20.
//

@testable import Apodini
import XCTest


final class EndpointsTreeTests: XCTestCase {
    
    struct Birthdate: Codable {
        let year: Int
        let day: Int
        let month: Int
    }
    
    struct TestHandler: Component {
        @Parameter
        var name: String
        
        @Parameter("times", .http(.body))
        var times: Int
        
        @Parameter
        var birthdate: Birthdate
        
        func handle() -> String {
            (0...times)
                .map { _ in
                    "Hello \(name) born in \(birthdate.year)!"
                }
                .joined(separator: " ")
        }
    }
    
    struct TestComponent: Component {
        @PathParameter
        var name: String
        
        var content: some Component {
            Group("birthdate", $name) {
                TestHandler(name: $name)
            }
        }
    }
    
    func testEndpointParameters() throws {
        let testComponent = TestComponent()
        let testHandler = try XCTUnwrap(testComponent.content.content as? TestHandler)
        
        let requestInjectables: [String: RequestInjectable] = extractRequestInjectables(from: testHandler)
        let endpoint = Endpoint(
                description: String(describing: testHandler),
                context: Context(contextNode: ContextNode()),
                operation: Operation.automatic,
                guards: [],
                requestInjectables: requestInjectables,
                handleMethod: testHandler.handle,
                responseTransformers: [],
                handleReturnType: TestHandler.Response.self
        )
        
        let parameters: [EndpointParameter] = endpoint.parameters
        let nameParameter: EndpointParameter = parameters.first { $0.label == "_name" }!
        let timesParameter: EndpointParameter = parameters.first { $0.label == "_times" }!
        let birthdateParameter: EndpointParameter = parameters.first { $0.label == "_birthdate" }!
        
        // basic checks to ensure proper parameter parsing
        XCTAssertEqual(nameParameter.id, (requestInjectables["_name"] as! Parameter<String>).id)
        XCTAssertEqual(timesParameter.id, (requestInjectables["_times"] as! Parameter<Int>).id)
        XCTAssertEqual(timesParameter.options.option(for: PropertyOptionKey.http), (requestInjectables["_times"] as! Parameter<Int>).option(for: PropertyOptionKey.http))
        XCTAssertEqual(birthdateParameter.id, (requestInjectables["_birthdate"] as! Parameter<Birthdate>).id)
        
        // check whether categorization works
        XCTAssertTrue(endpoint.contentParameters.contains {$0.id == birthdateParameter.id})
        XCTAssertTrue(endpoint.contentParameters.contains {$0.id == timesParameter.id})
        XCTAssertFalse(endpoint.contentParameters.contains {$0.id == nameParameter.id})
        XCTAssertFalse(endpoint.pathParameters.contains {$0.id == birthdateParameter.id})
        XCTAssertFalse(endpoint.pathParameters.contains {$0.id == timesParameter.id})
        XCTAssertTrue(endpoint.pathParameters.contains {$0.id == nameParameter.id})
        XCTAssertFalse(endpoint.lightweightParameters.contains {$0.id == birthdateParameter.id})
        XCTAssertFalse(endpoint.lightweightParameters.contains {$0.id == timesParameter.id})
        XCTAssertFalse(endpoint.lightweightParameters.contains {$0.id == nameParameter.id})
    }
    
}
