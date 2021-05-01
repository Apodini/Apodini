import Foundation
@_implementationOnly import Runtime

enum MangledName: Equatable {
    case dictionary
    case array
    case optional
    case other(String)
    
    init(_ type: Any.Type) {
        let mangledName: String
        do {
            mangledName = try Runtime.typeInfo(of: type).mangledName
        } catch {
            mangledName = String(describing: type)
        }
        switch mangledName {
        case "Optional": self = .optional
        case "Dictionary": self = .dictionary
        case "Array": self = .array
        case let other: self = .other(other)
        }
    }
}
