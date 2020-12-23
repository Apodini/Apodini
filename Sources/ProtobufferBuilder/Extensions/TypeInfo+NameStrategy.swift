//
//  File.swift
//  
//
//  Created by Nityananda on 03.12.20.
//

@_implementationOnly import Runtime

extension TypeInfo {
    func compatibleName() throws -> String {
        let type = ParticularType(self.type)
        
        if type.isPrimitive {
            return type.description.lowercased()
        } else {
            let result: String
            
            switch kind {
            case .struct, .class:
                result = try compatibleGenericName()
            case .tuple:
                result = try tupleName()
            default:
                throw ProtobufferBuilderError(message: "Kind: \(kind) is not supported")
            }
            
            return result
        }
    }
}

private extension TypeInfo {
    func compatibleGenericName() throws -> String {
        return String(describing: type)
            .replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: "<", with: "Of")
            .replacingOccurrences(of: ", ", with: "And")
    }

    func tupleName() throws -> String {
        if type == Void.self {
            return "Void"
        } else {
            throw ProtobufferBuilderError(message: "Tuple: \(type) is not supported")
        }
    }
}
