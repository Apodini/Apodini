import Foundation
import Apodini
import ApodiniUtils
@_implementationOnly import Runtime





// TODO we probably should remove this?
protocol _ProtoIgnoreInReflection {}

protocol _ProtoPackage_Google_Protobuf: ProtoTypeInPackage {}
extension _ProtoPackage_Google_Protobuf {
    public static var package: ProtobufPackageName { .init("google.protobuf") }
}



// Used to unify the typename handling for messages and enums
private protocol __LKProtoTypeDescriptorProtocol {
    var name: String { get set }
}
extension DescriptorProto: __LKProtoTypeDescriptorProtocol {}
extension EnumDescriptorProto: __LKProtoTypeDescriptorProtocol {}




public enum ProtoTypeDerivedFromSwift: Hashable { // TODO this name sucks ass
    public struct MessageField: Hashable {
        public let name: String
        public let fieldNumber: Int
        public let type: ProtoTypeDerivedFromSwift
        public let isRepeated: Bool
        public let containingOneof: AnyProtobufEnumWithAssociatedValues.Type?
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
            hasher.combine(fieldNumber)
            hasher.combine(type)
            hasher.combine(isRepeated)
            hasher.combine(containingOneof.map(ObjectIdentifier.init))
        }
        
        public static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.name == rhs.name
                && lhs.fieldNumber == rhs.fieldNumber
                && lhs.type == rhs.type
                && lhs.isRepeated == rhs.isRepeated
                && lhs.containingOneof.map(ObjectIdentifier.init) == rhs.containingOneof.map(ObjectIdentifier.init)
        }
    }
    
    public struct EnumCase: Hashable {
        public let name: String
        public let value: Int32
    }
    
    public struct OneofType: Hashable {
        public let name: String
        public let underlyingType: AnyProtobufEnumWithAssociatedValues.Type
        /// The fields belonging to this oneof. Note that the field numbers here are w/in the context of the type containing a oneof field definition (ie the struct where one of the struct's properties is of a oneof type)
        public let fields: [MessageField]
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
            hasher.combine(ObjectIdentifier(underlyingType))
            hasher.combine(fields)
        }
        
        public static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.name == rhs.name
                && ObjectIdentifier(lhs.underlyingType) == ObjectIdentifier(rhs.underlyingType)
                && lhs.fields == rhs.fields
        }
    }
    
    public struct Typename: Hashable {
        public let packageName: String
        public let typename: String
        public var mangled: String {
            "[\(packageName)].\(typename)"
        }
        public var fullyQualified: String {
            ".\(packageName).\(typename)" // TODO do we want the initial period here?
        }
        public init(packageName: String, typename: String) {
            // TODO use a regex here!!!
            precondition(!packageName.hasPrefix("."))
            precondition(!typename.hasPrefix("."))
            self.packageName = packageName
            self.typename = typename
        }
        public init(mangled string: String) {
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
    case primitive(ProtobufPrimitive.Type)
    /// `google.protobuf.Empty`
    case builtinEmptyType
    indirect case compositeMessage(name: Typename, underlyingType: Any.Type?, nestedOneofTypes: [OneofType], fields: [MessageField]) // TOdO rename to just message?
    case enumTy(name: Typename, enumType: AnyProtobufEnum.Type, cases: [EnumCase])
    
    case refdMessageType(Typename) // A message type which is referenced by its name only. Used to break recursion when dealing with recursive types.
    
    public static var bytes: Self { .primitive([UInt8].self) }
    
    public func hash(into hasher: inout Hasher) {
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
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.isEqual(to: rhs, onlyCheckSemanticEquivalence: false)
    }
    
    /// - parameter onlyCheckSemanticEquivalence: whether the equality checking should be relaxed to return true if two objects are structurally different, but semantically equivalent. (e.g.: comparing a message type ref to a message type with the same name)
    public func isEqual(to other: Self, onlyCheckSemanticEquivalence: Bool) -> Bool {
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
    
    public var fullyQualifiedTypename: String {
        switch self {
        case .builtinEmptyType:
            return ".google.protobuf.Empty"
        case .primitive(let type):
            switch GetProtoFieldType(type) {
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




public class ProtoSchema {
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
    
    
    public init(defaultPackageName: String) {
        self.defaultPackageName = defaultPackageName
    }
    
    
    public func messageTypeDescriptors(forPackage packageName: String) -> [DescriptorProto] {
        precondition(isFinalized, "Cannot access message type descriptors: Schema not yet finalized")
        return finalizedTopLevelMessageTypesByPackage[packageName] ?? []
    }
    
    public func enumTypeDescriptors(forPackage packageName: String) -> [EnumDescriptorProto] {
        precondition(isFinalized, "Cannot access enum type descriptors: Schema not yet finalized")
        return finalizedTopLevelEnumTypesByPackage[packageName] ?? []
    }
    
    
    private func makeUniqueMessageTypename() -> String {
        return "LK_Message\(messageTypesTypenameCounter.get())" // TODO
    }
    
    private func makeUniqueEnumTypename() -> String {
        return "LK_Enum\(enumTypesTypenameCounter.get())" // TODO
    }
    
    
    public struct EndpointProtoMessageTypes {
        public let input: ProtoTypeDerivedFromSwift
        public let output: ProtoTypeDerivedFromSwift
    }
    
    
    // TODO rename to registerEndpointTypes or informAboutEndpoint or smth like that
    public func endpointProtoMessageTypes<H: Handler>(for endpoint: Endpoint<H>) throws -> EndpointProtoMessageTypes {
        precondition(!isFinalized, "Cannot add type to already finalized schema")
        if let types = endpointMessageMappings[ObjectIdentifier(H.self)] {
            return types
        } else {
            let types = EndpointProtoMessageTypes(
                input: collectTypes(in: try parametersMessageType(for: endpoint)),
                output: collectTypes(in: try responseMessageType(for: endpoint))
            )
            endpointMessageMappings[ObjectIdentifier(H.self)] = types
            return types
        }
    }
    
    
    func parametersMessageType<H: Handler>(for endpoint: Endpoint<H>) throws -> ProtoTypeDerivedFromSwift {
        precondition(!isFinalized, "Cannot add type to already finalized schema")
        let parameters = endpoint.parameters
        if parameters.count == 0 {
            // If there are no parameters, we map to the empty message type.
            return protoType(for: EmptyMessage.self, requireTopLevelCompatibleOutput: true)
        } else if parameters.count == 1 {
            let param = parameters[0]
            print("param.type:", param.propertyType)
            print("asMessage:", (param.propertyType as? ProtobufMessage.Type))
            // If there's only one parameter, and that parameter is a ProtobufferMessage, we can simply use that directly as the rpc's input.
//            if let protobufMessageType = param.propertyType as? ProtobufMessage.Type {
//                precondition(!param.nilIsValidValue) // TODO handleOptionals
//                return .messageType(protobufMessageType)
//            }
            //return try wrapSingleType(param.propertyType)
            
            return protoType(
                for: param.propertyType,
                requireTopLevelCompatibleOutput: true,
                singleParamHandlingContext: .init(
                    paramName: param.name,
                    wrappingMessageTypename: .init(packageName: defaultPackageName, typename: "\(H.self)___Input") // TODO +"Request"?
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
    
    
    func responseMessageType<H: Handler>(for endpoint: Endpoint<H>) throws -> ProtoTypeDerivedFromSwift {
        precondition(!isFinalized, "Cannot add type to already finalized schema")
        //return try wrapSingleType(H.Response.Content.self as! Codable.Type)
        print(H.self, "\(H.self)", String(describing: H.self), String(reflecting: H.self), String(reflecting: H.Response.Content.self))
        let endpointResponseType = protoType(
            for: H.Response.Content.self,
            requireTopLevelCompatibleOutput: true,
               singleParamHandlingContext: .init(
                paramName: "value",
                wrappingMessageTypename: .init(packageName: defaultPackageName, typename: "\(H.self)___Response")
            )
        )
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
    
    
    private func getTypename(_ type: Any.Type) -> ProtoTypeDerivedFromSwift.Typename {
        // TODO properly handle generic instantiations here! pretty sure that wouldn't be compatible w/ the proto naming rules.
        let typenameComponents = String(reflecting: type)
            .components(separatedBy: ".")
            .filter { !$0.hasPrefix("(unknown context at") }
        return ProtoTypeDerivedFromSwift.Typename(
            packageName: { () -> String in
                if let typeInPackageTy = type as? ProtoTypeInPackage.Type {
                    return typeInPackageTy.package.rawValue
                } else {
                    return self.defaultPackageName
                }
            }(),
            //typename: typenameComponents.dropFirst().joined(separator: ".")
            typename: {
                var components = Array(typenameComponents.dropFirst())
                precondition(!components.isEmpty)
                if let typeWithCustomTypenameTy = type as? ProtoTypeWithCustomProtoName.Type {
                    components[components.endIndex - 1] = typeWithCustomTypenameTy.protoTypename
                }
                return components.joined(separator: ".")
            }()
        )
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
    public func informAboutMessageType(_ type: ProtobufMessage.Type) -> ProtoTypeDerivedFromSwift {
        precondition(!isFinalized, "Cannot add type to already finalized schema")
        let result = protoType(for: type, requireTopLevelCompatibleOutput: false)
        collectTypes(in: result)
        return result
    }
    
    
    private func combineIntoCompoundMessageType(
        typename: ProtoTypeDerivedFromSwift.Typename,
        underlyingType: Any.Type?,
        elements: [(String, Any.Type)]
    ) -> ProtoTypeDerivedFromSwift {
        let underlyingTypeFieldNumbersMapping: [String: Int]? = {
            guard let messageTy = underlyingType as? AnyProtobufTypeWithCustomFieldMapping.Type else {
                return nil
            }
            // intentionally not using the getProtoFieldNumber thing here bc the user -- by declaring conformance to the AnyProtobufTypeWithCustomFieldMapping protocol --- has stated that they want to provide a custom mapping (which we expect to be nonnil)
            return .init(uniqueKeysWithValues: messageTy.getCodingKeysType().allCases.map { ($0.stringValue, $0.intValue!) })
        }()
        let (allElements, nestedOneofTypes) = elements.enumerated().reduce(
            into: ([], []) as (Set<ProtoTypeDerivedFromSwift.MessageField>, Set<ProtoTypeDerivedFromSwift.OneofType>)
        ) { (partialResult, arg0) in
            //let (idx, field) = arg0
            //let (fieldName, fieldType) = field
            let (idx, (fieldName, fieldType)) = arg0
            let newFields: [ProtoTypeDerivedFromSwift.MessageField]
            if let assocEnumTy = fieldType as? AnyProtobufEnumWithAssociatedValues.Type {
                // TODO do something w/ the fieldNAme in here? in proto, the oneofs do have names, although i'm not sure where they get used, if at all...
                let TI = try! typeInfo(of: assocEnumTy)
                precondition(TI.kind == .enum)
                let fieldNumbersByFieldName: [String: Int] = .init(uniqueKeysWithValues: assocEnumTy.getCodingKeysType().allCases.map {
                    // intentionally not using the getProtoFieldNumber thing here bc the AnyProtobufEnumWithAssociatedValues requires the user provide a custom mapping with nonnil field numbers
                    ($0.stringValue, $0.intValue!)
                })
                newFields = TI.cases.map { enumCase in
                    precondition((enumCase.payloadType as? ProtobufRepeated.Type) == nil)
                    return ProtoTypeDerivedFromSwift.MessageField.init(
                        name: enumCase.name,
                        fieldNumber: fieldNumbersByFieldName[enumCase.name]!,
                        type: protoType(for: enumCase.payloadType!, requireTopLevelCompatibleOutput: false), // TODO add support for cases w/out a payload? ideally wed just add some dummy value that subsequently gets ignored. would need to support that in the en/decoders as well, though. probably easier to simply require the user define that unused value (eg what the reflection API does...)
                        isRepeated: false, // not supported (TODO check that that's actually true!)
                        containingOneof: assocEnumTy
                    )
                }
                precondition(partialResult.1.insert(ProtoTypeDerivedFromSwift.OneofType(
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
                        if let repeatedType = fieldType as? ProtobufRepeated.Type, (fieldType as? ProtobufBytesMapped.Type) == nil {
                            return protoType(for: repeatedType.elementType, requireTopLevelCompatibleOutput: false)
                        } else {
                            return protoType(for: fieldType, requireTopLevelCompatibleOutput: false)
                        }
                    }(),
                    isRepeated: (fieldType as? ProtobufRepeated.Type) != nil,
                    containingOneof: nil
                )]
            }
            for field in newFields {
                precondition(partialResult.0.insert(field).inserted, "Duplicate fields in message!") // TODO better error here!
            }
        }
        return .compositeMessage(
            name: typename,
            underlyingType: underlyingType,
            nestedOneofTypes: Array(nestedOneofTypes),
            fields: Array(allElements)
        )
    }
    
    
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
            precondition(GetProtoCodingKind(type) == .message)
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
            return protoType(for: EmptyMessage.self, requireTopLevelCompatibleOutput: requireTopLevelCompatibleOutput)
        } else if type == Array<UInt8>.self || type == Data.self {
            if requireTopLevelCompatibleOutput {
                fatalError("TODO!")
            } else {
                return cacheRetval(.bytes)
            }
        } else if type == EmptyMessage.self {
            // TODO we might need special handling here, insofar as we want probably want one definition of the empty type per package...
            return cacheRetval(.compositeMessage(name: typename, underlyingType: EmptyMessage.self, nestedOneofTypes: [], fields: []))
        }
        
        let TI = try! typeInfo(of: type)
        let protoCodingKind = GetProtoCodingKind(type)
        
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
                    return protoType(for: EmptyMessage.self, requireTopLevelCompatibleOutput: requireTopLevelCompatibleOutput)
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
            //return .messageType(type as! ProtobufMessage.Type)
        case .primitive:
            guard let primitiveTy = type as? ProtobufPrimitive.Type else {
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
                        elements: [(singleParamHandlingContext.paramName, primitiveTy)]
                    ))
                } else {
                    fatalError("TODO do we ever end up here???")
                    return cacheRetval(combineIntoCompoundMessageType(
                        typename: .init(packageName: defaultPackageName, typename: "\(makeUniqueMessageTypename())"), // TODO come up w/ better method names!
                        underlyingType: nil,
                        elements: [("value", primitiveTy)]
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
            if let enumTy = type as? AnyProtobufEnum.Type {
                precondition(TI.cases.count == enumTy.allCases.count)
                let enumCases: [ProtoTypeDerivedFromSwift.EnumCase] = zip(TI.cases, enumTy.allCases).map {
                    //print(String(reflecting: $0.1))
                    precondition($0.0.name == String(String(reflecting: $0.1).split(separator: ".").last!))
                    return .init(name: $0.0.name, value: $0.1.rawValue)
                }
                if requireTopLevelCompatibleOutput {
                    fatalError()
                } else {
                    return cacheRetval(.enumTy(name: typename, enumType: enumTy, cases: enumCases))
                }
            } else if let enumTy = type as? AnyProtobufEnumWithAssociatedValues.Type {
                fatalError() // shouldn't end up here since enums w/ assoc values are handled as part of processing a message's fields into a composite.
            } else {
                fatalError("Encountered an enum type which implements neither '\(AnyProtobufEnum.self)' nor '\(AnyProtobufEnumWithAssociatedValues.self)'. This is highly irregular.")
            }
        }
    }
}



// TODO optional detection. should move this to the utils target. probably already have the exact same thing there.

protocol AnyOptional {
    static var wrappedType: Any.Type { get }
}

extension Optional: AnyOptional {
    static var wrappedType: Any.Type { Wrapped.self }
}



extension ProtoSchema {
    /// Seals the schema, i.e. not allowing any further types to be added, and resolves the types that have been added so far into a proto descriptor
    public func finalize() {
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
                guard (enumType as? _ProtoIgnoreInReflection.Type) == nil else {
                    return nil
                }
                return EnumDescriptorProto(
                    name: typename.mangled, // We keep the full typename since we need that for the type containment checks...
                    values: { () -> [EnumValueDescriptorProto] in
                        cases.map { enumCase -> EnumValueDescriptorProto in
                            EnumValueDescriptorProto(
                                name: enumCase.name,
                                number: enumCase.value,
                                options: nil // NOTE we could use this to mark enum cases as deprecated, although there's no way of reading e.g. a swift @deprecatd annotation, so that's probably not overly useful...
                            )
                        }
                    }(),
                    options: nil,
                    reservedRanges: { () -> [EnumDescriptorProto.EnumReservedRange] in
                        if let protoEnumTy = enumType as? AnyProtobufEnum.Type {
                            return protoEnumTy.reservedRanges.map { .init(start: $0.lowerBound, end: $0.upperBound) }
                        } else {
                            return []
                        }
                    }(),
                    reservedNames: { () -> [String] in
                        if let protoEnumTy = enumType as? AnyProtobufEnum.Type {
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
    }
    
    
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
            guard (underlyingType as? _ProtoIgnoreInReflection.Type) == nil else {
                return nil
            }
            let fieldNumbersMapping: [String: Int]
            if let protoCodableWithCodingKeysTy = underlyingType as? AnyProtobufTypeWithCustomFieldMapping.Type {
                let codingKeys = protoCodableWithCodingKeysTy.getCodingKeysType().allCases
                fieldNumbersMapping = .init(uniqueKeysWithValues: codingKeys.map { ($0.stringValue, $0.intValue!) }) // intentionally not using the getProtoFieldNumber thing here bc we want the user to define int values (and, in fact, require it so the force unwrap shouldn't be a problem anyway)
            } else {
                //fieldNumbersMapping = .init(uniqueKeysWithValues: fields.enumerated().map { ($0.element.key, $0.offset) })
                fieldNumbersMapping = .init(uniqueKeysWithValues: fields.map { ($0.name, $0.fieldNumber) })
            }
            return DescriptorProto(
                name: messageTypename.mangled, // Same as with enums, we intentionally keep the full name so that the type containment handling works correctly.
                fields: fields.map { field -> FieldDescriptorProto in
                    FieldDescriptorProto(
                        name: field.name,
                        number: Int32(fieldNumbersMapping[field.name]!),
                        label: { () -> FieldDescriptorProto.Label? in
                            // TODO this is where we need to detect arrays and turn them into a repeated field! (and also we probably should adjust the name, although that shouldn't be happening here but rather in the type napper.
                            if field.isRepeated {
                                return .LABEL_REPEATED
                            } else {
                                return nil
                            }
                        }(),
                        type: { () -> FieldDescriptorProto.FieldType? in
                            switch field.type {
                            case .builtinEmptyType:
                                return .TYPE_MESSAGE
                            case .primitive(let type):
                                return GetProtoFieldType(type)
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
                                fatalError() // TODO we also need to include the file defining this type!!!!
                                return field.type.fullyQualifiedTypename
                            case .compositeMessage(let typename, _, _, _), .enumTy(let typename, _, _), .refdMessageType(let typename):
                                return typename.fullyQualified
                            }
                        }(),
                        extendee: nil,
                        defaultValue: nil, //<#T##String?#>, // TODO?
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
                extensions: [],
                nestedTypes: [],
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
                extensionRanges: [],
                oneofDecls: { () -> [OneofDescriptorProto] in
                    nestedOneofTypes.map { oneofType -> OneofDescriptorProto in
                        OneofDescriptorProto(
                            name: String(oneofType.name.split(separator: ".").last!), // TODO properly format (ie de-qualify) the name here!
                            options: nil
                        )
                    }
                }(),
                options: nil,
                reservedRanges: [], // <#T##[DescriptorProto.ReservedRange]#>, // TODO is this somewhing we want to support? would be trivial to add to the Message protocol...
                reservedNames: [] // <#T##[String]#> // same as reservedRanges above...
            )
        }
    }
}
