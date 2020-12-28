//
//  File.swift
//
//
//  Created by Alexander Collins on 27.12.20.
//

@propertyWrapper
public struct State<Value> {
    private var value: Value
    private var pointer: UnsafeMutablePointer<Value>?
    
    public init(wrappedValue value: Value) {
        self.value = value
        self.pointer = allocate()
    }

    public var wrappedValue: Value {
        get { pointer?.pointee ?? value }
        nonmutating set { pointer?.pointee = newValue }
    }
    
    private func allocate() -> UnsafeMutablePointer<Value> {
        let pointer = UnsafeMutablePointer<Value>.allocate(capacity: 1)
        pointer.pointee = value
        
        return pointer
    }
    
    internal func deallocate() {
        pointer?.deallocate()
    }
}
