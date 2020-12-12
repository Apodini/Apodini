//
//  Coder.swift
//  
//
//  Created by Tim Gymnich on 2.12.20.
//

import Foundation


struct AnyEncodable: Encodable {
    private let encodable: Encodable

    init(_ encodable: Encodable) {
        self.encodable = encodable
    }

    func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}
