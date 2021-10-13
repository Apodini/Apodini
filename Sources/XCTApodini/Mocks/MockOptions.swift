//
//  MockOptions.swift
//  
//
//  Created by Paul Schmiedmayer on 5/12/21.
//


public struct MockOptions: OptionSet {
    public static let doNotReduceRequest = MockOptions(rawValue: 0b001)
    public static let doNotReuseConnection = MockOptions(rawValue: 0b011)
    public static let subsequentRequest: MockOptions = []
    
    
    public let rawValue: UInt8
    
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
}
