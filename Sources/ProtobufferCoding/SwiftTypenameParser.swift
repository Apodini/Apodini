//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import ApodiniUtils


class SwiftTypename: Hashable, CustomStringConvertible {
    var baseName: String
    let genericArguments: [SwiftTypename]
    private(set) var parentType: SwiftTypename?
    /// Name of the module in which the type was defined.
    private(set) var module: String?
    
    init(baseName: String, genericArguments: [SwiftTypename], parentType: SwiftTypename?, module: String? = nil) {
        self.baseName = baseName
        self.genericArguments = genericArguments
        self.parentType = parentType
        self.module = module
    }
    
    convenience init(type: Any.Type) {
        self.init(typename: String(reflecting: type))!
    }
    
    convenience init?(typename: String) {
        if let typename = TypenameParser.parse(typename) {
            self.init(
                baseName: typename.baseName,
                genericArguments: typename.genericArguments,
                parentType: typename.parentType,
                module: typename.module
            )
            fixModuleNames()
        } else {
            return nil
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    static func == (lhs: SwiftTypename, rhs: SwiftTypename) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
    
    var description: String {
        description(includeModule: false)
    }
    
    
    func description(includeModule: Bool) -> String {
        var desc = ""
        if let parent = parentType {
            desc = parent.description
            desc.append(".")
        } else if includeModule, let module = module {
            desc = module
            desc.append(".")
        }
        desc.append(baseName)
        if !genericArguments.isEmpty {
            desc.append("<")
            desc.append(genericArguments.map(\.description).joined(separator: ", "))
            desc.append(">")
        }
        return desc
    }
    
    /// Sets the modules for all types in this type construct,
    /// by removing the topmost parent and using its name as the module name.
    private func fixModuleNames() {
        guard parentType != nil else {
            return
        }
        let typeHierarchy = Array(sequence(first: self, next: \.parentType))
        precondition(typeHierarchy.count >= 2)
        precondition(typeHierarchy.last!.genericArguments.isEmpty && typeHierarchy.last!.parentType == nil)
        let moduleName = typeHierarchy.last!.baseName
        precondition(typeHierarchy[typeHierarchy.count - 2].parentType == typeHierarchy.last!)
        typeHierarchy[typeHierarchy.count - 2].parentType = nil
        for type in typeHierarchy.dropLast() {
            type.module = moduleName
            for type in type.genericArguments {
                type.fixModuleNames()
            }
        }
    }
    
    
    /// Returns a possibly mangled string that can be used as a proto message typename
    func mangleForProto(strict: Bool) -> String {
        var mangledName = ""
        if let parent = parentType {
            let mangledParent = parent.mangleForProto(strict: strict)
            if strict {
                mangledName = "M\(mangledParent.count)\(mangledParent)"
            } else {
                mangledName = "\(mangledParent)."
            }
        }
        if strict {
            mangledName.append("M\(baseName.count)\(baseName)")
        } else {
            mangledName.append(baseName)
        }
        if !genericArguments.isEmpty {
            mangledName.append("T\(genericArguments.count)")
            for arg in genericArguments {
                // we have to enable strict mode here to make sure that the generic args list doesn't contain periods,
                // since that'd mess up the proto parent type deyection/handling stuff
                let argMangled = arg.mangleForProto(strict: true)
                mangledName.append("M\(argMangled.count)\(argMangled)")
            }
        }
        return mangledName
    }
}


private enum Token: Hashable {
    case period
    case identifier(String)
    case angledBracketLeft
    case angledBracketRight
    case comma
    case openingParen
    case closingParen
}


private struct TypenameParser {
    enum ParserError: Swift.Error {
        case invalidInput
    }
    
    private let tokens: [Token]
    private var position: Int = 0
    
    private init(input: String) {
        self.tokens = Lexer.lex(input)
    }
    
    static func parse(_ inputTypename: String) -> SwiftTypename? {
        let sanitizedInput = inputTypename
            .split(separator: ".")
            .filter { !$0.hasPrefix("(unknown context at") }
            .joined(separator: ".")
        var parser = TypenameParser(input: sanitizedInput)
        return try? parser.parse()
    }
    
    
    private var currentToken: Token? {
        tokens[safe: position]
    }
    private var nextToken: Token? {
        tokens[safe: position + 1]
    }
    
    private mutating func consume() {
        position += 1
    }
    
    
    private mutating func parse() throws -> SwiftTypename {
        let type = try parseType()
        precondition(position == tokens.endIndex)
        return type
    }
    
    
    private mutating func parseType() throws -> SwiftTypename { // swiftlint:disable:this cyclomatic_complexity
        var parentType: SwiftTypename?
        var prevPosition = position
        loop: while currentToken != nil {
            switch currentToken! {
            case .identifier(let ident):
                consume()
                switch currentToken {
                case nil, .comma, .angledBracketRight, .closingParen:
                    return SwiftTypename(baseName: ident, genericArguments: [], parentType: parentType)
                case .identifier, .openingParen:
                    throw ParserError.invalidInput
                case .period:
                    parentType = SwiftTypename(baseName: ident, genericArguments: [], parentType: parentType)
                    continue
                case .angledBracketLeft:
                    parentType = SwiftTypename(baseName: ident, genericArguments: try parseTypeList(), parentType: parentType)
                }
            case .angledBracketLeft:
                throw ParserError.invalidInput
            case .comma, .angledBracketRight, .closingParen:
                break loop
            case .openingParen:
                parentType = SwiftTypename(baseName: "__Tuple", genericArguments: try parseTypeList(), parentType: parentType)
            case .period:
                consume()
                switch currentToken {
                case nil, .period, .comma, .angledBracketLeft, .angledBracketRight, .openingParen, .closingParen:
                    throw ParserError.invalidInput
                case .identifier(let ident):
                    continue
                }
            }
        }
        if let type = parentType {
            return type
        } else {
            throw ParserError.invalidInput
        }
    }
    
    
    private mutating func parseTypeList() throws -> [SwiftTypename] {
        guard currentToken != nil else {
            throw ParserError.invalidInput
        }
        let initialToken = currentToken!
        switch currentToken! {
        case .angledBracketLeft, .openingParen:
            consume()
        case .identifier, .period, .comma, .angledBracketRight, .closingParen:
            throw ParserError.invalidInput
        }
        var types: [SwiftTypename] = []
        var prevPosition: Int?
        loop: while currentToken != nil, prevPosition != position {
            prevPosition = position
            types.append(try parseType())
            switch currentToken {
            case .angledBracketRight:
                if initialToken == .angledBracketLeft {
                    consume()
                    break loop
                } else {
                    throw ParserError.invalidInput
                }
            case .closingParen:
                if initialToken == .openingParen {
                    consume()
                    break loop
                } else {
                    throw ParserError.invalidInput
                }
            case .comma:
                consume()
            case .none, .identifier, .angledBracketLeft, .openingParen, .period:
                throw ParserError.invalidInput
            }
        }
        precondition(!types.isEmpty)
        return types
    }
}


private struct Lexer {
    private let input: String
    private var position: Int = 0
    private var tokens: [Token] = []
    
    private var currentChar: Character {
        let idx = input.index(input.startIndex, offsetBy: position)
        return input[idx]
    }
    
    private var isAtEnd: Bool {
        let idx = input.index(input.startIndex, offsetBy: position)
        return idx >= input.endIndex
    }
    
    static func lex(_ input: String) -> [Token] {
        precondition(input.allSatisfy(\.isASCII), "Can only parse ASCII typenames")
        var lexer = Lexer(input: input)
        lexer.lex()
        return lexer.tokens
    }
    
    private mutating func lex() {
        while !isAtEnd {
            let char = currentChar
            switch char {
            case ".":
                tokens.append(.period)
                position += 1
            case "<":
                tokens.append(.angledBracketLeft)
                position += 1
            case ">":
                tokens.append(.angledBracketRight)
                position += 1
            case ",":
                tokens.append(.comma)
                position += 1
            case "(":
                tokens.append(.openingParen)
                position += 1
            case ")":
                tokens.append(.closingParen)
                position += 1
            case " ":
                precondition(tokens.last == .comma)
                position += 1
            default:
                precondition(isIdentChar(char))
                var ident = ""
                repeat {
                    ident.append(currentChar)
                    position += 1
                } while !isAtEnd && isIdentChar(currentChar)
                tokens.append(.identifier(ident))
            }
        }
    }
    
    
    // MARK: Char checking
    
    private func isInInclusiveRange(_ char: Character, _ lower: Character, _ upper: Character) -> Bool {
        (lower.asciiValue!...upper.asciiValue!).contains(char.asciiValue!)
    }
    
    private func isDecimalDigitChar(_ char: Character) -> Bool {
        isInInclusiveRange(char, "0", "9")
    }
    
    private func isLetterChar(_ char: Character) -> Bool {
        isInInclusiveRange(char, "a", "z") || isInInclusiveRange(char, "A", "Z")
    }
    
    private func isIdentStartChar(_ char: Character) -> Bool {
        char == "_" || isLetterChar(char)
    }
    
    private func isIdentChar(_ char: Character) -> Bool {
        isIdentStartChar(char) || isDecimalDigitChar(char)
    }
}
