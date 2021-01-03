//
//  EmptyComponent.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO


/// A `Component` which does not contain any content
public struct EmptyComponent: Component, SyntaxTreeVisitable {
    /// `EmptyComponent` does not have any content.
    /// Accessing this property will result in a run-time crash.
    public var content: some Component {
        let imp = { () -> Self in
            fatalError("'\(Self.self)' does not implement the '\(#function)' property")
        }
        return imp()
    }
    
    func accept(_ visitor: SyntaxTreeVisitor) {}
}


public struct EmptyHandler: Handler, SyntaxTreeVisitable {
    public typealias Response = Never
    func accept(_ visitor: SyntaxTreeVisitor) {}
}

/// A custom `Never` type.
///
/// This is required to prevent the type system from using the `extension Component where Content == Never`
/// extension to deduce the `Content` type for empty component definitions.
/// The issue seems to be that, if we have a protocol structure like the following:
/// ```
/// protocol Req {}
/// protocol ValueProvider {
///     associatedtype Value: Req
///     func getValue() -> Value
/// }
///
/// extension Never: Req {}
///
/// extension ValueProvider where Value == Never {
///     func getValue() -> Never {
///         fatalError()
///     }
/// }
///
/// struct S: ValueProvider {
///     // intentionally empty
/// }
/// ```
/// Swift will deduce `S.Value` from the provided protocol extension.
/// NB: I have absolutely no idea why this is the case. Maybe it's a but and will get fixed in the future.
///
/// This behaviour (effectively giving the associatedtype a default, despite us explicitly not defining one)
/// is undesired from our point of view, since we want a `Component` struct definition which doesn't specify its `Content` type
/// (either explicitly via a typealias or implicitly via the `content` property's return type) to result in a compilation error.
///
/// Since apparently Swift looks at protocol extebsions to deduce default values for associatedtypes, we simply define a
/// second, functionally equivalent, extension with a different type.
/// The result is that, from Swift's point of view, both of these two extension's `Content` types are equally "valid" to
/// use as a component's `Content` type.
/// This means the compiler can't pick one over the other, which means that defining a component without a `Content` type
/// will result in a compilation error (which is exactly what we want).
/// It should be noted that all of this only applies to components which define neither a `Content` typealias nor a `content` property.
/// If a struct defines either of these two, that definition's type will take precedence over both extensions.
///
/// See also this post on the Swift forums: https://forums.swift.org/t/type-resolution-equality-rules-in-protocol-extensions-or-why-does-swift-give-my-associatedtype-a-default-value/43256
public enum _EmptyComponentCustomNeverImpl {} // swiftlint:disable:this type_name


// MARK: Component

extension Never: Component {
    public typealias Content = Never
    public var content: Self.Content {
        fatalError("'\(Self.self).\(#function)' is not implemented because 'Self.Content' is set to '\(Self.Content.self)'")
    }
}

extension Component where Content == Never {
    /// Default implementation which will simply crash
    public var content: Self.Content {
        fatalError("'\(Self.self).\(#function)' is not implemented because 'Self.Content' is set to '\(Self.Content.self)'")
    }
}


extension _EmptyComponentCustomNeverImpl: Component {
    public typealias Content = Never
    public var content: Self.Content {
        fatalError("'\(Self.self).\(#function)' is not implemented because 'Self.Content' is set to '\(Self.Content.self)'")
    }
}

extension Component where Content == _EmptyComponentCustomNeverImpl {
    /// Default implementation which will simply crash
    public var content: Self.Content {
        fatalError("'\(Self.self).\(#function)' is not implemented because 'Self.Content' is set to '\(Self.Content.self)'")
    }
}


// MARK: Handler

extension Never: Encodable {
    /// Default implementation which will simply crash
    public func encode(to encoder: Encoder) throws {
        fatalError("The '\(Self.self)' type cannot be encoded")
    }
}

extension Handler where Response == Never {
    /// Default implementation which will simply crash
    public func handle() -> Self.Response {
        fatalError("'\(Self.self).\(#function)' is not implemented because 'Self.Response' is set to '\(Self.Response.self)'")
    }
}


extension _EmptyComponentCustomNeverImpl: Encodable {
    /// Default implementation which will simply crash
    public func encode(to encoder: Encoder) throws {
        fatalError("The '\(Self.self)' type cannot be encoded")
    }
}

extension Handler where Response == _EmptyComponentCustomNeverImpl {
    /// Default implementation which will simply crash
    public func handle() -> Self.Response {
        fatalError("'\(Self.self).\(#function)' is not implemented because 'Self.Response' is set to '\(Self.Response.self)'")
    }
}
