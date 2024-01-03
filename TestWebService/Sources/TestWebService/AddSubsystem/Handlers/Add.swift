//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Apodini


struct Add: Handler {
    @Parameter(.http(.query)) var sum: Int
    @Parameter(.http(.query)) var number: Int
    @Environment(\.connection) var connection: Connection
    @State var nextExpectedSum = 0
    
    func handle() -> Response<AddStruct> {
        if connection.state == .close {
            return .final()
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
    
    var metadata: any AnyHandlerMetadata {
        Pattern(.bidirectionalStream)
        Operation(.create)
    }
    
//    deinit {
//        print("AddHandler is being deinitialized!")
//    }
}

struct AddStruct: Codable {
    var sum: Int
    var number: Int
}
