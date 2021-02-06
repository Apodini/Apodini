//
//  Namespace.swift
//
//
//  Created by Lukas Kollmer on 2021-02-06.
//

import Foundation



public protocol OuterNamespace: class {
    static var id: String { get }
}

//extension OuterNamespace {
//    static var id: String { "\(Self.self)" }
//}


public protocol InnerNamespace: class {
    associatedtype OuterNS: OuterNamespace
    static var id: String { get }
}

//extension InnerNamespace {
//    static var id: String { "\(Self.self)" }
//}
