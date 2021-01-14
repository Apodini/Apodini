//
//  AssertTypeIsStruct.swift
//  
//
//  Created by Paul Schmiedmayer on 1/11/21.
//

import Runtime


/// - parameter T: The type for which to assert that it is a struct
/// - parameter messagePrefix: An optional string which will be prefixed to the "T must be a struct" message
internal func assertTypeIsStruct<T>(_: T.Type, messagePrefix: String? = nil) {
    guard let typeInfo = try? Runtime.typeInfo(of: T.self) else {
        fatalError("Unable to get type info for type '\(T.self)'")
    }
    precondition(typeInfo.kind == .struct, "\(messagePrefix.map { $0 + " " } ?? "")'\(typeInfo.name)' must be a struct")
}
