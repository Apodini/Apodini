//
//  ThreadSafeVariable.swift
//  
//
//  Created by Lukas Kollmer on 2021-04-26.
//

import Foundation
import Dispatch


/// A thread-safe object wrapper.
/// Note: I have no idea if this is a good implementation, works property, or even makes sense.
/// There was an issue where accessing the `Task.taskPool` static variable from w/in the atexit
/// handler would fail but only sometimes (for some reason the atexit handler was being invoked
/// off the main thread). Adding this fixed the issue.
public class ThreadSafeVariable<T> {
    private var value: T
    private let queue: DispatchQueue
    
    /// Creates a new `ThreadSafeVariable`
    public init(_ value: T) {
        self.value = value
        self.queue = DispatchQueue(label: "Apodini.ThreadSafeVariable", attributes: .concurrent)
    }
    
    
    /// Access the value stored by the wrapper.
    public func read(_ block: (T) throws -> Void) rethrows {
        try queue.sync {
            try block(value)
        }
    }
    
    
    /// Access and modify the value stored by the wrapper.
    public func write(_ block: (inout T) throws -> Void) rethrows {
        try queue.sync(flags: .barrier) {
            try block(&value)
        }
    }
}
