//
//  Namespace.swift
//
//
//  Created by Lukas Kollmer on 2021-02-06.
//

import Foundation


public protocol OptionNamespace: class { // TODO -> OptionSubNamespace, add outer NS for better reuse
    static var id: String { get }
}
