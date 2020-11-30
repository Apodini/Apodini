//
//  File.swift
//  
//
//  Created by Nityananda on 26.11.20.
//

// MARK: - Message

extension Message: CustomStringConvertible {
    var description: String {
        let properties = self.properties
            .sorted()
            .map { "\t\($0.description)" }
            .joined(separator: .newLine)
        
        let body = properties.isEmpty
            ? ""
            : properties.quote(.newLine)
        
        return "message \(name) {\(body)}"
    }
}

extension Message.Property: CustomStringConvertible {
    var description: String {
        "\(typeName) \(name) = \(uniqueNumber);"
    }
}

// MARK: - Service

extension Service.Method: CustomStringConvertible {
    var description: String {
        "rpc \(name) (\(input.name)) returns (\(ouput.name));"
    }
}

extension Service: CustomStringConvertible {
    var description: String {
        let methods = self.methods
            .map { "\t\($0.description)" }
            .joined(separator: .newLine)
        let body = methods.isEmpty
            ? ""
            : methods.quote(.newLine)
        
        return "service \(name) {\(body)}"
    }
}

// MARK: - String++

private extension String {
    static let newLine = "\n"
    
    func quote(_ string: String) -> String {
        string + self + string
    }
}
