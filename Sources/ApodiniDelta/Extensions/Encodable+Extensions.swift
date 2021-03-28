//
//  File.swift
//  
//
//  Created by Eldi Cano on 28.03.21.
//

import Foundation

extension Encodable {

    func jsonString() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        let data = try encoder.encode(self)
        return String(decoding: data, as: UTF8.self)
    }

    func printJSONString() {
        do {
            print(try jsonString())
        } catch {
            print(error)
        }
    }
}
