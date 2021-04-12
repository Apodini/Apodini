//
//  File.swift
//  
//
//  Created by Eldi Cano on 12.04.21.
//

import Foundation

public class Property {
    let parent: Property?
    let path: String
    let offset: Int
    let type: TypeWrapper
    var properties: [Property]
    
    var pathComponents: [String] {
        var paths: [String] = []
        
        var currentParent = parent
        while let parent = currentParent {
            paths.insert(parent.path, at: 0)
            currentParent = parent.parent
        }

        paths.append(path)
        return paths
    }
    
    var absolutePath: String {
        pathComponents.joined(separator: "/")
    }
    
    var depth: Int {
        pathComponents.count - 1
    }
    
    init(parent: Property? = nil, offset: Int, path: String, type: TypeWrapper, properties: [Property]) {
        self.parent = parent
        self.path = path
        self.type = type
        self.offset = offset
        self.properties = properties
    }
    
    convenience init(parent: Property? = nil, offset: Int, path: String, type: TypeWrapper) {
        self.init(parent: parent, offset: offset, path: path, type: type, properties: [])
    }
    
    func addProperty(_ property: Property) {
        properties.append(property)
    }
    
    func property(with pathComponents: [String]) -> Property? {
        if absolutePath == pathComponents.joined(separator: "/") {
            return self
        }
        
        for property in properties {
            if let property = property.property(with: pathComponents) {
                return property
            }
        }
        
        return nil
    }
}

extension Property: CustomDebugStringConvertible {
    public var debugDescription: String {
        let indentation = String(repeating: "  ", count: depth)
        var output = "\(indentation)Offset(\(offset)), Path(\(path)), Type(\(type.debugDescription))"
        properties.sorted { $0.offset < $1.offset }.forEach { output.append("\n\(indentation)\($0.debugDescription)") }
        return output
    }
}
