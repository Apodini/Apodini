//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Apodini

struct Auction: Handler {
    @Throws(.badInput, reason: "The placed bid was too low") var bidTooLowError: ApodiniError
    
    static let minimumBid: UInt = 1000
    
    @Parameter var bid: UInt
    
    @Environment(\.connection) var connection: Connection
    
    @State var highestBid: UInt = 0
    
    func handle() throws -> Response<String> {
        if connection.state == .open {
            if bid > highestBid {
                highestBid = bid
                return .send("bid accepted")
            } else {
                throw bidTooLowError(description: "highest: \(highestBid); received: \(bid)")
            }
        } else {
            if highestBid >= Self.minimumBid {
                return .final("sold")
            } else {
                return .final("not sold")
            }
        }
    }
}
