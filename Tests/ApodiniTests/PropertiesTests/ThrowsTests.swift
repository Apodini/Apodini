//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import XCTest
import XCTApodini
@testable import Apodini


class ThrowsTests: ApodiniTests {
    struct ErrorTestHandler: Handler {
        @Throws(.badInput, reason: "!badInput!", description: "<badInput>")
        var error1: ApodiniError
        
        @Throws(.badInput, reason: "!badInput!", information: MockIntInformationInstantiatable(4))
        var error2: ApodiniError
        
        @Throws(.badInput, description: "<badInput>")
        var error3: ApodiniError
        
        @Throws(.badInput, description: "<badInput>", AnyPropertyOption(key: .errorType, value: .other))
        var error4: ApodiniError

        var errorCode: Int = 0
        
        var applyChanges = false
        
        var reason: String?
        
        var description: String?
        
        func handle() throws -> Bool {
            switch errorCode {
            case 1:
                if applyChanges {
                    throw error1(reason: reason, description: description)
                } else {
                    throw error1
                }
            case 2:
                if applyChanges {
                    throw error2(reason: reason, description: description)
                } else {
                    throw error2
                }
            case 3:
                if applyChanges {
                    throw error3(reason: reason, description: description)
                } else {
                    throw error3
                }
            case 4:
                if applyChanges {
                    throw error4(reason: reason, description: description, options: .webSocketErrorCode(.goingAway))
                } else {
                    throw error4
                }
            default:
                return false
            }
        }
    }
    
    func testOptionMechanism() throws {
        // default
        XCTAssertEqual(.badInput, ErrorTestHandler(errorCode: 1).evaluationError().option(for: .errorType))
        // overwrite
        XCTAssertEqual(.other, ErrorTestHandler(errorCode: 4).evaluationError().option(for: .errorType))
    }
    
    func testReasonAndDescriptionPresence() throws {
        print(ErrorTestHandler(errorCode: 1).evaluationError().standardMessage)
        XCTAssertTrue(ErrorTestHandler(errorCode: 1).evaluationError().standardMessage.contains("!badInput!"))
        #if DEBUG
        XCTAssertTrue(ErrorTestHandler(errorCode: 1).evaluationError().standardMessage.contains("<badInput>"))
        #else
        XCTAssertFalse(ErrorTestHandler(errorCode: 1).evaluationError().standardMessage.contains("<badInput>"))
        #endif
        
        XCTAssertTrue(ErrorTestHandler(errorCode: 2).evaluationError().standardMessage.contains("!badInput!"))
        XCTAssertFalse(ErrorTestHandler(errorCode: 2).evaluationError().standardMessage.contains("<badInput>"))
        
        XCTAssertFalse(ErrorTestHandler(errorCode: 3).evaluationError().standardMessage.contains("!badInput!"))
        #if DEBUG
        XCTAssertTrue(ErrorTestHandler(errorCode: 3).evaluationError().standardMessage.contains("<badInput>"))
        #else
        XCTAssertFalse(ErrorTestHandler(errorCode: 3).evaluationError().standardMessage.contains("<badInput>"))
        #endif
    }
    
    func testReasonAndDescriptionOverwrite() throws {
        XCTAssertTrue(ErrorTestHandler(
            errorCode: 4,
            applyChanges: true,
            reason: "!other!",
            description: "<other>").evaluationError().standardMessage.contains("!other!")
        )
        #if DEBUG
        XCTAssertTrue(ErrorTestHandler(
            errorCode: 4,
            applyChanges: true,
            reason: "!other!",
            description: "<other>").evaluationError().standardMessage.contains("<other>")
        )
        #else
        XCTAssertFalse(ErrorTestHandler(
            errorCode: 4,
            applyChanges: true,
            reason: "!other!",
            description: "<other>").evaluationError().standardMessage.contains("<other>")
        )
        #endif
        
        XCTAssertTrue(ErrorTestHandler(
            errorCode: 4,
            applyChanges: true,
            reason: "!other!",
            description: nil).evaluationError().standardMessage.contains("!other!")
        )
        XCTAssertFalse(ErrorTestHandler(
            errorCode: 4,
            applyChanges: true,
            reason: "!other!",
            description: nil).evaluationError().standardMessage.contains("<other>")
        )
        
        XCTAssertFalse(ErrorTestHandler(
            errorCode: 4,
            applyChanges: true,
            reason: nil,
            description: "<other>").evaluationError().standardMessage.contains("!other!")
        )
        #if DEBUG
        XCTAssertTrue(ErrorTestHandler(
            errorCode: 4,
            applyChanges: true,
            reason: nil,
            description: "<other>").evaluationError().standardMessage.contains("<other>")
        )
        #else
        XCTAssertFalse(ErrorTestHandler(
            errorCode: 4,
            applyChanges: true,
            reason: nil,
            description: "<other>").evaluationError().standardMessage.contains("<other>")
        )
        #endif
    }

    func testInformation() throws {
        XCTAssertEqual(
            ErrorTestHandler(errorCode: 2).evaluationError().information[MockIntInformationInstantiatable.self],
            4
        )
    }
}

private extension ThrowsTests.ErrorTestHandler {
    func evaluationError() -> ApodiniError {
        do {
            _ = try handle()
            XCTFail("This function expects the Handler to fail.")
            return ApodiniError(type: .other)
        } catch {
            return error.apodiniError
        }
    }
}
