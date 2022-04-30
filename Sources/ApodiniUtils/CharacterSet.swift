//
//  File.swift
//  
//
//  Created by Lukas Kollmer on 2022-04-30.
//

import Foundation


extension Set where Element == Character {
    /// The set of  all `Character`s which are US-ASCII characters
    public static let ascii = Set<Character>((0...127).map { Character(Unicode.Scalar($0)) })
    /// The set of all `Character`s which are US-ASCII control characters
    public static let asciiControlCharacters = Set<Character>((0...31).map { Character(Unicode.Scalar($0)) })
}
