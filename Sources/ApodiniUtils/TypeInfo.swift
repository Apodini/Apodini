//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Foundation
@_implementationOnly import Runtime
@_implementationOnly import AssociatedTypeRequirementsVisitor


/// Returns the mangled name of a type
public func mangledName(of type: Any.Type) -> String {
    do {
        let typeInfo = try Runtime.typeInfo(of: type)
        return typeInfo.mangledName
    } catch {
        return "\(type)"
    }
}


/// Test whether a type is an `Optional`
public func isOptional(_ type: Any.Type) -> Bool {
    do {
        let typeInfo = try Runtime.typeInfo(of: type)
        return typeInfo.kind == .optional
    } catch {
        // typeInfo(of:) only throws if the `Kind` enum isn't one of the supported cases:
        //  .struct, .class, .existential, .tuple, .enum, .optional.
        // Thus if it throws, we know for sure that it isn't a optional.
        return false
    }
}


/// Test whether a type is an enum
public func isEnum(_ type: Any.Type) -> Bool {
    do {
        let typeInfo = try Runtime.typeInfo(of: type)
        return typeInfo.kind == .enum
    } catch {
        return false
    }
}


/// Run a precondition check to make sure that a type is a struct
/// - parameter T: The type for which to assert that it is a struct
/// - parameter messagePrefix: An optional string which will be prefixed to the "T must be a struct" message
public func preconditionTypeIsStruct<T>(_: T.Type, messagePrefix: String? = nil) {
    guard let typeInfo = try? Runtime.typeInfo(of: T.self) else {
        fatalError("Unable to get type info for type '\(T.self)'")
    }
    precondition(typeInfo.kind == .struct, "\(messagePrefix.map { $0 + " " } ?? "")'\(typeInfo.name)' must be a struct")
}


/// Test whether a value is a `Sequence`
public func isSequence(_ value: Any) -> Bool {
    AnySequenceVisitor()(value) != nil
}


/// Test whether a value is a `Collection`
public func isCollection(_ value: Any) -> Bool {
    AnyCollectionVisitor()(value) != nil
}


// MARK: Utils

private protocol AnySequenceVisitorBase: AssociatedTypeRequirementsVisitor {
    associatedtype Visitor = AnySequenceVisitorBase
    associatedtype Input = Sequence
    associatedtype Output

    func callAsFunction<T: Sequence>(_ value: T) -> Output
}

private extension AnySequenceVisitorBase {
    @inline(never)
    @_optimize(none)
    func _test() {
        _ = self([1, 2, 3])
    }
}

private struct AnySequenceVisitor: AnySequenceVisitorBase {
    func callAsFunction<T: Sequence>(_ value: T) -> Void { // swiftlint:disable:this redundant_void_return
        ()
    }
}


private protocol AnyCollectionVisitorBase: AssociatedTypeRequirementsVisitor {
    associatedtype Visitor = AnyCollectionVisitorBase
    associatedtype Input = Collection
    associatedtype Output

    func callAsFunction<T: Collection>(_ value: T) -> Output
}

private extension AnyCollectionVisitorBase {
    @inline(never)
    @_optimize(none)
    func _test() {
        _ = self([1, 2, 3])
    }
}

private struct AnyCollectionVisitor: AnyCollectionVisitorBase {
    func callAsFunction<T: Collection>(_ value: T) -> Void { // swiftlint:disable:this redundant_void_return
        ()
    }
}
