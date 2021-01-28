//
//  State.swift
//  
//
//  Created by Max Obermeier on 13.01.21.
//

import Foundation

/// State can be used to maintain state across multiple evaluations of the same `Handler`..
/// This is especially helpful for `Handler`s which use `Connection` and do not instantly return
/// `Response.final(_)`.
/// - Note `State` has the same scope as the `Connection` available via `@Environment(\.connection)`
@propertyWrapper
public struct State<Element>: Property {
    internal var initializer: () -> Element
    
    private var wrapper: Wrapper<Element>?
    
    /// Uses the given `Element` as the default value.
    public init(wrappedValue value: @escaping @autoclosure () -> Element) {
        self.initializer = value
    }
    
    public var wrappedValue: Element {
        get {
            guard let wrapper = wrapper else {
                fatalError("""
                    A State's wrappedValue was accessed before the State was activated.
                    Do not use the wrappedValue internally. Use the initializer instead.
                    """)
            }
            
            return wrapper.value
        }
        nonmutating set {
            guard let wrapper = wrapper else {
                fatalError("""
                    A State's wrappedValue was accessed before the State was activated.
                    Do not use the wrappedValue internally. Use the initializer instead.
                    """)
            }
            
            wrapper.value = newValue
        }
    }
}

extension State where Element: ExpressibleByNilLiteral {
    /// A convenience initializer that uses `nil` as the initial value.
    public init() {
        self.init(wrappedValue: nil)
    }
}

/// An `Activatable` element may allocate resources when `activate` is called. These
/// resources may share information with any copies made from this element after `activate`
/// was called.
public protocol Activatable {
    /// Activates the given element.
    mutating func activate()
}

extension State: Activatable {
    public mutating func activate() {
        self.wrapper = Wrapper(value: self.initializer())
    }
}

class Wrapper<Value> {
    var value: Value
    
    init(value: Value) {
        self.value = value
    }
}
