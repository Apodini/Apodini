import Apodini
import ApodiniTypeInformation
import Runtime
import Foundation





// MARK: Protocols and shit

/// Protocol indicating that the type is not nested, but rather directly embdeded into its parent type
protocol LKProtobufferEmbeddedOneofType {}




protocol LKAnyProtobufferMessageCodingKeys: Swift.CodingKey {
    static var allCases: [Self] { get }
}

protocol LKProtobufferMessageCodingKeys: LKAnyProtobufferMessageCodingKeys & CaseIterable {}



protocol LKAnyProtobufferCodableWithCustomFieldMapping {
    static func getCodingKeysType() -> LKAnyProtobufferMessageCodingKeys.Type
}

protocol LKProtobufferCodableWithCustomFieldMapping: LKAnyProtobufferCodableWithCustomFieldMapping {
    associatedtype CodingKeys: RawRepresentable & CaseIterable & LKAnyProtobufferMessageCodingKeys where Self.CodingKeys.RawValue == Int
}

extension LKProtobufferCodableWithCustomFieldMapping {
    static func getCodingKeysType() -> LKAnyProtobufferMessageCodingKeys.Type {
        CodingKeys.self
    }
}


protocol LKIgnoreInReflection {}


protocol __Proto_TypeInNamespace {
    static var namespace: String { get }
}

protocol __Proto_TypeWithCustomProtoName {
    static var protoTypeName: String { get }
}

protocol __ProtoNS_Google_Protobuf: __Proto_TypeInNamespace {}
extension __ProtoNS_Google_Protobuf {
    static var namespace: String { "google.protobuf" }
}

protocol __ProtoNS_GRPC_Reflection_V1Alpha: __Proto_TypeInNamespace {}
extension __ProtoNS_GRPC_Reflection_V1Alpha {
    static var namespace: String { "grpc.reflection.v1alpha" }
}


//protocol __LKProtobufferCodableBase {
//    associatedtype CodingKeys: RawRepresentable & LKProtobufferMessageCodingKeys & CaseIterable where Self.CodingKeys.RawValue == Int
//}
//
//protocol LKProtobufferEncodable: Encodable & __LKProtobufferCodableBase {}
//protocol LKProtobufferDecodable: Decodable & __LKProtobufferCodableBase {}
//typealias LKProtobufferCodable = LKProtobufferEncodable & LKProtobufferDecodable



protocol LKProtobufferMessage {}
typealias LKProtobufferMessageWithCustomFieldMapping = LKProtobufferMessage & LKProtobufferCodableWithCustomFieldMapping


//extension LKProtobufferMessage where Self: LKProtobufferEncodable {
//    static func getCodingKeysType() -> LKProtobufferMessageCodingKeys.Type {
//        Self.CodingKeys.self
//    }
//}
//
//extension LKProtobufferMessage where Self: LKProtobufferDecodable {
//    static func getCodingKeysType() -> LKProtobufferMessageCodingKeys.Type {
//        Self.CodingKeys.self
//    }
//}


/// A type which can become a primitive field in a protobuffer message
protocol LKProtobufferPrimitive {}

extension Bool: LKProtobufferPrimitive {}
extension Int: LKProtobufferPrimitive {}
extension String: LKProtobufferPrimitive {}
extension Int64: LKProtobufferPrimitive {}
extension UInt64: LKProtobufferPrimitive {}
extension Int32: LKProtobufferPrimitive {}
extension UInt32: LKProtobufferPrimitive {}
extension Float: LKProtobufferPrimitive {}
extension Double: LKProtobufferPrimitive {}
// TODO add some more






//struct LKProtobufferReservedEnumRange {
//    /// Inclusive
//    let start: Int32
//    /// Inclusive
//    let end: Int32
//}



protocol LKAnyProtobufferEnum {

//protocol LKProtobufferEnum { //}: RawRepresentable where RawValue == Int32 {
    static var allCases: [Self] { get }
    var rawValue: Int32 { get }
    static var reservedRanges: Set<ClosedRange<Int32>> { get }
    static var reservedNames: Set<String> { get }
}


protocol LKProtobufferEnum: LKAnyProtobufferEnum, Codable, CaseIterable, RawRepresentable where RawValue == Int32 {}

extension LKProtobufferEnum {
    static var reservedRanges: Set<ClosedRange<Int32>> { [] }
    static var reservedNames: Set<String> { [] }
}



// MARK: The type handling stuff




struct LKEmptyMessage: Codable, LKProtobufferMessage {}



protocol AnyGRPCv2ScalarWrappingMessage: Codable, LKProtobufferMessage {
    init(value: Any)
}


struct GRPCv2ScalarWrappingMessage<T: Codable>: Codable, LKProtobufferMessage {
    let value: T
    
    enum CodingKeys: Int, CodingKey {
        case value = 1
    }
}



// Used to unify the typename handling for messages and enums
private protocol __LKProtoTypeDescriptorProtocol {
    var name: String { get set }
}
extension DescriptorProto: __LKProtoTypeDescriptorProtocol {}
extension EnumDescriptorProto: __LKProtoTypeDescriptorProtocol {}

//enum GRPCv2HandlerParamsProtobufferMessageType {
//    /// google.protobuf.Empty
//    case builtinEmptyType
//    case messageType(LKProtobufferMessage.Type)
//    case compositeMessageType([String: Any]) // TODO make this indirect and map onto the enum?
//}


enum ProtoTypeDerivedFromSwift: Hashable { // TODO this name sucks ass
    struct MessageField: Hashable {
        let name: String
        let fieldNumber: Int
        let type: ProtoTypeDerivedFromSwift
        let isRepeated: Bool
        let containingOneof: LKAnyProtobufferEnumWithAssociatedValues.Type?
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(name)
            hasher.combine(fieldNumber)
            hasher.combine(type)
            hasher.combine(isRepeated)
            hasher.combine(containingOneof.map(ObjectIdentifier.init))
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.name == rhs.name
                && lhs.fieldNumber == rhs.fieldNumber
                && lhs.type == rhs.type
                && lhs.isRepeated == rhs.isRepeated
                && lhs.containingOneof.map(ObjectIdentifier.init) == rhs.containingOneof.map(ObjectIdentifier.init)
        }
    }
    
    struct EnumCase: Hashable {
        let name: String
        let value: Int32
    }
    
    struct OneofType: Hashable {
        let name: String
        let underlyingType: LKAnyProtobufferEnumWithAssociatedValues.Type
        /// The fields belonging to this oneof. Note that the field numbers here are w/in the context of the type containing a oneof field definition (ie the struct where one of the struct's properties is of a oneof type)
        let fields: [MessageField]
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(name)
            hasher.combine(ObjectIdentifier(underlyingType))
            hasher.combine(fields)
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.name == rhs.name
                && ObjectIdentifier(lhs.underlyingType) == ObjectIdentifier(rhs.underlyingType)
                && lhs.fields == rhs.fields
        }
    }
    
    struct Typename: Hashable {
        let packageName: String
        let typename: String
        var mangled: String {
            "[\(packageName)].\(typename)"
        }
        var fullyQualified: String {
            ".\(packageName).\(typename)" // TODO do we want the initial period here?
        }
        init(packageName: String, typename: String) {
            // TODO use a regex here!!!
            precondition(!packageName.hasPrefix("."))
            precondition(!typename.hasPrefix("."))
            self.packageName = packageName
            self.typename = typename
        }
        init(mangled string: String) {
            precondition(string.hasPrefix("["))
            let packageEndIdx = string.firstIndex(of: "]")!
            //self.packageName = String(string[string.index(after: string.startIndex)..<packageEndIdx])
            //self.typename = String(string[string.index(after: packageEndIdx)...])
            self.init(
                packageName: String(string[string.index(after: string.startIndex)..<packageEndIdx]),
                typename: String(string[string.index(after: string.index(after: packageEndIdx))...])
            )
            precondition(mangled == self.mangled)
        }
    }
    
    /// A type which is a protobuffer primitive, such as Strings, Ints, Doubles, etc
    case primitive(LKProtobufferPrimitive.Type) // TOdO set the type to LKProtoPrimitive.Type
    /// `google.protobuf.Empty`
    case builtinEmptyType
    //case bytes // TODO or just model this as .primitive([UInt8].self)?
//    /// A type which is already a protobuffer message type in its own right.
//    case messageType(name: String, underlying: Any.Type)
    //case wrappingPrimitive(name: String, LKProtobufferPrimitive.Type) // TODO!!!!
    //indirect case compositeMessage(name: String, underlying: Any.Type?, fields: [String: ProtoTypeDerivedFromSwift]) // TOdO rename to just message?
    indirect case compositeMessage(name: Typename, underlyingType: Any.Type?, nestedOneofTypes: [OneofType], fields: [MessageField]) // TOdO rename to just message?
    case enumTy(name: Typename, enumType: LKAnyProtobufferEnum.Type, cases: [EnumCase]) // TODO set the type to LKProtoEnum or whatever its called!
    
    case refdMessageType(Typename) // A message type which is referenced by its (fully qualified, TODO!!!) name only. Used to break recursion when dealing with recursive types.
    
    static var bytes: Self { .primitive([UInt8].self) }
    
    func hash(into hasher: inout Hasher) {
        // TODO this hashable conformance is broken, insofar as `hash(a) == hash(b) =/=> a == b` (which should ideally hold)
        switch self {
        case .primitive(let type):
            hasher.combine(0)
            hasher.combine(ObjectIdentifier(type))
        case .builtinEmptyType:
            hasher.combine(1)
        case let .compositeMessage(name, underlyingType, nestedOneofTypes, fields):
            hasher.combine(2)
            hasher.combine(name)
            hasher.combine(underlyingType.map(ObjectIdentifier.init))
            hasher.combine(nestedOneofTypes)
            hasher.combine(fields)
        case let .enumTy(name, enumType, cases):
            hasher.combine(3)
            hasher.combine(name)
            hasher.combine(ObjectIdentifier(enumType))
            hasher.combine(cases)
        case .refdMessageType(let name):
            hasher.combine(4)
            hasher.combine(name)
        }
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.isEqual(to: rhs, onlyCheckSemanticEquivalence: true)
    }
    
    /// - parameter onlyCheckSemanticEquivalence: whether the equality checking should be relaxed to return true if two objects are structurally different, but semantically equivalent. (e.g.: comparing a message type ref to a message type with the same name)
    func isEqual(to other: Self, onlyCheckSemanticEquivalence: Bool) -> Bool {
        switch (self, other) {
        case (.primitive(let lhsTy), .primitive(let rhsTy)):
            return ObjectIdentifier(lhsTy) == ObjectIdentifier(rhsTy)
        case (.builtinEmptyType, .builtinEmptyType):
            return true
        case let (.compositeMessage(lhsName, lhsUnderlying, lhsNestedOneofs, lhsFields), .compositeMessage(rhsName, rhsUnderlying, rhsNestedOneofs, rhsFields)):
            return lhsName == rhsName
                && lhsUnderlying.map(ObjectIdentifier.init) == rhsUnderlying.map(ObjectIdentifier.init)
                && lhsNestedOneofs == rhsNestedOneofs
                && lhsFields == rhsFields
        case let (.enumTy(lhsName, lhsEnumType, lhsCases), .enumTy(rhsName, rhsEnumType, rhsCases)):
            return lhsName == rhsName && ObjectIdentifier(lhsEnumType) == ObjectIdentifier(rhsEnumType) && lhsCases == rhsCases
        case let (.refdMessageType(lhsName), .refdMessageType(rhsName)):
            return lhsName == rhsName
        case let (.refdMessageType(lhsName), .compositeMessage(rhsName, _, _, _)):
            return onlyCheckSemanticEquivalence && lhsName == rhsName
        case let (.compositeMessage(lhsName, _, _, _), .refdMessageType(rhsName)):
            return onlyCheckSemanticEquivalence && lhsName == rhsName
        default:
            return false
        }
    }
    
    var fullyQualifiedTypename: String {
        switch self {
        case .builtinEmptyType:
            return GRPCv2InterfaceExporter.EmptyTypeFullyQualifiedTypeName
        case .primitive(let type):
            switch LKGetProtoFieldType(type) {
            case .TYPE_DOUBLE:
                return "double"
            case .TYPE_FLOAT:
                return "float"
            case .TYPE_INT64:
                return "int64"
            case .TYPE_UINT64:
                return "uint64"
            case .TYPE_INT32:
                return "uint32"
            case .TYPE_FIXED32, .TYPE_FIXED64, .TYPE_SFIXED32, .TYPE_SFIXED64:
                fatalError("Not supported")
            case .TYPE_BOOL:
                return "bool"
            case .TYPE_STRING:
                return "string"
            case .TYPE_GROUP:
                fatalError()
            case .TYPE_MESSAGE, .TYPE_ENUM:
                fatalError("Should've ended up in one of the other beanches in the outer switch")
            case .TYPE_BYTES:
                return "bytes"
            case .TYPE_UINT32:
                return "uint32"
            case .TYPE_SINT32:
                fatalError("TODO?")
            case .TYPE_SINT64:
                fatalError("TODO?")
            }
        case .refdMessageType(let typename):
            return typename.fullyQualified
        case .compositeMessage(let typename, underlyingType: _, nestedOneofTypes: _, fields: _):
            return typename.fullyQualified
        case .enumTy(let typename, enumType: _, cases: _):
            return typename.fullyQualified
        }
    }
}




struct Counter {
    private var nextValue: Int
    
    init(_ initialValue: Int = 0) {
        nextValue = initialValue
    }
    
    mutating func get() -> Int {
        defer { nextValue += 1 }
        return nextValue
    }
}



//struct TypenameInfo {
//    let fullyQualifiedTypename: String
//    let moduleName: String
//    let simpleTypename: String
//    let nameWithoutModule: String
//
//    init(_ type: Any.Type) {
//        let fullTypename = String(reflecting: type)
//        fullyQualifiedTypename = fullTypename
//        let components = fullTypename
//            .components(separatedBy: ".")
//            .filter { !$0.hasPrefix("(unknown context at") }
//        precondition(!components.contains { $0.hasPrefix("(unknown context at") })
//        moduleName = components.first!
//        simpleTypename = components.last!
//        nameWithoutModule = components.count > 1 ? components.dropFirst().joined(separator: ".") : components[0]
//    }
//}

//struct TypenameInfo {
//    let fullyQualifiedTypename: String
//    let moduleName: String
//    let simpleTypename: String
//    //let nameWithoutModule: String
//
//    init(_ type: Any.Type) {
//        let fullTypename = String(reflecting: type)
//        let components = fullTypename
//            .components(separatedBy: ".")
//            .filter { !$0.hasPrefix("(unknown context at") }
//        if let protonNamespaceType = type as? __Proto_TypeInNamespace.Type {
//            fullyQualifiedTypename = "[\(protonNamespaceType.namespace)].\(components.dropFirst().joined(separator: "."))"
//        } else {
//            fullyQualifiedTypename = fullTypename
//        }
//        moduleName = components.first!
//        simpleTypename = components.last!
//        //nameWithoutModule = components.count > 1 ? components.dropFirst().joined(separator: ".") : components[0]
//    }
//}


class GRPCv2SchemaManager {
    func getTypename(_ type: Any.Type) -> ProtoTypeDerivedFromSwift.Typename {
        let typenameComponents = String(reflecting: type)
            .components(separatedBy: ".")
            .filter { !$0.hasPrefix("(unknown context at") }
        return ProtoTypeDerivedFromSwift.Typename(
            packageName: { () -> String in
                if let namespacedTy = type as? __Proto_TypeInNamespace.Type {
                    return namespacedTy.namespace
                } else {
                    return self.defaultPackageName
                }
            }(),
            //typename: typenameComponents.dropFirst().joined(separator: ".")
            typename: {
                var components = Array(typenameComponents.dropFirst())
                precondition(!components.isEmpty)
                if let typeWithCustomTypenameTy = type as? __Proto_TypeWithCustomProtoName.Type {
                    components[components.endIndex - 1] = typeWithCustomTypenameTy.protoTypeName
                }
                return components.joined(separator: ".")
            }()
        )
    }
    
//    private static var hardcodedTypenamePrefixes: [ObjectIdentifier: String] = [
//        //ObjectIdentifier(FileDescriptorProto.self): "grpc.reflection.v1alpha"
//    ]
    // Key: Handler type
    private var endpointMessageMappings: [ObjectIdentifier: EndpointProtoMessageTypes] = [:]
    private var messageTypesTypenameCounter = Counter()
    private var enumTypesTypenameCounter = Counter()
    
    /// the package name used for types which don't explicitly specify their own package.
    private let defaultPackageName: String
    
    private(set) var isFinalized = false
    
    private(set) var allMessageTypes: [ProtoTypeDerivedFromSwift.Typename: ProtoTypeDerivedFromSwift] = [:]
    private(set) var allEnumTypes: [ProtoTypeDerivedFromSwift.Typename: ProtoTypeDerivedFromSwift] = [:]
    
    //private(set) var finalisedTopLevelMessageTypes: [DescriptorProto] = []
    //private(set) var finalisedTopLevelEnumTypes: [EnumDescriptorProto] = []
    
    private var finalizedTopLevelMessageTypesByPackage: [String: [DescriptorProto]] = [:]
    private var finalizedTopLevelEnumTypesByPackage: [String: [EnumDescriptorProto]] = [:]
    
    private(set) var fileDescriptors: [FileDescriptorProto] = []
    
    
    init(defaultPackageName: String) {
        self.defaultPackageName = defaultPackageName
    }
    
    
    func messageTypeDescriptors(forPackage packageName: String) -> [DescriptorProto] {
        precondition(isFinalized, "Cannot access message type descriptors: Schema not yet finalized")
        return finalizedTopLevelMessageTypesByPackage[packageName] ?? []
    }
    
    func enumTypeDescriptors(forPackage packageName: String) -> [EnumDescriptorProto] {
        precondition(isFinalized, "Cannot access enum type descriptors: Schema not yet finalized")
        return finalizedTopLevelEnumTypesByPackage[packageName] ?? []
    }
    
    
    private func makeUniqueMessageTypename() -> String {
        return "LK_Message\(messageTypesTypenameCounter.get())"
    }
    
    private func makeUniqueEnumTypename() -> String {
        return "LK_Enum\(enumTypesTypenameCounter.get())"
    }
    
    
    struct EndpointProtoMessageTypes {
        let input: ProtoTypeDerivedFromSwift
        let output: ProtoTypeDerivedFromSwift
    }
    
    
    // TODO rename to registerEndpointTypes or informAboutEndpoint or smth like that
    func endpointProtoMessageTypes<H: Handler>(
        for endpoint: Endpoint<H>,
        endpointContext: GRPCv2EndpointContext
    ) throws -> EndpointProtoMessageTypes {
        precondition(!isFinalized, "Cannot add type to already finalized schema")
        if let types = endpointMessageMappings[ObjectIdentifier(H.self)] {
            return types
        } else {
            let types = EndpointProtoMessageTypes(
                input: collectTypes(in: try parametersMessageType(for: endpoint, endpointContext: endpointContext)),
                output: collectTypes(in: try responseMessageType(for: endpoint, endpointContext: endpointContext))
            )
            endpointMessageMappings[ObjectIdentifier(H.self)] = types
            return types
        }
    }
    
    
    func parametersMessageType<H: Handler>(
        for endpoint: Endpoint<H>,
        endpointContext: GRPCv2EndpointContext
    ) throws -> ProtoTypeDerivedFromSwift {
        precondition(!isFinalized, "Cannot add type to already finalized schema")
        let parameters = endpoint.parameters
        if parameters.count == 0 {
            // If there are no parameters, we map to the empty message type.
            //return .builtinEmptyType
            return protoType(for: LKEmptyMessage.self, requireTopLevelCompatibleOutput: true)
        } else if parameters.count == 1 {
            let param = parameters[0]
            print("param.type:", param.propertyType)
            print("asMessage:", (param.propertyType as? LKProtobufferMessage.Type))
            // If there's only one parameter, and that parameter is a ProtobufferMessage, we can simply use that directly as the rpc's input.
//            if let protobufMessageType = param.propertyType as? LKProtobufferMessage.Type {
//                precondition(!param.nilIsValidValue) // TODO handleOptionals
//                return .messageType(protobufMessageType)
//            }
            //return try wrapSingleType(param.propertyType)
            
            return protoType(
                for: param.propertyType,
                requireTopLevelCompatibleOutput: true,
                singleParamHandlingContext: .init(
                    paramName: param.name,
                    wrappingMessageTypename: .init(packageName: defaultPackageName, typename: "\(H.self)___Input"), // TODO +"Request"?
                    endpointContext: endpointContext
                )
            )
            
//            return protoType(
//                for: param.propertyType,
//                   requireTopLevelCompatibleOutput: true,
//                   //singleParamHandlingContext: (paramName: String, wrappingMessageTypename: ProtoTypeDerivedFromSwift.Typename, decodingCtx: GRPCv2EndpointParameterDecodingContext)?)
//                   singleParamHandlingContext: .init(
//                    paramName: <#T##String#>,
//                    wrappingMessageTypename: <#T##ProtoTypeDerivedFromSwift.Typename#>,
//                    decodingContext: <#T##GRPCv2EndpointParameterDecodingContext#>
//                   )
        } else {
            // The handler has multiple parameters, so we have to combine them into a protobuf message type
            return combineIntoCompoundMessageType(
                //typename: "\(H.self)Input",
                typename: .init(packageName: defaultPackageName, typename: "\(H.self)___Input"),
                underlyingType: nil,
                elements: parameters.map { ($0.name, $0.propertyType) } // TODO handle nil values here!!! The `propertyType` has optionals stripped!!!
            )
//            return .compositeMessage(
//                name: makeUniqueMessageTypename(),
//                underlying: nil,
//                fields: parameters.enumerated().map { (idx, param) -> ProtoTypeDerivedFromSwift.MessageField in
//                    precondition(!param.nilIsValidValue) // TODO properly handle optional types!!!
//                    return .init(name: param.name, fieldNumber: idx + 1, type: protoType(for: <#T##Any.Type#>, allowPrimitiveOutput: <#T##Bool#>), isRepeated: <#T##Bool#>)
//                }
//                fields: .init(uniqueKeysWithValues: parameters.map { param -> (String, ProtoTypeDerivedFromSwift) in
//                    precondition(!param.nilIsValidValue)
//                    //return (param.name, try wrapSingleType(param.propertyType)) // TODO properly handle optional types!!!
//                    return (param.name, protoType(for: param.propertyType, allowPrimitiveOutput: true))
//                })
//            )
//            return .compositeMessageType(.init(uniqueKeysWithValues: parameters.map { param -> (String, Any) in
//                precondition(!param.nilIsValidValue)
//                return (param.name, param.propertyType)
//            }))
        }
    }
    
    
    func responseMessageType<H: Handler>(for endpoint: Endpoint<H>, endpointContext: GRPCv2EndpointContext) throws -> ProtoTypeDerivedFromSwift {
        precondition(!isFinalized, "Cannot add type to already finalized schema")
        //return try wrapSingleType(H.Response.Content.self as! Codable.Type)
        print(H.self, "\(H.self)", String(describing: H.self), String(reflecting: H.self), String(reflecting: H.Response.Content.self))
        let endpointResponseType = protoType(
            for: H.Response.Content.self,
            requireTopLevelCompatibleOutput: true,
               singleParamHandlingContext: .init(
                paramName: "value",
                wrappingMessageTypename: .init(packageName: defaultPackageName, typename: "\(H.self)___Response"),
                endpointContext: endpointContext
            )
        )
        endpointContext.endpointResponseType = endpointResponseType
        return endpointResponseType
//        let type = try TypeInformation(type: H.Response.Content.self)
//        print(H.Response.Content.self)
//        print(type)
//        print("isScalar: \(type.isScalar)")
//        print("context: \(type.context)")
//        precondition(!type.isOptional)
//        if type.isScalar {
//        }
//        for (idx, param) in endpoint.parameters.enumerated() {
//            print("[\(idx)]: \(param)")
//        }
//        fatalError()
    }
    
    
    @discardableResult
    private func collectTypes(in protoType: ProtoTypeDerivedFromSwift) -> ProtoTypeDerivedFromSwift {
        precondition(!isFinalized, "Cannot add type to already finalized schema")
        let setMapping = { (dst: inout [ProtoTypeDerivedFromSwift.Typename: ProtoTypeDerivedFromSwift], name: ProtoTypeDerivedFromSwift.Typename) in
            if let oldValue = dst[name] {
                precondition(oldValue.isEqual(to: protoType, onlyCheckSemanticEquivalence: false))
            }
            dst[name] = protoType
        }
        
        switch protoType {
        case .builtinEmptyType:
            break
        case .primitive:
            break
        case let .compositeMessage(name, underlyingType: _, nestedOneofTypes: _, fields):
            setMapping(&allMessageTypes, name)
            for field in fields {
                collectTypes(in: field.type)
            }
        case .enumTy(let name, enumType: _, cases: _):
            setMapping(&allEnumTypes, name)
        case .refdMessageType:
            break
        }
        return protoType
    }
    
    
    @discardableResult
    func informAboutMessageType(_ type: LKProtobufferMessage.Type) -> ProtoTypeDerivedFromSwift {
        precondition(!isFinalized, "Cannot add type to already finalized schema")
        let result = protoType(for: type, requireTopLevelCompatibleOutput: false)
        collectTypes(in: result)
        return result
    }
    
    
    private func combineIntoCompoundMessageType(
        typename: ProtoTypeDerivedFromSwift.Typename,
        underlyingType: Any.Type?,
        elements: [(String, Any.Type)],
        endpointContext: GRPCv2EndpointContext? = nil
    ) -> ProtoTypeDerivedFromSwift {
//        let allElements: [(String, Any.Type)] = elements.flatMap { (name, type) in
//            if let assocEnumTy = type as? LKAnyProtobufferEnumWithAssociatedValues.Type {
//            } else {
//                return [(name, type)]
//            }
//        }
        
        let underlyingTypeFieldNumbersMapping: [String: Int]? = {
            guard let messageTy = underlyingType as? LKAnyProtobufferCodableWithCustomFieldMapping.Type else {
                return nil
            }
            return .init(uniqueKeysWithValues: messageTy.getCodingKeysType().allCases.map { ($0.stringValue, $0.intValue!) })
        }()
        
        let (allElements, nestedOneofTypes) = elements.enumerated().reduce(
            into: ([], []) as (Set<ProtoTypeDerivedFromSwift.MessageField>, Set<ProtoTypeDerivedFromSwift.OneofType>)
        ) { (partialResult, arg0) in
            //let (idx, field) = arg0
            //let (fieldName, fieldType) = field
            let (idx, (fieldName, fieldType)) = arg0
            let newFields: [ProtoTypeDerivedFromSwift.MessageField]
            if let assocEnumTy = fieldType as? LKAnyProtobufferEnumWithAssociatedValues.Type {
                // TODO do something w/ the fieldNAme in here? in proto, the oneofs do have names, although i'm not sure where they get used, if at all...
                let TI = try! typeInfo(of: assocEnumTy)
                precondition(TI.kind == .enum)
                let fieldNumbersByFieldName: [String: Int] = .init(uniqueKeysWithValues: assocEnumTy.getCodingKeysType().allCases.map {
                    ($0.stringValue, $0.intValue!)
                })
                newFields = TI.cases.map { enumCase in
                    precondition((enumCase.payloadType as? __LKProtobufRepeatedValueCodable.Type) == nil)
                    return ProtoTypeDerivedFromSwift.MessageField.init(
                        name: enumCase.name,
                        fieldNumber: fieldNumbersByFieldName[enumCase.name]!,
                        type: protoType(for: enumCase.payloadType!, requireTopLevelCompatibleOutput: false), // TODO add support for cases w/out a payload? ideally wed just add some dummy value that subsequently gets ignored. would need to support that in the en/decoders as well, though. probably easier to simply require the user define that unused value (eg what the reflection API does...)
                        isRepeated: false, // not supported (TODO check that that's actually true!)
                        containingOneof: assocEnumTy
                    )
                }
                precondition(partialResult.1.insert(ProtoTypeDerivedFromSwift.OneofType(
                    //name: ".\(TypenameInfo(assocEnumTy).nameWithoutModule)",
                    //name: ".\(TypenameInfo(assocEnumTy).fullyQualifiedTypename)",
                    name: getTypename(assocEnumTy).typename, // TODO is this the correct property to use here?
                    underlyingType: assocEnumTy,
                    fields: newFields
                )).inserted)
                // The insertion check here is to ensure that a type contains at most one property of a given enum w/ assoc values.
                // This is the limit since we'd otherwise have duplicate field numbers.
            } else {
                // The field's type is not an enum w/ associated values, meaning that the field simply gets turned into one field in the resulting message.
                newFields = [.init(
                    name: fieldName,
                    fieldNumber: { () -> Int in
                        if let fieldNumbersMapping = underlyingTypeFieldNumbersMapping {
                            return fieldNumbersMapping[fieldName]!
                        } else {
                            return idx + 1
                        }
                    }(),
                    type: { () -> ProtoTypeDerivedFromSwift in
                        if let repeatedType = fieldType as? __LKProtobufRepeatedValueCodable.Type, (fieldType as? __LKProtobufferBytesMappedType.Type) == nil {
                            return protoType(for: repeatedType.elementType, requireTopLevelCompatibleOutput: false)
                        } else {
                            return protoType(for: fieldType, requireTopLevelCompatibleOutput: false)
                        }
                    }(),
                    isRepeated: (fieldType as? __LKProtobufRepeatedValueCodable.Type) != nil,
                    containingOneof: nil
                )]
            }
            for field in newFields {
                precondition(partialResult.0.insert(field).inserted, "Duplicate fields in message!") // TODO better error here!
            }
        }
        
        if let endpointContext = endpointContext {
            for messageField in allElements {
                endpointContext.addMapping(fromParamName: messageField.name, toFieldNumber: messageField.fieldNumber)
            }
        }
        
        return .compositeMessage(
            name: typename,
            underlyingType: underlyingType,
            nestedOneofTypes: Array(nestedOneofTypes),
            fields: Array(allElements)
        )
        
        
//        let codingKeysTy = enumTy.getCodingKeysType()
//        let fieldNumbersByFieldName: [String: Int] = .init(uniqueKeysWithValues: codingKeysTy.allCases.map {
//            ($0.stringValue, $0.intValue!)
//        })
//        return cacheRetval(.oneof(name: typenameWithoutModule, underlyingType: enumTy, fields: TI.cases.map { enumCase in
//            precondition((enumCase.payloadType as? __LKProtobufRepeatedValueCodable.Type) == nil)
//            return ProtoTypeDerivedFromSwift.MessageField(
//                name: enumCase.name,
//                fieldNumber: fieldNumbersByFieldName[enumCase.name]!,
//                type: protoType(for: enumCase.payloadType!, requireTopLevelCompatibleOutput: false),
//                isRepeated: false // TODO is repetition inside a oneof allowed?
//            )
//        }))
//
//        return .compositeMessage(
//            name: typename,
//            underlyingType: underlyingType,
//            nestedOneofTypes: <#T##Set<ProtoTypeDerivedFromSwift.OneofType>#>,
//            fields: <#T##[ProtoTypeDerivedFromSwift.MessageField]#>
//        )
//
//        return .compositeMessage(name: typename, underlying: underlying, fields: elements.enumerated().map { (idx, element) in
//            let (name, type) = element
//            return .init(
//                name: name,
//                fieldNumber: idx + 1,
//                //type: protoType(for: type, allowPrimitiveOutput: true),
//                type: { () -> ProtoTypeDerivedFromSwift in
//                    if let repeatedType = type as? __LKProtobufRepeatedValueCodable.Type, (type as? __LKProtobufferBytesMappedType.Type) == nil {
//                        return protoType(for: repeatedType.elementType, requireTopLevelCompatibleOutput: false)
//                    } else {
//                        return protoType(for: type, requireTopLevelCompatibleOutput: false)
//                    }
//                }(),
//                isRepeated: (type as? __LKProtobufRepeatedValueCodable.Type) != nil
//            )
//        })
    }
    
    
    
//    func getFullTypename(_ type: Any.Type) -> String {
//        String(reflecting: type)
//    }
//
//    func getTypenameWithoutModule(_ type: Any.Type) -> String {
//        String(getFullTypename(type).drop(while: { $0 != "." }))
//    }
    
    
    
    
    private struct CachedProtoTypeResult: Hashable {
        let type: Any.Type
        let requireTopLevelCompatibleOutput: Bool
        let primitiveTypeHandlingContext: SingleParamHandlingContext?
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(ObjectIdentifier(type))
            hasher.combine(requireTopLevelCompatibleOutput)
            hasher.combine(primitiveTypeHandlingContext)
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            return ObjectIdentifier(lhs.type) == ObjectIdentifier(rhs.type)
                && lhs.requireTopLevelCompatibleOutput == rhs.requireTopLevelCompatibleOutput
                && lhs.primitiveTypeHandlingContext == rhs.primitiveTypeHandlingContext
        }
    }
    
    private var cachedResults: [CachedProtoTypeResult: ProtoTypeDerivedFromSwift] = [:]
    private var currentTypesStack: Stack<CachedProtoTypeResult> = []
    
    
    /// Helper type which provides context used when mapping a primitive type into a message type
    private struct SingleParamHandlingContext: Hashable {
        let paramName: String
        let wrappingMessageTypename: ProtoTypeDerivedFromSwift.Typename
        let endpointContext: GRPCv2EndpointContext
    }
    
    /// Returns a proto type representing the Swift type `type` in a proto definition.
    /// - parameter requireTopLevelCompatibleOutput: whether the function is required to produce types that are value "top-level" types in protobuf (i.e. messages or enums).
    ///         If set to true, types which can not be used as top-level types (e.g. primitive types, oneofs, etc) will be wrapped in a wrapper message type
    private func protoType(
        for type: Any.Type,
        requireTopLevelCompatibleOutput: Bool,
        //singleParamHandlingContext: (paramName: String, wrappingMessageTypename: ProtoTypeDerivedFromSwift.Typename, decodingCtx: GRPCv2EndpointParameterDecodingContext)? = nil
        singleParamHandlingContext: SingleParamHandlingContext? = nil
            //paramDecodingContext: GRPCv2EndpointParameterDecodingContext? = nil
    ) -> ProtoTypeDerivedFromSwift {
//        let fullTypename = String(reflecting: type) // `String(reflecting:)` returns fullly qualified typenames for nested types, which `String(describing:)` does not...
//        let moduleName = String(fullTypename.prefix(while: { $0 != "." }))
//        guard moduleName != "Builtin" else {
//            fatalError("Descended too far into the type hierarchy and reached one of the Builtin types: '\(type)'")
//        }
//        let typenameWithoutModule = String(fullTypename.drop(while: { $0 != "." }))
//        //let typenameWithoutModule = String(fullTypename.dropFirst(moduleName.count + 1))
////        print(fullTypename, moduleName, typenameWithoutModule)
////        fatalError()
        
        let typename = getTypename(type)
        
        let cacheKey = CachedProtoTypeResult( // TODO rename (both the variable as well as the  type!)
            type: type,
            requireTopLevelCompatibleOutput: requireTopLevelCompatibleOutput,
            primitiveTypeHandlingContext: singleParamHandlingContext
        )
        
        if currentTypesStack.contains(cacheKey) {
            precondition(LKGetProtoCodingKind(type) == .message)
            //return .refdMessageType(".\(typenameInfo.nameWithoutModule)")
            //return .refdMessageType(".\(typenameInfo.fullyQualifiedTypename)")
            return .refdMessageType(typename)
        }
        currentTypesStack.push(cacheKey)
        defer {
            currentTypesStack.pop()
        }
        
        if currentTypesStack.count == 100 {
            print("\n\n\n")
            for ty in currentTypesStack {
                print("- \(String(reflecting: ty))")
            }
            fatalError()
        }
        
        if let cached = cachedResults[cacheKey] {
            return cached
        }
        
        
        func cacheRetval(_ retval: ProtoTypeDerivedFromSwift) -> ProtoTypeDerivedFromSwift {
            cachedResults[cacheKey] = retval
            return retval
        }
        
        //precondition(!isFinalized, "Cannot add type to already finalized schema")
        if let optionalTy = type as? AnyOptional.Type {
            return protoType(for: optionalTy.wrappedType, requireTopLevelCompatibleOutput: requireTopLevelCompatibleOutput)
        } else if type == Never.self {
            //return cacheRetval(.builtinEmptyType)
            return protoType(for: LKEmptyMessage.self, requireTopLevelCompatibleOutput: requireTopLevelCompatibleOutput)
        } else if type == Array<UInt8>.self || type == Data.self {
            if requireTopLevelCompatibleOutput {
                fatalError("TODO!")
            } else {
                return cacheRetval(.bytes)
            }
        } else if type == LKEmptyMessage.self {
            // TODO we might need special handling here, insofar as we want probably want one definition of the empty type per package...
            return cacheRetval(.compositeMessage(name: typename, underlyingType: LKEmptyMessage.self, nestedOneofTypes: [], fields: []))
        }
        
//        if fullTypename.contains("MessageResponse") {
//            fatalError()
//        }
        
        let TI = try! typeInfo(of: type)
        let protoCodingKind = LKGetProtoCodingKind(type)
        
        switch protoCodingKind {
        case nil:
            fatalError()
        case .message:
            //print("\(type), name: \(TI.name), mangledName: \(TI.mangledName)")
            switch TI.kind {
            case .struct:
//                if let repeatedType = type as? __LKProtobufRepeatedValueCodable.Type {
//                    fatalError("TODO handle Array<\(repeatedType.elementType)>!!!")
//                }
                switch TI.properties.count {
                case 0:
                    //return cacheRetval(.builtinEmptyType)
                    return protoType(for: LKEmptyMessage.self, requireTopLevelCompatibleOutput: requireTopLevelCompatibleOutput)
                default:
//                    return .compositeMessage(
//                        name: messageName,
//                        underlying: type,
//                        fields: .init(uniqueKeysWithValues: TI.properties.map { property -> (String, ProtoTypeDerivedFromSwift) in
//                            return (property.name, protoType(for: property.type, allowPrimitiveOutput: true))
//                        })
//                    )
                    return cacheRetval(combineIntoCompoundMessageType(
                        //typename: ".\(typenameInfo.nameWithoutModule)",
                        //typename: ".\(typenameInfo.fullyQualifiedTypename)",
                        typename: typename,
                        underlyingType: type,
                        elements: TI.properties.map { ($0.name, $0.type) }
                    ))
                }
            case .class:
                fatalError("TODO: \(TI)")
            default:
                fatalError("Unsupported type: \(TI.kind)")
            }
//            let TI = try! TypeInformation(type: type)
//            switch TI {
//            case let .object(typeName, properties, context):
//                print(typeName, "\(type)", context)
//                return .compositeMessage(name: typeName.name, fields: .init(uniqueKeysWithValues: properties.map { prop in
//                }))
//                fatalError()
//            case .optional(wrappedValue: let wrapped):
//                fatalError("\(wrapped)")
//            case let .enum(name, rawValueType, cases, context):
//                fatalError("\(TI)")
//            case .scalar, .dictionary, .repeated, .reference:
//                fatalError("unreachable?")
//            }
            //return .messageType(type as! LKProtobufferMessage.Type)
        case .primitive:
            guard let primitiveTy = type as? LKProtobufferPrimitive.Type else {
                fatalError()
            }
            if !requireTopLevelCompatibleOutput {
                return cacheRetval(.primitive(primitiveTy))
            } else {
                // TODO a) reuse message types?
                // b) derive the type name from the nesting (i.e. encode the ?
                if let singleParamHandlingContext = singleParamHandlingContext {
                    return cacheRetval(combineIntoCompoundMessageType(
                        typename: singleParamHandlingContext.wrappingMessageTypename,
                        underlyingType: nil,
                        elements: [(singleParamHandlingContext.paramName, primitiveTy)],
                        endpointContext: singleParamHandlingContext.endpointContext
                    ))
                } else {
                    fatalError("TODO do we ever end up here???")
                    return cacheRetval(combineIntoCompoundMessageType(
                        typename: .init(packageName: defaultPackageName, typename: "\(makeUniqueMessageTypename())"), // TODO come up w/ better method names!
                        underlyingType: nil,
                        elements: [("value", primitiveTy)],
                        endpointContext: nil
                    ))
                }
//                return cacheRetval(combineIntoCompoundMessageType(
//                    typename: .init(packageName: defaultPackageName, typename: "\(makeUniqueMessageTypename())"), // TODO come up w/ better method names!
//                    underlyingType: nil,
//                    elements: [("value", primitiveTy)],
//                    paramDecodingContext: paramDecodingContext
//                ))
//                return cacheRetval(.compositeMessage(
//                    //name: ".\(makeUniqueMessageTypename())",
//                    name: .init(packageName: defaultPackageName, typename: "\(makeUniqueMessageTypename())"), // TODO come up w/ better method names!
//                    underlyingType: nil /*<<<TODO!!!*/,
//                    nestedOneofTypes: [],
//                    fields: [
//                        .init(name: "value", fieldNumber: 1, type: .primitive(primitiveTy), isRepeated: false, containingOneof: nil)
//                    ]
//                ))
            }
        case .enum:
            if let enumTy = type as? LKAnyProtobufferEnum.Type {
                precondition(TI.cases.count == enumTy.allCases.count)
                let enumCases: [ProtoTypeDerivedFromSwift.EnumCase] = zip(TI.cases, enumTy.allCases).map {
                    //print(String(reflecting: $0.1))
                    precondition($0.0.name == String(String(reflecting: $0.1).split(separator: ".").last!))
                    return .init(name: $0.0.name, value: $0.1.rawValue)
                }
                //return cacheRetval(.enumTy(name: ".\(typenameInfo.nameWithoutModule)", enumType: type, cases: enumCases))
                //return cacheRetval(.enumTy(name: ".\(typenameInfo.fullyQualifiedTypename)", enumType: type, cases: enumCases))
                if requireTopLevelCompatibleOutput {
                    fatalError()
                } else {
                    return cacheRetval(.enumTy(name: typename, enumType: enumTy, cases: enumCases))
                }
            } else if let enumTy = type as? LKAnyProtobufferEnumWithAssociatedValues.Type {
                fatalError() // shouldn't end up here anymore since enums w/ assoc values are handled as part of processing a message's fields into a composite.
//                let codingKeysTy = enumTy.getCodingKeysType()
//                let fieldNumbersByFieldName: [String: Int] = .init(uniqueKeysWithValues: codingKeysTy.allCases.map {
//                    ($0.stringValue, $0.intValue!)
//                })
//                return cacheRetval(.oneof(name: typenameWithoutModule, underlyingType: enumTy, fields: TI.cases.map { enumCase in
//                    precondition((enumCase.payloadType as? __LKProtobufRepeatedValueCodable.Type) == nil)
//                    return ProtoTypeDerivedFromSwift.MessageField(
//                        name: enumCase.name,
//                        fieldNumber: fieldNumbersByFieldName[enumCase.name]!,
//                        type: protoType(for: enumCase.payloadType!, requireTopLevelCompatibleOutput: false),
//                        isRepeated: false // TODO is repetition inside a oneof allowed?
//                    )
//                }))
            }
            fatalError()
        }
//        if let messageType = type as? LKProtobufferMessage.Type {
//            return .messageType(messageType)
//        } else if let protobufferPrimitiveType = type as? LKProtobufferPrimitive.Type {
//            return .wrappingPrimitive(protobufferPrimitiveType)
//        } else if let TI = try? typeInfo(of: type) {
//            switch TI.kind {
//            case .struct:
//                if TI.properties.isEmpty {
//                    return .builtinEmptyType
//                } else {
//                    // It's a struct. IT's non-empty. We have to somehow handle this.
//                    print(type)
//                    fatalError()
//                }
//            case .enum:
//                // TODO. this one is indeed a bit tricky bc we have to a) handle the enum, and b) also introduce a enum type into the proto thing
//                // ALSO, we have to make sure that the enum uses int raw values. Can we access these? We might need to require the enum be CaseIterable. Which would break enums w/ assoc values... fuck fuck fuck fuck fuck fuck fuck fuck fuck fuck fuck fuck fuck fuck fuck fuck fuck fuck fuck fuck fuck fuck
//                fatalError() // TODO
//            default:
//                fatalError("TI kind \(TI.kind) is not supported (atm)")
//            }
//        } else {
//            // fuck
//            fatalError("TODO???")
//        }
    }
}



protocol AnyOptional {
    static var wrappedType: Any.Type { get }
}

extension Optional: AnyOptional {
    static var wrappedType: Any.Type { Wrapped.self }
}



extension GRPCv2SchemaManager {
    /// Seals the schema, i.e. not allowing any further types to be added, and resolves the types that have been added so far into a proto descriptor
    func finalize() {
        guard !isFinalized else {
            return
        }
        isFinalized = true
        processTypes()
    }
    
    private func processTypes() {
        precondition(isFinalized, "Cannot process types of non-finalized schema")
        
        // We start out by making every type a top-level type
        // Firstly, we process enums, since these are the simplest types (enums can't contain other types, they are a simple key-value mapping)
        var topLevelEnumTypeDescs = allEnumTypes.values.compactMap { protoType -> EnumDescriptorProto? in
            switch protoType {
            case .primitive, .builtinEmptyType, .compositeMessage, .refdMessageType:
                fatalError()
            case let .enumTy(typename, enumType, cases):
                guard (enumType as? LKIgnoreInReflection.Type) == nil else {
                    return nil
                }
                return EnumDescriptorProto(
                    name: typename.mangled, // We keep the full typename since we need that for the type containment checks...
                    //values: <#T##[EnumValueDescriptorProto]#>,
                    values: { () -> [EnumValueDescriptorProto] in
                        cases.map { enumCase -> EnumValueDescriptorProto in
                            EnumValueDescriptorProto(
                                name: enumCase.name,
                                number: enumCase.value,
                                options: nil//<#T##EnumValueOptions?#> // TODO we could use this to mark enum cases as deprecated, although there's no way of reading e.g. a swift @deprecatd annotation, so that's probably not overly useful...
                            )
                        }
                    }(),
                    options: nil, // <#T##EnumOptions?#>,
                    //reservedRanges: <#T##[EnumDescriptorProto.EnumReservedRange]#>,
                    reservedRanges: { () -> [EnumDescriptorProto.EnumReservedRange] in
                        if let protoEnumTy = enumType as? LKAnyProtobufferEnum.Type {
                            return protoEnumTy.reservedRanges.map { .init(start: $0.lowerBound, end: $0.upperBound) }
                        } else {
                            return []
                        }
                    }(),
                    reservedNames: { () -> [String] in
                        if let protoEnumTy = enumType as? LKAnyProtobufferEnum.Type {
                            return Array(protoEnumTy.reservedNames)
                        } else {
                            return []
                        }
                    }()
                )
            }
        }
        
        // Next, we process message types. Again, we first map them all into the global namespace, ignoring any potential nesting
        // This step will already take care of nested enums, which will be moved out of the top-level namespace and put into their respective parent message types.
        var topLevelMessageTypeDescs = allMessageTypes.values.compactMap {
            mapMessageType($0, topLevelEnumTypes: &topLevelEnumTypeDescs)
        }
        
        // Next, we have to go through the message types and determine which of them are top-level types, and which are not.
        // For types which are not top-level types, we move them into their parent type.
        do { // lmao all of this is so fucking inefficient
            var potentiallyNestedTypes = Stack(topLevelMessageTypeDescs
                .filter { m1 in topLevelMessageTypeDescs.contains { m2 in
                    m1.name.count > m2.name.count && m1.name.hasPrefix(m2.name)
                }}
                .sorted { lhs, rhs in
                    let lhsNestingDepth = lhs.name.count { $0 == "." }
                    let rhsNestingDepth = rhs.name.count { $0 == "." }
                    return rhsNestingDepth > lhsNestingDepth
                })
            
            while let typeDesc = potentiallyNestedTypes.pop() {
                // Check whether the type is in fact nested.
                // If yes, move it into its parent type (TODO do we need to adjust the typename?) and remove it from the list of top-level types.
                //let unnestedTypename = getLastTypenameComponent(typeDesc.name!)
                let expectedParentName = getParentTypename(typeDesc.name)!
                guard let containingTypeIdx = topLevelMessageTypeDescs.firstIndex(where: { $0.name == expectedParentName }) else {
                    continue
                }
                // We add it into its containing type, with the typename adjusted accordingly
                topLevelMessageTypeDescs[containingTypeIdx].nestedTypes.append(DescriptorProto(
                    name: String(typeDesc.name.split(separator: ".").last!),
                    fields: typeDesc.fields,
                    extensions: typeDesc.extensions,
                    nestedTypes: typeDesc.nestedTypes,
                    enumTypes: typeDesc.enumTypes,
                    extensionRanges: typeDesc.extensionRanges,
                    oneofDecls: typeDesc.oneofDecls,
                    options: typeDesc.options,
                    reservedRanges: typeDesc.reservedRanges,
                    reservedNames: typeDesc.reservedNames
                ))
                // And then remove the nested type from the list of top-level types
                topLevelMessageTypeDescs.removeFirstOccurrence(of: typeDesc)
            }
        }
        
        
        self.finalizedTopLevelEnumTypesByPackage = .init(grouping: topLevelEnumTypeDescs) { enumType in
            ProtoTypeDerivedFromSwift.Typename(mangled: enumType.name).packageName
        }.mapValues { enumTypeDescs -> [EnumDescriptorProto] in
            enumTypeDescs.map { enumTypeDesc -> EnumDescriptorProto in
                let retval = EnumDescriptorProto(
                    name: ProtoTypeDerivedFromSwift.Typename(mangled: enumTypeDesc.name).typename,
                    values: enumTypeDesc.values,
                    options: enumTypeDesc.options,
                    reservedRanges: enumTypeDesc.reservedRanges,
                    reservedNames: enumTypeDesc.reservedNames
                )
                print(enumTypeDesc.name)
                print(retval.name)
                fatalError() // TODO check this and make sure its correct!!!
                return retval
            }
        }
        
        self.finalizedTopLevelMessageTypesByPackage = .init(grouping: topLevelMessageTypeDescs) { msgType in
            ProtoTypeDerivedFromSwift.Typename(mangled: msgType.name).packageName
        }.mapValues { msgTypeDescs -> [DescriptorProto] in
            msgTypeDescs.map { msgTypeDesc -> DescriptorProto in
                var msgTypeDesc = msgTypeDesc
                print("old: \(msgTypeDesc.name)")
                let newName = ProtoTypeDerivedFromSwift.Typename(mangled: msgTypeDesc.name).typename
                print("new: \(newName)")
                precondition(newName.rangeOfCharacter(from: CharacterSet(charactersIn: ".[]")) == nil)
                msgTypeDesc.name = newName
                return msgTypeDesc
            }
        }
        
//        func handleTopLevelTypes<T: __LKProtoTypeDescriptorProtocol>(_ array: inout [T]) {
//            array.mapInPlace { typeDesc in
//                let name = typeDesc.name
//                let nameComponents = name.split(separator: ".")
//                precondition(name.hasPrefix(".") && nameComponents.count == 1 && nameComponents[0] == name.dropFirst())
//                typeDesc.name = String(nameComponents[0])
//            }
//            array.sort(by: \.name)
//        }
//
//        handleTopLevelTypes(&finalisedTopLevelEnumTypes)
//        handleTopLevelTypes(&finalisedTopLevelMessageTypes)
    }
    
    
//    private func getPAckageName(_ string: String) -> String {
//        let endIdx = string.firstIndex(of: "]")!
//        let packageName = string[string.index(after: string.startIndex)..<endIdx]
//        return String(packageName)
//    }
    
    
    private func getParentTypename(_ typename: String) -> String? {
        precondition(typename.hasPrefix("["))
        let components = typename.split(separator: ".")
        if components.count == 1 {
            return nil
        } else {
            return "\(components.dropLast().joined(separator: "."))"
        }
    }
    
    private func getParentTypename(_ typename: ProtoTypeDerivedFromSwift.Typename) -> ProtoTypeDerivedFromSwift.Typename? {
        let typenameWithoutPackage = typename.typename
        let components = typenameWithoutPackage.split(separator: ".")
        if components.count == 1 {
            return nil
        } else {
            return .init(packageName: typename.packageName, typename: components.dropLast().joined(separator: "."))
        }
    }
    
//    private func getLastTypenameComponent(_ typename: String) -> String {
//        return String(typename.split(separator: ".").last!)
//    }
    
    
    private func mapMessageType(_ protoType: ProtoTypeDerivedFromSwift, topLevelEnumTypes: inout [EnumDescriptorProto]) -> DescriptorProto? {
        switch protoType {
        case .builtinEmptyType:
            fatalError()
        case .primitive:
            fatalError()
        case .enumTy:
            fatalError()
        case .refdMessageType:
            fatalError() // Shouldn't be a problem since this function only gets called for top-level types. riiiight?
        case let .compositeMessage(messageTypename, underlyingType, nestedOneofTypes, fields):
            guard (underlyingType as? LKIgnoreInReflection.Type) == nil else {
                return nil
            }
            let fieldNumbersMapping: [String: Int]
            if let protoCodableWithCodingKeysTy = underlyingType as? LKAnyProtobufferCodableWithCustomFieldMapping.Type {
                let codingKeys = protoCodableWithCodingKeysTy.getCodingKeysType().allCases
                fieldNumbersMapping = .init(uniqueKeysWithValues: codingKeys.map { ($0.stringValue, $0.intValue!) }) // intentionally not using the getProtoFieldNumber thing here bc we want the user to define int values (and, in fact, require it so the force unwrap shouldn't be a problem anyway)
            } else {
                //fieldNumbersMapping = .init(uniqueKeysWithValues: fields.enumerated().map { ($0.element.key, $0.offset) })
                fieldNumbersMapping = .init(uniqueKeysWithValues: fields.map { ($0.name, $0.fieldNumber) })
            }
            return DescriptorProto(
                name: messageTypename.mangled, // Same as with enums, we intentionally keep the full name so that the type containment handling works correctly.
                //fields: <#T##[FieldDescriptorProto]#>,
                fields: fields.map { field -> FieldDescriptorProto in
                    FieldDescriptorProto(
                        name: field.name,
                        number: Int32(fieldNumbersMapping[field.name]!),
                        //label: nil, // <#T##FieldDescriptorProto.Label?#> optional/repeated/required
                        label: { () -> FieldDescriptorProto.Label? in
                            // TODO this is where we need to detect arrays and turn them into a repeated field! (and also we probably should adjust the name, although that shouldn't be happening here but rather in the type napper.
                            if field.isRepeated {
                                return .LABEL_REPEATED
                            } else {
                                return nil
                            }
                        }(),
                        //type: <#T##FieldDescriptorProto.FieldType?#>,
                        type: { () -> FieldDescriptorProto.FieldType? in
                            switch field.type {
                            case .builtinEmptyType:
                                return .TYPE_MESSAGE
                            case .primitive(let type):
                                return LKGetProtoFieldType(type)
                            case .compositeMessage, .refdMessageType:
                                return .TYPE_MESSAGE
                            case .enumTy:
                                return .TYPE_ENUM
                            }
                        }(),
                        typename: { () -> String? in
                            // For message and enum types, this is the name of the type.  If the name
                            // starts with a '.', it is fully-qualified.  Otherwise, C++-like scoping
                            // rules are used to find the type (i.e. first the nested types within this
                            // message are searched, then within the parent, on up to the root
                            // namespace).
                            switch field.type {
                            case .primitive:
                                return nil
                            case .builtinEmptyType:
                                return GRPCv2InterfaceExporter.EmptyTypeFullyQualifiedTypeName
                            case .compositeMessage(let typename, _, _, _), .enumTy(let typename, _, _), .refdMessageType(let typename):
                                return typename.fullyQualified
                            }
                        }(),
                        extendee: nil, //<#T##String?#>,
                        defaultValue: nil, //<#T##String?#>,
                        oneofIndex: { () -> Int32? in
                            // If set, gives the index of a oneof in the containing type's oneof_decl
                            // list.  This field is a member of that oneof.
                            if let containingOneofTy = field.containingOneof {
                                return Int32(nestedOneofTypes.firstIndex { ObjectIdentifier($0.underlyingType) == ObjectIdentifier(containingOneofTy) }!)
                            } else {
                                return nil
                            }
                        }(),
                        jsonName: { () -> String? in
                            // JSON name of this field. The value is set by protocol compiler. If the
                            // user has set a "json_name" option on this field, that option's value
                            // will be used. Otherwise, it's deduced from the field's name by converting
                            // it to camelCase.
                            return nil // TODO is this something we want? Probably not.
                        }(),
                        options: { () -> FieldOptions? in
                            return nil // TODO?
//                                FieldOptions(
//                                    ctype: <#T##FieldOptions.CType?#>,
//                                    // The packed option can be enabled for repeated primitive fields to enable
//                                    // a more efficient representation on the wire. Rather than repeatedly
//                                    // writing the tag and type for each element, the entire array is encoded as
//                                    // a single length-delimited blob. In proto3, only explicit setting it to
//                                    // false will avoid using packed encoding.
//                                    packed: <#T##Bool?#>,
//                                    jsType: <#T##FieldOptions.JSType?#>,
//                                    lazy: <#T##Bool?#>,
//                                    deprecated: <#T##Bool?#>,
//                                    weak: <#T##Bool?#>,
//                                    uninterpretedOptions: <#T##[UninterpretedOption]#>
//                                )
                        }(),
                        // If true, this is a proto3 "optional". When a proto3 field is optional, it
                        // tracks presence regardless of field type.
                        //
                        // When proto3_optional is true, this field must be belong to a oneof to
                        // signal to old proto3 clients that presence is tracked for this field. This
                        // oneof is known as a "synthetic" oneof, and this field must be its sole
                        // member (each proto3 optional field gets its own synthetic oneof). Synthetic
                        // oneofs exist in the descriptor only, and do not generate any API. Synthetic
                        // oneofs must be ordered after all "real" oneofs.
                        //
                        // For message fields, proto3_optional doesn't create any semantic change,
                        // since non-repeated message fields always track presence. However it still
                        // indicates the semantic detail of whether the user wrote "optional" or not.
                        // This can be useful for round-tripping the .proto file. For consistency we
                        // give message fields a synthetic oneof also, even though it is not required
                        // to track presence. This is especially important because the parser can't
                        // tell if a field is a message or an enum, so it must always create a
                        // synthetic oneof.
                        //
                        // Proto2 optional fields do not set this flag, because they already indicate
                        // optional with `LABEL_OPTIONAL`.
                        proto3Optional: false
                    )
                },
                extensions: [], //<#T##[FieldDescriptorProto]#>,
                nestedTypes: [], // <#T##[DescriptorProto]#>, // TODO!!!!
                //enumTypes: [], //<#T##[EnumDescriptorProto]#>,
                enumTypes: { () -> [EnumDescriptorProto] in
                    // All enum types nested in this message.
                    // Other than nested messages, this is actually simple to obtain (because we first process enums, meaning that by the time we end up here, we already have all enums processed.
                    // Also, enums can't reference messages so we don't have to take anything else into account here.
//                    let nestedEnums = finalisedTopLevelEnumTypes.filter { $0.name.hasSuffix(name) }
//                    finalisedTopLevelEnumTypes.subtract(nestedEnums)
//                    return nestedEnums.map { enumTypeDesc -> EnumDescriptorProto in
//                        EnumDescriptorProto(
//                            name: <#T##String#>,
//                            values: <#T##[EnumValueDescriptorProto]#>,
//                            options: <#T##EnumOptions?#>,
//                            reservedRanges: <#T##[EnumDescriptorProto.EnumReservedRange]#>,
//                            reservedNames: <#T##[String]#>
//                        )
//                    }
                    let nestedEnumTypes = topLevelEnumTypes.filter { enumTypeDesc in
                        if messageTypename.mangled.contains("FieldOptions") {
                            LKNoop()
                        }
                        guard let expectedParentTypename = getParentTypename(enumTypeDesc.name) else {
                            return false
                        }
                        return expectedParentTypename == messageTypename.mangled
                    }
                    print("message ty: \(messageTypename)")
                    print("nested enums \(nestedEnumTypes.map(\.name))" )
                    topLevelEnumTypes.subtract(nestedEnumTypes)
                    return nestedEnumTypes.map { enumTypeDesc -> EnumDescriptorProto in
                        EnumDescriptorProto(
                            name: String(enumTypeDesc.name.split(separator: ".").last!),
                            values: enumTypeDesc.values,
                            options: enumTypeDesc.options,
                            reservedRanges: enumTypeDesc.reservedRanges,
                            reservedNames: enumTypeDesc.reservedNames
                        )
                    }
                }(),
                extensionRanges: [], // <#T##[DescriptorProto.ExtensionRange]#>,
                oneofDecls: { () -> [OneofDescriptorProto] in
                    nestedOneofTypes.map { oneofType -> OneofDescriptorProto in
                        OneofDescriptorProto(
                            name: String(oneofType.name.split(separator: ".").last!), // TODO properly format (ie de-qualify) the name here!
                            options: nil
                        )
                    }
                }(),
                options: nil, //<#T##MessageOptions?#>,
                reservedRanges: [], // <#T##[DescriptorProto.ReservedRange]#>, // TODO is this somewhing we want to support? would be trivial to add to the Message protocol...
                reservedNames: [] // <#T##[String]#> // same as reservedRanges above...
            )
        }
    }
}







// MARK: OTHER





/// what a type becomes when coding it in protobuf
enum LKProtoCodingKind {
    case message
    case primitive
    case `enum`
    // TODO give oneofs a dedicated case here?
}

/// Returns whether the type is a message type in protobuf. (Or, rather, would become one.)
func LKGetProtoCodingKind(_ type: Any.Type) -> LKProtoCodingKind? {
    let conformsToMessageProtocol = (type as? LKProtobufferMessage.Type) != nil
//    if ((type as? Encodable) == nil) || ((type as? Decodable) == nil) {
//        // A type which conforms neiter to en- nor to decodable
//    }
    
    let isPrimitiveProtoType = (type as? LKProtobufferPrimitive.Type) != nil
    
    if type == Never.self {
        // We have this as a special case since never isn't really codable, but still allowed as a return type for handlers.
        return .message
    }
    
    guard (type as? Codable.Type) != nil else {
        // A type which isn't codable couldn't be en- or decoded in the first place
        fatalError()
        return nil
    }
    
    if (type as? LKProtobufferPrimitive.Type) != nil {
        // The type is a primitive
        precondition(!conformsToMessageProtocol)
        return .primitive
    }
    
    guard let TI = try? typeInfo(of: type) else {
        fatalError()
        return nil
    }
    
    switch TI.kind {
    case .struct:
        // The type is a struct, it is codable, but it is not a primitive.
        // What is it?
        // (Jpkes on you i dont know either,,,)
        
        // This is the point where we'd like to just be able to assume that it's a message, but I'm not really comfortable w/ thhat...
        return .message
        fatalError()
    case .enum:
        let isSimpleEnum = (type as? LKAnyProtobufferEnum.Type) != nil
        let isComplexEnum = (type as? LKAnyProtobufferEnumWithAssociatedValues.Type) != nil
        switch (isSimpleEnum, isComplexEnum) { // TODO the protocol names  here in the error messages aren't perfectly correct but we can't use the actual one bc reasons
        case (false, false):
            fatalError("Encountered an enum type (\(String(reflecting: type))) that conforms neither to '\(LKAnyProtobufferEnum.self)' nor to '\(LKAnyProtobufferEnumWithAssociatedValues.self)'")
        case (true, false):
            return .enum
        case (false, true):
            return .enum // TODO use a dedicated case????
        case (true, true):
            fatalError("Invalid enum, type: The '\(LKAnyProtobufferEnum.self)' and '\(LKAnyProtobufferEnumWithAssociatedValues.self)' protocols are mutually exclusive.")
        }
    default:
        // just return nil...!!!
        fatalError()
    }
}




// MARK: Utilz

struct Stack<Element> {
    private var storage: [Element]
    
    init() {
        storage = []
    }
    
    init<S>(_ other: S) where S: Sequence, S.Element == Element {
        storage = Array(other)
    }
    
    
    var isEmpty: Bool { storage.isEmpty }
    var count: Int { storage.count }
    
    mutating func push(_ element: Element) {
        storage.append(element)
    }
    
    @discardableResult
    mutating func pop() -> Element? {
        guard !isEmpty else {
            return nil
        }
        return storage.removeLast()
    }
    
    func peek() -> Element? {
        storage.last
    }
}

extension Stack: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
}


extension Stack: Collection {
    typealias Index = Array<Element>.Index
    
    var startIndex: Index {
        storage.startIndex
    }
    
    var endIndex: Index {
        storage.endIndex
    }
    
    subscript(index: Index) -> Element {
        storage[index]
    }
    
    func index(after idx: Index) -> Index {
        storage.index(after: idx)
    }
}


extension Stack where Element == Any.Type {
    func contains(_ other: Element) -> Bool {
        let identifier = ObjectIdentifier(other)
        return contains { ObjectIdentifier($0) == identifier }
    }
}





extension Array {
    /// Removes the first occurrence of the specified object from the array.
    /// - returns: The index from which the object was removed, `nil` if the object was not found in the array
    @discardableResult
    mutating func removeFirstOccurrence(of element: Element) -> Int? where Element: Equatable {
        if let idx = firstIndex(of: element) {
            remove(at: idx)
            return idx
        } else {
            return nil
        }
    }
    
    mutating func subtract<S>(_ other: S) where Element: Hashable, S: Sequence, S.Element == Element {
        let otherAsSet = Set(other)
        self = filter { !otherAsSet.contains($0) }
    }
    
    
    mutating func mapInPlace(_ transform: (inout Element) throws -> Void) rethrows {
        for idx in indices {
            var element = self[idx]
            try transform(&element)
            self[idx] = element
        }
    }
}


extension Dictionary {
    mutating func mapValuesInPlace(_ transform: (Key, inout Value) throws -> Void) rethrows {
        for key in keys {
            var value = self[key]!
            try transform(key, &value)
            self[key] = value
        }
    }
}
