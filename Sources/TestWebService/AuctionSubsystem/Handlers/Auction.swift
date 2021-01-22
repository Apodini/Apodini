//
//  Auction.swift
//  
//
//  Created by Paul Schmiedmayer on 1/19/21.
//

import Apodini


struct Auction: Handler {
    static let minimumBid: UInt = 1000
    
    
    @Parameter var bid: UInt
    
    @Environment(\.connection) var connection: Connection
    
    @State var highestBid: UInt = 0
    
    
    func handle() -> Response<String> {
        if connection.state == .open {
            if bid > highestBid {
                highestBid = bid
                return .send("accepted")
            } else {
                return .send("denied")
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
