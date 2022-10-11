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

struct SummingHandler: Handler {
    @Parameter(.http(.query)) var number: Int
    @Environment(\.connection) var connection: Connection
    @State var sum: Int = 0
    
    func handle() -> Response<SumStruct> {
        switch connection.state {
        case .close:
            return .final(SumStruct(sum: sum))
        case .end:
            return .final(SumStruct(sum: sum + number))
        case .open:
            sum += number
            return .nothing
        }
    }
    
    var metadata: AnyHandlerMetadata {
        Operation(.create)
        Pattern(.clientSideStream)
    }
}

// Receives one number n. Sends n responses, with response x having length x bytes, all bytes set to 1.
struct IncreasingBlobLengthHandler: Handler {
    @Parameter(.mutability(.constant)) var max: Int
    @ObservedObject var countup = Countup()
    
    func handle() -> Response<Blob> {
        if countup.count > max {
            return .end
        }
        
        // Send blob
        let bytes = Array(repeating: UInt8(1), count: countup.count)
        let byteBuffer = ByteBuffer(bytes: bytes)
        
        countup.increase()
        return .send(Blob(byteBuffer))
    }
    
    var metadata: AnyHandlerMetadata {
        Operation(.create)
        Pattern(.serviceSideStream)
    }
}

class Countup: Apodini.ObservableObject {
    @Apodini.Published var count = 1
    func increase() {
        count += 1
    }
}

struct AddStruct: Codable {
    let sum: Int
    let number: Int
}

struct SumStruct: Codable {
    let sum: Int
}

struct NumberStruct: Codable {
    let number: Int
}

struct MaxStruct: Codable {
    let max: Int
}

@ConfigurationBuilder
var httpsConfiguration: Configuration {
    HTTP()
    
    HTTPConfiguration(
        bindAddress: .init(address: "localhost", port: 4443),
        tlsConfiguration: try! .makeServerConfiguration(
            certificatePath: try! XCTUnwrap(Bundle.module.url(forResource: "apodini_https_cert_localhost.cer", withExtension: "pem")).path,
            keyPath: try! XCTUnwrap(Bundle.module.url(forResource: "apodini_https_cert_localhost.key", withExtension: "pem")).path
        )
    )
}

@ComponentBuilder
var http2Content: some Component {
    AddHandler()
    Group("ss") {
        ServiceSideStreamingHandler()
    }
    Group("cs") {
        SummingHandler()
    }
    Group("ss2") {
        IncreasingBlobLengthHandler()
    }
}
