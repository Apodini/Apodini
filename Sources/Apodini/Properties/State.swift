//
//  State.swift
//  
//
//  Created by Max Obermeier on 13.01.21.
//

import ApodiniUtils

/// State can be used to maintain state across multiple evaluations of the same `Handler`..
/// This is especially helpful for `Handler`s which use `Connection` and do not instantly return
/// `Response.final(_)`.
/// - Note `State` has the same scope as the `Connection` available via `@Environment(\.connection)`
@propertyWrapper
public struct State<Element>: InstanceCodable, Property {
    internal var initializer: () -> Element
    
    private var storage: Box<Element>?
    
    /// Uses the given `Element` as the default value.
    public init(wrappedValue value: @escaping @autoclosure () -> Element) {
        self.initializer = value
    }
    
    public var wrappedValue: Element {
        get {
            guard let storage = storage else {
                fatalError("""
                    A State's wrappedValue was accessed before the State was activated.
                    Do not use the wrappedValue internally. Use the initializer instead.
                    """)
            }
            
            return storage.value
        }
        nonmutating set {
            guard let storage = storage else {
                fatalError("""
                    A State's wrappedValue was accessed before the State was activated.
                    Do not use the wrappedValue internally. Use the initializer instead.
                    """)
            }
            
            storage.value = newValue
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
protocol Activatable {
    /// Activates the given element.
    mutating func activate()
}

extension State: Activatable {
    mutating func activate() {
        self.storage = Box(self.initializer())
    }
}
