//
//  File.swift
//  
//
//  Created by Nityananda on 26.11.20.
//

// MARK: - Message

extension GRPCMessage: CustomStringConvertible {
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

extension GRPCMessage.Property: CustomStringConvertible {
    var description: String {
        "\(typeName) \(name) = \(uniqueNumber);"
    }
}

// MARK: - Service

extension GRPCService.Method: CustomStringConvertible {
    var description: String {
        "rpc \(name) (\(input.name)) returns (\(ouput.name));"
    }
}

extension GRPCService: CustomStringConvertible {
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
