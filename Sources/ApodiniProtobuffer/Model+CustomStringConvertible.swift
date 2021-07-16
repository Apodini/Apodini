//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

extension ProtobufferMessage: CustomStringConvertible {
    var description: String {
        let properties = self.properties
            .sorted(by: \.uniqueNumber)
            .map { "  \($0.description)" }
            .joined(separator: .newLine)
        
        let body = properties.isEmpty
            ? ""
            : properties.quote(.newLine)
        
        return "message \(name) {\(body)}"
    }
}

extension ProtobufferMessage.Property: CustomStringConvertible {
    var description: String {
        let components: [CustomStringConvertible] = [
            fieldRule,
            typeName,
            name,
            "=",
            "\(uniqueNumber);"
        ]
        
        return components
            .map(\.description)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

extension ProtobufferMessage.Property.FieldRule: CustomStringConvertible {
    var description: String {
        switch self {
        case .optional:
            return "optional"
        case .required:
            return ""
        case .repeated:
            return "repeated"
        }
    }
}

// MARK: - Service

extension ProtobufferService.Method: CustomStringConvertible {
    var description: String {
        "rpc \(name) (\(input.name)) returns (\(ouput.name));"
    }
}

extension ProtobufferService: CustomStringConvertible {
    var description: String {
        let methods = self.methods
            .map { "  \($0.description)" }
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
