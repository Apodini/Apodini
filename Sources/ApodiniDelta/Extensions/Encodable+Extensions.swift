//
//  File.swift
//  
//
//  Created by Eldi Cano on 28.03.21.
//

import Foundation

extension Encodable {
    var json: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        let data = (try? encoder.encode(self)) ?? Data()
        return String(decoding: data, as: UTF8.self)
    }
}
