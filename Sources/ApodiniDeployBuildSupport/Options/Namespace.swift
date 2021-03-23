//
//  Namespace.swift
//
//
//  Created by Lukas Kollmer on 2021-02-06.
//


public protocol OuterNamespace: AnyObject {
    static var id: String { get }
}

public protocol InnerNamespace: AnyObject {
    associatedtype OuterNS: OuterNamespace
    static var id: String { get }
}
