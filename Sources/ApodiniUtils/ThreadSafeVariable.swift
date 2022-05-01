//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Dispatch


/// A thread-safe object wrapper.
/// Note: I have no idea if this is a good implementation, works property, or even makes sense.
/// There was an issue where accessing the `ChildProcess.taskPool` static variable from w/in the atexit
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
    public func read<Result>(_ block: (T) throws -> Result) rethrows -> Result {
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
