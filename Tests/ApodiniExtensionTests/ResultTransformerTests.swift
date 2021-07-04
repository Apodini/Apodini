//
//  ResultHandlerTests.swift
//  
//
//  Created by Max Obermeier on 04.07.21.
//

import Foundation
import XCTApodini


class ResultTransformerTests: XCTApodiniTest {   
    struct ResponseUnawareTransformer<E: Encodable>: ResultTransformer {
        func transform(input: E) throws -> E {
            input
        }
        
        func handle(error: ApodiniError) -> ErrorHandlingStrategy<E, ApodiniError> {
                .abort(error)
        }
    }

    
    func testNothingWithResponseUnawareTransformerThrows() throws {
        let eventLoop = app.eventLoopGroup.next()
        
        do {
            _ = try eventLoop.makeSucceededFuture(Response<String>.nothing)
                                .transform(using: ResponseUnawareTransformer())
                                .wait()
            XCTFail("Should have thrown!")
        } catch {
            let apodini = try XCTUnwrap(error as? ApodiniError)
            
            XCTAssertEqual(apodini.option(for: .errorType), .serverError)
        }
    }
    
    func testSomethingWithResponseUnawareTransformer() throws {
        let eventLoop = app.eventLoopGroup.next()

        let response = try eventLoop
                            .makeSucceededFuture(Response<String>.send(""))
                            .transform(using: ResponseUnawareTransformer())
                            .wait()

        XCTAssertEqual(response, "")
    }
}
