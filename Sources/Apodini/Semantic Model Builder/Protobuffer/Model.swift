//
//  Created by Nityananda on 24.11.20.
//

// MARK: - Message

struct ProtobufferMessage: Equatable, Hashable {
    struct Property: Equatable, Hashable {
        enum FieldRule {
            case optional
            case required
            case repeated
        }
        
        let fieldRule: FieldRule
        let name: String
        let typeName: String
        let uniqueNumber: Int
    }
    
    let name: String
    let properties: Set<Property>
}

// MARK: - Service

struct ProtobufferService: Equatable, Hashable {
    struct Method: Equatable, Hashable {
        let name: String
        let input: ProtobufferMessage
        let ouput: ProtobufferMessage
    }
    
    let name: String
    let methods: Set<Method>
}
