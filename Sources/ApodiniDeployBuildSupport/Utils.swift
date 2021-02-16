//
//  File.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-01.
//

import Foundation






extension Collection {
    /// Count the number of elements matching `predicate`
    public func lk_count(where predicate: (Element) throws -> Bool) rethrows -> Int {
        try reduce(into: 0) { $0 += try predicate($1) ? 1 : 0 }
    }
    
    
    /// Returns the first element after the specified index, which matches the predicate
    public func lk_first(after idx: Index, where predicate: (Element) throws -> Bool) rethrows -> Element? {
        return try lk_firstIndex(from: index(after: idx), where: predicate).map { self[$0] }
    }
    
    
    public func lk_firstIndex(after idx: Index, where predicate: (Element) throws -> Bool) rethrows -> Index? {
        return try lk_firstIndex(from: index(after: idx), where: predicate)
    }
    
    /// Returns the first index within the collection which matches a predicate, starting at `from`.
    public func lk_firstIndex(from idx: Index, where predicate: (Element) throws -> Bool) rethrows -> Index? {
        guard indices.contains(idx) else {
            return nil
        }
        if try predicate(self[idx]) {
            return idx
        } else {
            return try lk_firstIndex(from: index(after: idx), where: predicate)
        }
    }
}




// MARK: Other








// was intended as a Codable-conformant NSNull implemnentation. can we get rid of this?
public struct Null: Codable {
    public init() {}
    
    public init(from decoder: Decoder) throws {
        let wasNil = try decoder.singleValueContainer().decodeNil()
        if !wasNil {
            throw NSError(domain: "Apodini", code: 0, userInfo: [NSLocalizedDescriptionKey: "wasnt nil"])
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}
