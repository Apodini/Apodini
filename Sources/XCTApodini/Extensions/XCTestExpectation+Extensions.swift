//
//  XCTestExpectation+Extensions.swift
//  
//
//  Created by Paul Schmiedmayer on 5/12/21.
//

import XCTest


extension XCTestExpectation {
    public convenience init(expectedFulfillmentCount: Int) {
        self.init()
        
        self.expectedFulfillmentCount = expectedFulfillmentCount
        self.assertForOverFulfill = true
    }
}
