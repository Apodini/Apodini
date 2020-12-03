//
//  File.swift
//  
//
//  Created by Nityananda on 03.12.20.
//

import Runtime

extension TypeInfo {
    var isArray: Bool {
        ParticularType(type).description == "Array"
    }
}
