//
//  State.swift
//  
//
//  Created by Max Obermeier on 13.01.21.
//

// MIT License
//
// Copyright (c) 2019 Devran "Cosmo" Uenal
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

@propertyWrapper public struct State<Value>: Property {
    internal var initializer: () -> Value
    
    private var _location: AnyLocation<Value>?
    
    public init(wrappedValue value: @escaping @autoclosure () -> Value) {
        self.initializer = value
    }
    
    public var wrappedValue: Value {
        get {
            guard let location = _location else {
                fatalError("""
                    A State's wrappedValue was accessed before the State was activated.
                    Do not use the wrappedValue internally. Use the initializer instead.
                    """)
            }
            
            return location._value.pointee
        }
        nonmutating set {
            guard let location = _location else {
                fatalError("""
                    A State's wrappedValue was accessed before the State was activated.
                    Do not use the wrappedValue internally. Use the initializer instead.
                    """)
            }
            
            location._value.pointee = newValue
        }
    }
}

protocol Activatable {
    mutating func activate()
}

extension State: Activatable {
    mutating func activate() {
        self._location = AnyLocation(value: self.initializer())
    }
}

private class AnyLocation<Value> {
    internal let _value = UnsafeMutablePointer<Value>.allocate(capacity: 1)
    
    init(value: Value) {
        self._value.pointee = value
    }
}

extension State where Value: ExpressibleByNilLiteral {
    public init() {
        self.init(wrappedValue: nil)
    }
}
