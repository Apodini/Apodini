//
//  File.swift
//  
//
//  Created by Eldi Cano on 28.03.21.
//

import Foundation

extension Encodable {
    func jsonString(with outputFormatting: JSONEncoder.OutputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = outputFormatting
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
