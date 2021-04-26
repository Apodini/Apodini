//
//  File.swift
//  
//
//  Created by Eldi Cano on 22.03.21.
//

import Foundation

extension WebServiceStructure {
    func export(at path: String) {
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: path) {
            try? fileManager.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
        }

        let filename = "web_service_\(version?.description ?? "").json"
        let jsonFileURL = URL(fileURLWithPath: path).appendingPathComponent(filename)

        do {
            try json.write(to: jsonFileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Could not save \(error)")
        }
    }
}
