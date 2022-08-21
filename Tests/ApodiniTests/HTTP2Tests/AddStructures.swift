//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import XCTApodini
@testable import XCTApodiniNetworking
import ApodiniHTTP
@testable import Apodini

struct AddHandler: Handler {
    @Parameter(.http(.query)) var sum: Int
    @Parameter(.http(.query)) var number: Int
    @Environment(\.connection) var connection: Connection
    @State var nextExpectedSum = 0
    
    func handle() -> Response<AddStruct> {
        switch connection.state {
        case .close:
            return .final()
        default:
            break
        }
        
        // Verify that the request is correct given the last response we sent
        if sum != nextExpectedSum {
            let failAddStruct = AddStruct(sum: -1, number: -1)
            return .final(failAddStruct)
        }
        
        let newNumber = Int.random(in: 0..<10)
        let confirmedSum = self.sum + self.number
        self.nextExpectedSum = confirmedSum + newNumber
        let responseAddStruct = AddStruct(sum: confirmedSum, number: newNumber)
        
        
        switch connection.state {
        case .open:
            return .send(responseAddStruct)
        case .end:
            return .final(responseAddStruct)
        default:
            return .final()
        }
    }
    
    var metadata: AnyHandlerMetadata {
        Pattern(.bidirectionalStream)
        Operation(.create)
    }
}

struct ServiceSideStreamingHandler: Handler {
    @Parameter(.http(.query)) var sum: Int
    @Parameter(.http(.query)) var number: Int
    
    func handle() -> Response<AddStruct> {
        .send(AddStruct(sum: 3, number: 3))
    }
    
    var metadata: AnyHandlerMetadata {
        Operation(.create)
        Pattern(.serviceSideStream)
    }
}

struct AddStruct: Codable {
    let sum: Int
    let number: Int
}

enum AddStuff {
    @ConfigurationBuilder
    static var configuration: Configuration {
        HTTP()
        
        HTTPConfiguration(
            bindAddress: .interface("localhost", port: 4443),
            tlsConfiguration: .init(
                certificatePath: try! XCTUnwrap(Bundle.module.url(forResource: "apodini_https_cert_localhost.cer", withExtension: "pem")).path,
                keyPath: try! XCTUnwrap(Bundle.module.url(forResource: "apodini_https_cert_localhost.key", withExtension: "pem")).path
            )
        )
    }

    @ComponentBuilder
    static var content: some Component {
        AddHandler()
        Group("ss") {
            ServiceSideStreamingHandler()
        }
    }
}
