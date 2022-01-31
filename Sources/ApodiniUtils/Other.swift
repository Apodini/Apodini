//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import NIO


/// The `Box` type can be used to wrap an object in a class
public final class Box<T>: Hashable {
    /// The value stored by the `Box`
    public var value: T
    
    /// Creates a new box filled with the specified value, and,
    /// if `T` has reference semantics, establishing a strong reference to it.
    public init(_ value: T) {
        self.value = value
    }
    
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    public static func == (lhs: Box, rhs: Box) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}


/// The `Boxed` property wrapper can be used to wrap an object in a class
@propertyWrapper
public final class Boxed<T> {
    /// The value stored by the `Boxed` property wrapper
    public var wrappedValue: T
    
    /// Initializor of the property warpper
    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
}


/// A weak reference to an object of class type
public final class Weak<T: AnyObject> {
    /// The value stored by the `Box`
    public weak var value: T?
    
    /// Creates a new box filled with the specified value, establishing a weak reference.
    public init(_ value: T?) {
        self.value = value
    }
}


// MARK: Type-casting

/// Perform a dynamic cast from one type to another.
/// - returns: the casted value, or `nil` if the cast failed
/// - note: This is semantically equivalent to the `as?` operator.
///         The reason this function exists is to enable casting from `Any` to an optional type,
///         which is otherwise rejected by the type checker.
public func dynamicCast<U>(_ value: Any, to _: U.Type) -> U? {
    value as? U
}

/// Unsafely cast a value to a type.
/// - parameter value: The to-be-cast value
/// - parameter to: The to-be-casted-to type
/// - Note: This function will result in a fatal error if `value` cannot be cast to `T`.
///         Only use this function if you are fine with the program crashing as a result of the cast failing.
///         This function should only be used if you know *for a fact* that `value` is nonnil, and can be cast to `T`.
public func unsafelyCast<T>(_ value: Any, to _: T.Type) -> T {
    if let typed = value as? T {
        return typed
    } else {
        fatalError("Unable to cast value of type '\(type(of: value))' to type '\(T.self)'")
    }
}


/// The `DeferHandle` class can be used to tie an operation (e.g. some cleanup task) to the lifetime of an object.
/// The object in this case is the `DeferHandle` instance.
/// This is useful, for example, for returning handles (or tokens) which keep some state or association alive, and, when
/// the handle is deallicated, automatically de-register the underlying association.
public class DeferHandle {
    let action: () -> Void
    
    /// Creates a new defer handle.
    public init(_ action: @escaping () -> Void) {
        self.action = action
    }
    
    deinit {
        action()
    }
}


// MARK: NSRegularExpression and friends

extension NSRegularExpression {
    /// Matches the receiver against the full range of the specified string.
    public func matches(in string: String, options: MatchingOptions = []) -> [NSTextCheckingResult] {
        self.matches(
            in: string,
            options: options,
            range: NSRange(string.startIndex..<string.endIndex, in: string)
        )
    }
}


extension NSTextCheckingResult {
    /// Reads the contents of a capture group (specified by its index, keep in mind that 0 is the enire match) in the specified string.
    /// - Note: `string` should, obviously, be the string the pattern was matched against.
    public func contentsOfCaptureGroup(atIndex idx: Int, in string: String) -> String {
        precondition((0..<numberOfRanges).contains(idx), "Invalid capture group index")
        guard let range = Range(self.range(at: idx), in: string) else {
            fatalError("Unable to construct 'Range<String.Index>' from NSRange")
        }
        return String(string[range])
    }
}


extension UUID: LosslessStringConvertible {
    public init?(_ description: String) {
        self.init(uuidString: description)
    }
}


extension NSLocking {
    /// Requests the lock, then executes the specified closure, then relinquishes the lock, then returns the closure's result.
    public func withLock<Result>(_ block: () -> Result) -> Result {
        lock()
        defer { unlock() }
        return block()
    }
}


extension CharacterSet {
    /// Constructs a new `CharacterSet` by forming the union of the specified character sets.
    public static func joining(_ other: [CharacterSet]) -> CharacterSet {
        other.reduce(into: []) { $0.formUnion($1) }
    }
}


/// Assert that an implication holds
public func precondition(
    _ condition: @autoclosure () -> Bool,
    implies implication: @autoclosure () -> Bool,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) {
    precondition(!condition() || implication(), message(), file: file, line: line)
}


/// A type that can be initialised using a 0-arity iniitialiser
public protocol DefaultInitialisable {
    /// Create a new value
    init()
}

extension Int: DefaultInitialisable {}
extension UInt: DefaultInitialisable {}
extension Int8: DefaultInitialisable {}
extension Int16: DefaultInitialisable {}
extension Int32: DefaultInitialisable {}
extension Int64: DefaultInitialisable {}
extension UInt8: DefaultInitialisable {}
extension UInt16: DefaultInitialisable {}
extension UInt32: DefaultInitialisable {}
extension UInt64: DefaultInitialisable {}
extension Float: DefaultInitialisable {}
extension Double: DefaultInitialisable {}
extension String: DefaultInitialisable {}
extension Array: DefaultInitialisable {}
extension Set: DefaultInitialisable {}
extension Dictionary: DefaultInitialisable {}


/// :nodoc
public func getMemoryAddressAsHexString<T: AnyObject>(_ object: T?) -> String {
    switch object {
    case nil:
        return "0x0"
    case .some(let value):
        return Unmanaged.passUnretained(value).toOpaque().debugDescription
    }
}


/// A counter that counts integer values upwards.
public struct Counter<T: FixedWidthInteger> {
    private var nextValue: T
    
    /// Create a new Counter, optionally specifying the initial value, which otherwise defaults to `T.zero`
    public init(_ initialValue: T = .zero) {
        nextValue = initialValue
    }
    
    /// Get the next value.
    public mutating func get() -> T {
        defer { nextValue += 1 }
        return nextValue
    }
}


/// Checks whether the program was compiled as a debug build
public func isDebugBuild() -> Bool {
    #if DEBUG
    return true
    #else
    return false
    #endif
}

/// Checks whether the program was compiled as a release build
public func isReleaseBuild() -> Bool {
    !isDebugBuild()
}


/// An operating system
public enum OperatingSystem: Hashable {
    case macOS
    case linux
    case windows
    
    /// The current host operating system
    public static var current: OperatingSystem {
        #if os(macOS)
        return .macOS
        #elseif os(Linux)
        return .linux
        #elseif os(Windows)
        return .windows
        #else
        #error("Unsupported OS")
        #endif
    }
}


/// An architecture
public enum Architecture: Hashable {
    case arm64
    case x86_64 // swiftlint:disable:this identifier_name
    
    /// The current host architecture
    public static var current: Architecture {
        #if arch(arm64)
        return .arm64
        #elseif arch(x86_64)
        return .x86_64
        #else
        #error("Unsupported architecture")
        #endif
    }
}
