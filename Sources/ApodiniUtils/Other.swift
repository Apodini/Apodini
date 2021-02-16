//
//  File.swift
//  
//
//  Created by Lukas Kollmer on 16.02.21.
//

import Foundation


public class Box<T> {
    public var value: T
    
    public init(_ value: T) {
        self.value = value
    }
}
