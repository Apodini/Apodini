//
//  Cookies.swift
//  
//
//  Created by Paul Schmiedmayer on 6/16/21.
//


/// An `Information` instance carrying information about cookies
public struct Cookies: Information {
    public static var key: String {
        "Cookie"
    }
    
    
    public private(set) var value: [String: String]
    
    
    public var rawValue: String {
        value.map { "\($0.0)=\($0.1)" }.joined(separator: "; ")
    }
    
    
    public init?(rawValue: String) {
        let keyValuePairs = rawValue.components(separatedBy: "; ")
        var cookies: [String: String] = Dictionary(minimumCapacity: keyValuePairs.count)
        
        for keyValuePair in keyValuePairs {
            if keyValuePair.count < 3 {
                continue
            }
            
            let substrings = keyValuePair.split(separator: "=", maxSplits: 1)
            guard substrings.count == 2 else {
                return nil
            }
            cookies[String(substrings[0])] = String(substrings[1])
        }
        
        self.init(cookies)
    }
    
    public init(_ value: [String: String]) {
        self.value = value
    }
}
