//
//  Empty+Equatable.swift
//  
//
//  Created by Paul Schmiedmayer on 7/8/21.
//


extension Empty: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        true
    }
}
