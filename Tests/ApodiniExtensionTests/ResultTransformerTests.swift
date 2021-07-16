//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
