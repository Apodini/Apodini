//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Algorithms


extension String {
    /// Returns the string, with the specified suffix appended if necessary
    public func withSuffix(_ suffix: String) -> String {
        guard !hasSuffix(suffix) else {
            return self
        }
        return self + suffix
    }
    
    
    /// Creates a string by interpreting a tuple of `UInt8` values as a C string.
    /// This is useful when working with C libraries, where the swift importer sometimes represents C-style arrays as tuples.
    /// - Note: This intentionally is a static function rather than an initializer, the reason being that,
    ///         due to the fact that this function takes `Any`, it would cause the typechecker to, in some cases,  prefer this `init` overload
    ///         over other better-matching overloads when initialising a string from some (generic) value.
    ///         Note that this even applies if the initializer has a named argument: if its called `init?(int8Tuple:)` and you write code like
    ///         `[Substring]().first.flatMap(String.init)`, the typechecker will resolve the `String.init` to the tuple-taking overload,
    ///         rather than the probably intended `String.init(Substring)` overload.
    public static func createFromInt8Tuple(_ int8Tuple: Any) -> String? {
        let mirror = Mirror(reflecting: int8Tuple)
        guard mirror.displayStyle == .tuple else {
            return nil
        }
        var str = ""
        str.reserveCapacity(mirror.children.count)
        for (_, value) in mirror.children {
            guard let value = value as? Int8 else {
                return nil
            }
            str.append(String(UnicodeScalar(UInt8(value))))
        }
        return str
    }
    
    
    /// Returns a copy of the string, with all quotation marks (both single `'` and double `"`) escaped.
    /// This function is intended for strings which are used as parameters to shell commands.
    public func shellEscaped() -> String {
        self
            .replacingOccurrences(of: "'", with: #"\'"#)
            .replacingOccurrences(of: "\"", with: #"\""#)
    }
    
    
    /// Returns a copy of the string with the first character capitalised.
    /// - Note: If you need the first character of every word capitalised, use `-[String capitalized]` instead
    public var capitalisingFirstCharacter: String {
        guard let first = self.first else {
            return self
        }
        return "\(first.uppercased())\(self.dropFirst())"
    }
    
    
    /// Produces a copy of this string, with all occurrences of the characters in the specified character set replaced with the replacement string
    public func replacingOccurrences(ofCharactersIn characterSet: Set<Character>, with replacement: String) -> String {
        self.reduce(into: String(reservingCapacity: self.count)) { partialResult, character in
            if characterSet.contains(character) {
                partialResult.append(replacement)
            } else {
                partialResult.append(character)
            }
        }
    }
    
    
    /// Checks whether the string starts with any of the strings passed in the set.
    public func startsWith(anyOf prefixes: Set<String>) -> Bool {
        prefixes.contains { self.starts(with: $0) }
    }
    
    
    /// Whether the string contains any of the specified characters
    public func contains(anyOf characters: Set<Character>) -> Bool {
        self.contains { characters.contains($0) }
    }
    
    /// Whether all chatacters in the string are also contained in the character set
    public func containsOnly(charsFrom characterSet: Set<Character>) -> Bool {
        self.allSatisfy { characterSet.contains($0) }
    }
    
    
    /// Returns a copy of the string, with its prefix dropped, if the prefix is contained in the set of specified prefixes to drop
    public func dropPrefix(ifAnyOf prefixes: Set<String>) -> String {
        let dropCount: Int = prefixes.first { self.starts(with: $0) }?.count ?? 0
        return String(self.dropFirst(dropCount))
    }
}


extension String {
    /// Returns a copy of this string, formatted as `camelCase`
    /// - parameter additionalWordDelimiters: Set of characters to be considered word delimiters, in addition to whitespace
    public func camelCase(additionalWordDelimiters: Set<Character> = ["_"]) -> String {
        splitIntoWords(delimiters: [.whitespace, .uppercase, .characterSet(additionalWordDelimiters)]).camelCase()
    }
    
    /// Returns a copy of this string, formatted as `PascalCase`
    /// - parameter additionalWordDelimiters: Set of characters to be considered word delimiters, in addition to whitespace
    public func pascalCase(additionalWordDelimiters: Set<Character> = ["_"]) -> String {
        splitIntoWords(delimiters: [.whitespace, .uppercase, .characterSet(additionalWordDelimiters)]).pascalCase()
    }
    
    
    /// Returns a copy of this string, formatted as `snake_case`
    /// - parameter additionalWordDelimiters: Set of characters to be considered word delimiters, in addition to whitespace
    public func snakeCase(additionalWordDelimiters: Set<Character> = ["_"]) -> String {
        splitIntoWords(delimiters: [.whitespace, .uppercase, .characterSet(additionalWordDelimiters)]).snakeCase()
    }
    
    
    /// A word delimiter, used to determine where words end and begin.
    public enum SplitIntoWordDelimiter {
        /// A character which should be considered a word delimiter
        case character(Character)
        /// A set of characters which should be considered word delimiters
        case characterSet(Set<Character>)
        /// A custom function allowing to determine whether a character is a word delimiter.
        /// This function takes two parameters, which will be the previous and the current character.
        case custom((Character, Character) -> Bool)
        
        /// Any whitespace character
        public static let whitespace = Self.custom { _, char in char.isWhitespace }
        
        /// An uppercase character following a lowercase character should be considered to implicitly start a new word
        public static let uppercase = Self.custom { prev, cur in
            prev.isLowercase && cur.isUppercase
        }
        
        /// Split by any non alphanumerical characters
        public static let notAlphaNumerical = Self.custom { _, cur in
            !cur.isLetter && !cur.isNumber
        }
    }
    
    
    /// Attempts to split the string into its individual words.
    public func splitIntoWords(delimiters: [SplitIntoWordDelimiter]) -> [String] {
        guard !self.isEmpty else {
            return []
        }
        guard self.count > 1 && !delimiters.isEmpty else {
            return [self]
        }
        var isDelimiter: (Character, Character) -> Bool = { _, _ in false }
        var allDelimChars: Set<Character> = []
        for delimiter in delimiters {
            switch delimiter {
            case .character(let char):
                allDelimChars.insert(char)
            case .characterSet(let chars):
                allDelimChars.formUnion(chars)
            case .custom(let block):
                isDelimiter = { [isDelimiter] in isDelimiter($0, $1) || block($0, $1) }
            }
        }
        if !allDelimChars.isEmpty {
            isDelimiter = { [isDelimiter] in isDelimiter($0, $1) || allDelimChars.contains($1) }
        }
        var words: [String] = []
        var currentWord = String(self.first!)
        for (prev, cur) in self.adjacentPairs() {
            if isDelimiter(prev, cur) {
                words.append(currentWord)
                currentWord.removeAll(keepingCapacity: true)
            }
            currentWord.append(cur)
        }
        if !currentWord.isEmpty {
            words.append(currentWord)
        }
        return words
    }
}


extension Array where Element == String {
    /// Produces a string by joining the elements of the array, using a `camelCase` formatting
    public func camelCase() -> String {
        guard !isEmpty else {
            return ""
        }
        return dropFirst().reduce(into: first!.lowercased()) { result, element in
            result.append(element.capitalisingFirstCharacter)
        }
    }
    
    /// Produces a string by joining the elements of the array, using a `PascalCase` formatting
    public func pascalCase() -> String {
        guard !isEmpty else {
            return ""
        }
        return dropFirst().reduce(into: first!.capitalisingFirstCharacter) { result, element in
            result.append(element.capitalisingFirstCharacter)
        }
    }
    
    /// Produces a string by joining the elements of the array, using a `snake_case` formatting
    public func snakeCase() -> String {
        guard !isEmpty else {
            return ""
        }
        return dropFirst().reduce(into: first!.lowercased()) {
            $0.append("_\($1.lowercased())")
        }
    }
}


// MARK: Trimming

extension String {
    /// For trim operationg on a string, the place where the operation should take place
    public struct TrimLocation: OptionSet {
        public let rawValue: UInt8
        
        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
        
        public static let leading = TrimLocation(rawValue: 1 << 1)
        public static let trailing = TrimLocation(rawValue: 1 << 2)
    }
    
    
    /// Returns a copy of this string, with the specified characters removed from the specified trim locations.
    public func trimmingCharacters(from characterSet: Set<Character>, at locations: TrimLocation = [.leading, .trailing]) -> String {
        guard !locations.isEmpty else {
            return self
        }
        var result = self[...]
        if locations.contains(.leading) {
            result = result.trimmingPrefix(while: { characterSet.contains($0) })
        }
        if locations.contains(.trailing) {
            result = result.trimmingSuffix(while: { characterSet.contains($0) })
        }
        return String(result)
    }
}


extension StringProtocol {
    /// Returns a Substring with the receiver's leading and trailing whitespace removed
    public func trimmingLeadingAndTrailingWhitespace() -> SubSequence {
        self.trimmingLeadingWhitespace().trimmingTrailingWhitespace()
    }
    
    /// Returns a Substring with the receiver's leading whitespace removed
    public func trimmingLeadingWhitespace() -> SubSequence {
        if let first = self.first, first.isWhitespace {
            return dropFirst().trimmingLeadingWhitespace()
        } else {
            return self[...]
        }
    }
    
    /// Returns a Substring with the receiver's trailing whitespace removed
    public func trimmingTrailingWhitespace() -> SubSequence {
        if let last = self.last, last.isWhitespace {
            return dropLast().trimmingTrailingWhitespace()
        } else {
            return self[...]
        }
    }
}


// MARK: Set<Character>

extension Set where Element == Character {
    /// The set of  all `Character`s which are US-ASCII characters
    public static let ascii = Set<Character>(asciiRange: 0...127)
    
    /// The set of all `Character`s which are US-ASCII control characters
    public static let asciiControlCharacters = Set(asciiRange: 0...31).union([Character(Unicode.Scalar(0x7f))])
    
    /// The set of all `Character`s which are US-ASCII numerals
    public static let asciiNumerals = Set(asciiRange: 48...57)
    
    /// Creates a character set for the specified ascii range
    public init(asciiRange: ClosedRange<UInt8>) {
        self = asciiRange.mapIntoSet { Character(Unicode.Scalar($0)) }
    }
}
