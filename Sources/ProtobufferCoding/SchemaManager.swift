//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini
import ApodiniUtils
@_implementationOnly import Runtime

// swiftlint:disable closure_body_length


// Used to unify the typename handling for messages and enums
private protocol __ProtoTypeDescriptorProtocol {
    var name: String { get set }
}
extension DescriptorProto: __ProtoTypeDescriptorProtocol {}
extension EnumDescriptorProto: __ProtoTypeDescriptorProtocol {}


/// A proto typename, consisting of the proto package the type belongs to, as well as the (potentially qualified) name of the type.
public struct ProtoTypename: Hashable {
    public let packageName: String
    public let typename: String

    public var mangled: String {
        "[\(packageName)].\(typename)"
    }

    public var fullyQualified: String {
        ".\(packageName).\(typename)"
    }

    public init(packageName: String, typename: String) {
        precondition(!packageName.hasPrefix("."))
        precondition(!typename.hasPrefix("."))
        self.packageName = packageName
        self.typename = typename
    }
    public init(mangled string: String) {
        guard let packageEndIndex = string.firstIndex(of: "]") else {
            preconditionFailure("Encountered mangled type name without package prefix: '\(string)'")
        }
        self.init(
            packageName: String(string[string.index(after: string.startIndex)..<packageEndIndex]),
            typename: String(string[string.index(after: string.index(after: packageEndIndex))...])
        )
        precondition(string == self.mangled, "Encountered mangled name inconsistency: input '\(string)' vs output '\(self.mangled)'")
    }
}


/// A Protobuffer type that was derived from a Swift type.
public enum ProtoType: Hashable {
    public struct MessageField: Hashable {
        public let name: String
        public let fieldNumber: Int
        public let type: ProtoType
        public let isOptional: Bool
        public let isRepeated: Bool
        /// If the field is repeated, whether it is also packed.
        public let isPacked: Bool
        public let containingOneof: AnyProtobufEnumWithAssociatedValues.Type?
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
            hasher.combine(fieldNumber)
            hasher.combine(type)
            hasher.combine(isOptional)
            hasher.combine(isRepeated)
            hasher.combine(isPacked)
            hasher.combine(containingOneof.map(ObjectIdentifier.init))
        }
        
        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.name == rhs.name
                && lhs.fieldNumber == rhs.fieldNumber
                && lhs.type == rhs.type
                && lhs.isOptional == rhs.isOptional
                && lhs.isRepeated == rhs.isRepeated
                && lhs.isPacked == rhs.isPacked
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
        /// The fields belonging to this oneof.
        /// - Note: The field numbers here are w/in the context of the type containing a oneof field definition
        ///         (ie the struct where one of the struct's properties is of a oneof type).
        public let fields: [MessageField]
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
            hasher.combine(ObjectIdentifier(underlyingType))
            hasher.combine(fields)
        }
        
        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.name == rhs.name
                && ObjectIdentifier(lhs.underlyingType) == ObjectIdentifier(rhs.underlyingType)
                && lhs.fields == rhs.fields
        }
    }
    
    /// A type which is a protobuffer primitive, such as Strings, Ints, Doubles, etc
    /// - Note: The value is guaranteed to be a `ProtobufPrimitive.Type`
    case primitive(Any.Type)
    /// A protobuf message type.
    /// - parameter underlyingType: The Swift type modelled by this proto message. Nil for synthesized message types (e.g. wrappers created to make single values top-level-compatible).
    indirect case message(name: ProtoTypename, underlyingType: Any.Type?, nestedOneofTypes: [OneofType], fields: [MessageField])
    /// A protobuf enum type.
    case enumTy(name: ProtoTypename, enumType: AnyProtobufEnum.Type, cases: [EnumCase])
    /// A message type which is referenced by its name only. Used to break recursion when dealing with recursive types.
    case refdMessageType(ProtoTypename)
    /// The protobuf `bytes` type.
    public static var bytes: Self { .primitive([UInt8].self) }
    
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .primitive(let type):
            hasher.combine(0)
            hasher.combine(ObjectIdentifier(type))
        case let .message(name, underlyingType, nestedOneofTypes, fields):
            hasher.combine(1)
            hasher.combine(name)
            hasher.combine(underlyingType.map(ObjectIdentifier.init))
            hasher.combine(nestedOneofTypes)
            hasher.combine(fields)
        case let .enumTy(name, enumType, cases):
            hasher.combine(2)
            hasher.combine(name)
            hasher.combine(ObjectIdentifier(enumType))
            hasher.combine(cases)
        case .refdMessageType(let name):
            hasher.combine(3)
            hasher.combine(name)
        }
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.isEqual(to: rhs, onlyCheckSemanticEquivalence: false)
    }
    
    /// - parameter onlyCheckSemanticEquivalence: whether the equality checking should be relaxed to return true if two objects are structurally different,
    ///     but semantically equivalent. (e.g.: comparing a message type ref to a message type with the same name)
    public func isEqual(to other: Self, onlyCheckSemanticEquivalence: Bool) -> Bool {
        switch (self, other) {
        case let (.primitive(lhsTy), .primitive(rhsTy)):
            return ObjectIdentifier(lhsTy) == ObjectIdentifier(rhsTy)
        case let (.message(lhsName, lhsUnderlying, lhsNestedOneofs, lhsFields),
                  .message(rhsName, rhsUnderlying, rhsNestedOneofs, rhsFields)):
            return lhsName == rhsName
                && lhsUnderlying.map(ObjectIdentifier.init) == rhsUnderlying.map(ObjectIdentifier.init)
                && lhsNestedOneofs == rhsNestedOneofs
                && lhsFields.compareIgnoringOrder(rhsFields)
        case let (.enumTy(lhsName, lhsEnumType, lhsCases), .enumTy(rhsName, rhsEnumType, rhsCases)):
            return lhsName == rhsName && ObjectIdentifier(lhsEnumType) == ObjectIdentifier(rhsEnumType) && lhsCases == rhsCases
        case let (.refdMessageType(lhsName), .refdMessageType(rhsName)):
            return lhsName == rhsName
        case let (.refdMessageType(lhsName), .message(rhsName, _, _, _)):
            return onlyCheckSemanticEquivalence && lhsName == rhsName
        case let (.message(lhsName, _, _, _), .refdMessageType(rhsName)):
            return onlyCheckSemanticEquivalence && lhsName == rhsName
        default:
            return false
        }
    }
    
    public var fullyQualifiedTypename: String {
        switch self {
        case .primitive(let type):
            let fieldType = getProtoFieldType(type)
            switch fieldType {
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
            case .TYPE_FIXED32, .TYPE_FIXED64, .TYPE_SFIXED32, .TYPE_SFIXED64, .TYPE_SINT32, .TYPE_SINT64:
                fatalError("Unsupported field type: \(fieldType)")
            case .TYPE_BOOL:
                return "bool"
            case .TYPE_STRING:
                return "string"
            case .TYPE_GROUP:
                fatalError("Deprecated field type: \(fieldType)")
            case .TYPE_MESSAGE, .TYPE_ENUM:
                fatalError("Should've ended up in one of the other beanches in the outer switch")
            case .TYPE_BYTES:
                return "bytes"
            case .TYPE_UINT32:
                return "uint32"
            }
        case .refdMessageType(let typename):
            return typename.fullyQualified
        case .message(let typename, underlyingType: _, nestedOneofTypes: _, fields: _):
            return typename.fullyQualified
        case .enumTy(let typename, enumType: _, cases: _):
            return typename.fullyQualified
        }
    }
    
    
    /// Whether this type could appear as a "top-level" type in a proto file.
    /// This also implies that it could be used as the input/output type of a gPRC method
    public var isTopLevelType: Bool {
        switch self {
        case .refdMessageType, .message:
            return true
        case .primitive, .enumTy:
            return false
        }
    }
    
    
    /// The proto type's underlying Swift type, if available
    var underlyingType: Any.Type? {
        switch self {
        case .primitive(let type):
            return type
        case .message(_, let underlyingType, _, _):
            return underlyingType
        case .enumTy(_, let enumType, _):
            return enumType
        case .refdMessageType:
            return nil
        }
    }
    
    
    public var typename: ProtoTypename? {
        switch self {
        case .primitive:
            return nil
        case .message(let typename, _, _, _):
            return typename
        case .enumTy(let typename, _, _):
            return typename
        case .refdMessageType(let typename):
            return typename
        }
    }
    
    
    /// Returns a copy of `self`, with the typename's package adjusted to be the specified `packageName`.
    /// If `self` is a type that is not bound to some specific package, the unchanged input is returned.
    func movedIntoPackage(_ packageName: String) -> Self {
        switch self {
        case .primitive:
            return self
        case let .message(typename, underlyingType, nestedOneofTypes, fields):
            return .message(
                name: ProtoTypename(packageName: packageName, typename: typename.typename),
                underlyingType: underlyingType,
                nestedOneofTypes: nestedOneofTypes,
                fields: fields
            )
        case let .enumTy(typename, enumType, cases):
            return .enumTy(
                name: ProtoTypename(packageName: packageName, typename: typename.typename),
                enumType: enumType,
                cases: cases
            )
        case .refdMessageType:
            // The problem here is that this might well be referring to a type in a package,
            // but we can't replace the package name in the typename w/out breaking the reference.
            // So instead we just return self.
            return self
        }
    }
}


public enum ProtoValidationError: Swift.Error, Equatable {
    /// The error thrown if the schema encounters an enum that is not defined as a proto2 enum and is missing a case with the raw value `0`.
    case proto3EnumMissingCaseWithZeroValue(AnyProtobufEnum.Type)
    /// The error thrown if the schema encounters a type which is an array of optional values.
    /// - Note: The associated value here should be a `ProtobufRepeated{En,De}codable.Type`
    case arrayOfOptionalsNotAllowed(Any.Type)
    /// The error thrown if the schema encounters a type which is an optional array.
    /// - Note: The associated value here is an `Optional`, and this optional's wrapped type is pretty much guaranteed to be a `ProtobufRepeated{En,De}codable.Type`.
    case optionalArrayNotAllowed(AnyOptional.Type)
    /// The error thrown when the schema is asked to produce the proto type for an Array, but is now allowed to wrap the array in a composite message type
    /// - Note: The associated value here should be a `ProtobufRepeated{En,De}codable.Type`
    case topLevelArrayNotAllowed(Any.Type)
    /// The error thrown when the schema encounters a type wich is an enum, but does not implement either of the two proto enum protocols.
    case missingEnumProtocolConformance(Any.Type)
    /// The error thrown when the schema is unable to get runtime type metadata for a type
    case unableToGetTypeMetadata(Any.Type, underlyingError: Error)
    /// The error thrown when the schema is unable to determine the proto coding kind for a type
    case unableToDetermineProtoCodingKind(Any.Type)
    /// The schema failed at constructing a composite proto type (i.e. a message type), because the resulting type would've contained duplicate field names
    case messageTypeContainsDuplicateFieldNames(ProtoTypename)
    /// The error thrown when the schema is asked to produce a proto type descriptor for a type that is not an allowed top-level type
    case typeNotTopLevelCompatible(ProtoType)
    /// The error thrown when the schema is unable to resolve a nested proto type, i.e. unable to move the type into some other proto type that is part of the schema.
    /// This usually happens when a proto type (e.g. a `Codable` struct or enum) is nested in some other Swift type that is itself not part of the schema.
    case unableToResolveNestedProtoType(ProtoTypename)
    /// The error thrown if the schema encounters an invalid type nesting, e.g. a proto2 type nested inside a proto3 type, or the other way around.
    case invalidProto2AndProto3TypeNesting(parent: ProtoTypename, prospectiveChild: ProtoTypename)
    /// The error thrown if the schema encounters a package which contains both proto2 and proto3 types
    case invalidProto2AndProto3TypeMixing
    /// The error thrown if the schema encounters a `repeated` type within a `oneof`, i.e. in Swift an enum w/ associated values
    /// where one of the values is a type which gets mapped into a `repeated` type
    /// - Note: The associated value here should be a `ProtobufRepeated{En,De}codable.Type`
    case invalidRepeatedInOneof(Any.Type)
    /// The error thrown if the schema encounters an `optional` type within a `oneof`, i.e. in Swift an enum w/ associated values
    /// where one of the values is an `Optional` type.
    case invalidOptionalInOneof(Any.Type)
    /// The error thrown if the schema contains multiple protobuffer message types with the same type name.
    case conflictingMessageTypeNames(ProtoType, ProtoType)
    /// The error thrown by the schema when encountering one of the integer types not supported by protobuffer (i.e..`Int8`, `UInt8`, `Int16`, `UInt16`)
    case unsupportedIntegerType(Any.Type)
    /// Some other, unspecified error occurred while handling a type
    /// - parameter message: A String describing the error
    /// - parameter type: The type that caused this error, if applicable
    case other(message: String, type: Any.Type?)
    
    /// Compares two validation errors and checks wheter they're equal.
    /// - Note: This equality check will ignore sub-errors, since these are not equatable. Instead, only the validation error case, and any associated `Any.Type`s will be considered.
    public static func == (lhs: Self, rhs: Self) -> Bool { // swiftlint:disable:this cyclomatic_complexity
        switch (lhs, rhs) {
        case let (.proto3EnumMissingCaseWithZeroValue(lhsTy), .proto3EnumMissingCaseWithZeroValue(rhsTy)):
            return ObjectIdentifier(lhsTy) == ObjectIdentifier(rhsTy)
        case let (.arrayOfOptionalsNotAllowed(lhsTy), .arrayOfOptionalsNotAllowed(rhsTy)):
            return ObjectIdentifier(lhsTy) == ObjectIdentifier(rhsTy)
        case let (.optionalArrayNotAllowed(lhsTy), .optionalArrayNotAllowed(rhsTy)):
            return ObjectIdentifier(lhsTy) == ObjectIdentifier(rhsTy)
        case let (.topLevelArrayNotAllowed(lhsTy), .topLevelArrayNotAllowed(rhsTy)):
            return ObjectIdentifier(lhsTy) == ObjectIdentifier(rhsTy)
        case let (.missingEnumProtocolConformance(lhsTy), .missingEnumProtocolConformance(rhsTy)):
            return ObjectIdentifier(lhsTy) == ObjectIdentifier(rhsTy)
        case let (.unableToGetTypeMetadata(lhsTy, _), .unableToGetTypeMetadata(rhsTy, _)):
            return ObjectIdentifier(lhsTy) == ObjectIdentifier(rhsTy)
        case let (.unableToDetermineProtoCodingKind(lhsTy), .unableToDetermineProtoCodingKind(rhsTy)):
            return ObjectIdentifier(lhsTy) == ObjectIdentifier(rhsTy)
        case let (.messageTypeContainsDuplicateFieldNames(lhsTypename), .messageTypeContainsDuplicateFieldNames(rhsTypename)):
            return lhsTypename == rhsTypename
        case let (.typeNotTopLevelCompatible(lhsTy), .typeNotTopLevelCompatible(rhsTy)):
            return lhsTy == rhsTy
        case let (.unableToResolveNestedProtoType(lhsTypename), .unableToResolveNestedProtoType(rhsTypename)):
            return lhsTypename == rhsTypename
        case let (.invalidProto2AndProto3TypeNesting(lhsParent, lhsChild), .invalidProto2AndProto3TypeNesting(rhsParent, rhsChild)):
            return lhsParent == rhsParent && lhsChild == rhsChild
        case (.invalidProto2AndProto3TypeMixing, .invalidProto2AndProto3TypeMixing):
            return true
        case let (.invalidRepeatedInOneof(lhsTy), .invalidRepeatedInOneof(rhsTy)):
            return ObjectIdentifier(lhsTy) == ObjectIdentifier(rhsTy)
        case let (.invalidOptionalInOneof(lhsTy), .invalidOptionalInOneof(rhsTy)):
            return ObjectIdentifier(lhsTy) == ObjectIdentifier(rhsTy)
        case let (.conflictingMessageTypeNames(lhsTy1, lhsTy2), .conflictingMessageTypeNames(rhsTy1, rhsTy2)):
            return lhsTy1 == rhsTy1 && lhsTy2 == rhsTy2
        case let (.unsupportedIntegerType(lhsTy), .unsupportedIntegerType(rhsTy)):
            return ObjectIdentifier(lhsTy) == ObjectIdentifier(rhsTy)
        case let (.other(lhsMessage, lhsTy), .other(rhsMessage, rhsTy)):
            return lhsMessage == rhsMessage && lhsTy.map(ObjectIdentifier.init) == rhsTy.map(ObjectIdentifier.init)
        default:
            return false
        }
    }
}


/// Checks whether the type can be en- or decoded as a `repeated` proto type
func isProtoRepeatedEncodableOrDecodable(_ type: Any.Type) -> Bool {
    (type as? ProtobufRepeatedEncodable.Type != nil) || (type as? ProtobufRepeatedDecodable.Type != nil)
}


/// Retrieves, if `type` is a repeated type, the underlying element type.
/// - Note: This function returning a nonnil value implies that `type` is either repeated-field-encodable, or repeated-field-decodable, or both.
/// - Note: This function also checks whether, if `type` is both encodable and decodable, the underlying type is the same in both cases.
func getProtoRepeatedElementType(_ type: Any.Type) -> Any.Type? {
    let encodableUnderlyingType = (type as? ProtobufRepeatedEncodable.Type)?.elementType
    let decodableUnderlyingType = (type as? ProtobufRepeatedDecodable.Type)?.elementType
    if let encodableUnderlyingType = encodableUnderlyingType, let decodableUnderlyingType = decodableUnderlyingType {
        precondition(ObjectIdentifier(encodableUnderlyingType) == ObjectIdentifier(decodableUnderlyingType))
    }
    return encodableUnderlyingType ?? decodableUnderlyingType
}


/// Returns `true` iff the type is en/decodable as a `repeated`, and has packed fields.
func isProtoRepeatedPacked(_ type: Any.Type) -> Bool {
    if let encodableType = type as? ProtobufRepeatedEncodable.Type {
        return encodableType.isPacked
    } else if let decodableType = type as? ProtobufRepeatedDecodable.Type {
        return decodableType.isPacked
    } else {
        return false
    }
}


/// A Protobuf schema, i.e. an object that manages proto types appearing across one or more proto packages.
public class ProtoSchema {
    private static let endpointInputSuffix = "Input"
    private static let endpointOutputSuffix = "Response"
    
    // Key: Handler type
    private var endpointMessageMappings: [ObjectIdentifier: EndpointProtoMessageTypes] = [:]
    private var messageTypesTypenameCounter = Counter<UInt16>() // 65k wrapped types should be enough for the time being...
    
    /// the package name used for types which don't explicitly specify their own package.
    private let defaultPackageName: String
    
    /// Whether the schema has been finalized.
    /// Once the schema is finalized, no further types can be added, and the schema's processed contents can be accessed through the respective functions.
    public private(set) var isFinalized = false

    private(set) var allMessageTypes: [ProtoTypename: ProtoType] = [:]
    private(set) var allEnumTypes: [ProtoTypename: ProtoType] = [:]
    
    /// Helper intermediate type when finalizing the schema
    struct PackageTypeDescriptors<T> {
        let packageUnit: ProtobufPackageUnit
        let packageSyntax: ProtoSyntax
        let referencedSymbols: Set<String>
        let descriptors: [T]
    }
    
    private var finalizedTopLevelMessageTypesByPackage: [ProtobufPackageUnit: PackageTypeDescriptors<DescriptorProto>] = [:]
    private var finalizedTopLevelEnumTypesByPackage: [ProtobufPackageUnit: PackageTypeDescriptors<EnumDescriptorProto>] = [:]
    /// Mapping from package names to the set of fully qualified typenames contained in that package (including nested types
    public private(set) var fqtnByPackageMapping: [ProtobufPackageUnit: Set<String>] = [:]
    
    /// The mapping between all proto types known to the schema, and their respective package names.
    private var protoTypenameToPackageUnitMapping: [ProtoTypename: ProtobufPackageUnit] = [:]
    
    /// Information about a finalized proto package.
    public struct FinalizedPackage: Hashable {
        /// The name of the packae
        public let packageUnit: ProtobufPackageUnit
        /// The package's syntax. It is guaranteed for all `FinalizedPackage`s returned from the schema,
        /// that the package's syntax is the same as the syntax for all enum and message types contained in the package.
        public let packageSyntax: ProtoSyntax
        /// External proto symbols referenced by this package
        public let referencedSymbols: Set<String>
        /// All message types contained in this package
        public let messageTypes: [DescriptorProto]
        /// All enum types contained in this package
        public let enumTypes: [EnumDescriptorProto]
    }
    
    /// All packages known to the schema.
    public private(set) var finalizedPackages: [ProtobufPackageUnit: FinalizedPackage] = [:]

    /// This property maps ``ProtoTypename/mangled`` to ``String(reflecting: <SwiftType>.self)``.
    /// This allows us to get an identifier for the Swift Type a message or enum descriptor was built from.
    /// The mapping contains nil if the respective proto type was synthesized (e.g. input or output wrappers).
    public private(set) var protoNameToSwiftTypeMapping: [ProtoTypename: String?] = [:]
        
    /// Create a new Proto Schema.
    /// - parameter defaultPackageName: Proto package name that will be used for all types that don't specify an explicit package name via the `ProtoTypeInPackage` protocol.
    public init(defaultPackageName: String) {
        self.defaultPackageName = defaultPackageName
    }
    
    
    /// Creates a unique proto message typename.
    /// Used when creating wrapper types for non-top-level-compatible types
    private func makeUniqueMessageTypename() -> String {
        "_AnonMesgTy\(messageTypesTypenameCounter.get())"
    }
    
    
    /// Proto Input and Output types mapped from an Endpoint
    public struct EndpointProtoMessageTypes {
        /// Proto type representing the handler's input
        public let input: ProtoType
        /// Proto type representing the handler's output
        public let output: ProtoType
    }
    
    
    /// Informs the schema about an endpoint, and returns the proto types for the endpoint's request and response types.
    public func informAboutEndpoint<H: Handler>(_ endpoint: Endpoint<H>, grpcMethodName: String) throws -> EndpointProtoMessageTypes {
        precondition(!isFinalized, "Cannot add type to already finalized schema")
        if let types = endpointMessageMappings[ObjectIdentifier(H.self)] {
            return types
        } else {
            let types = EndpointProtoMessageTypes(
                input: try collectTypes(in: parametersMessageType(for: endpoint, grpcMethodName: grpcMethodName)),
                output: try collectTypes(in: responseMessageType(for: endpoint, grpcMethodName: grpcMethodName))
            )
            endpointMessageMappings[ObjectIdentifier(H.self)] = types
            return types
        }
    }
    
    
    func parametersMessageType<H: Handler>(for endpoint: Endpoint<H>, grpcMethodName: String) throws -> ProtoType {
        precondition(!isFinalized, "Cannot add type to already finalized schema")
        let parameters = endpoint.parameters
        switch parameters.count {
        case 0:
            // If there are no parameters, we map to the empty message type.
            return try protoType(for: EmptyMessage.self, requireTopLevelCompatibleOutput: true)
        case 1:
            let param = parameters[0]
            // If there's only one parameter, and that parameter is a ProtobufferMessage, we can simply use that directly as the rpc's input.
            return try protoType(
                for: param.originalPropertyType,
                requireTopLevelCompatibleOutput: true,
                singleParamHandlingContext: .init(
                    paramName: param.name,
                    wrappingMessageTypename: .init(
                        packageName: defaultPackageName,
                        typename: makeProtoMessageTypename(for: endpoint, context: .input)
                    )
                )
            )
        default:
            // The handler has multiple parameters, so we have to combine them into a protobuf message type
            return try combineIntoCompoundMessageType(
                typename: .init(
                    packageName: defaultPackageName,
                    typename: makeProtoMessageTypename(for: endpoint, context: .input)
                ),
                underlyingType: nil,
                elements: parameters.map { ($0.name, $0.originalPropertyType) }
            )
        }
    }
    
    
    func responseMessageType<H: Handler>(for endpoint: Endpoint<H>, grpcMethodName: String) throws -> ProtoType {
        precondition(!isFinalized, "Cannot add type to already finalized schema")
        let endpointResponseType = try protoType(
            for: H.Response.Content.self,
            requireTopLevelCompatibleOutput: true,
            singleParamHandlingContext: .init(
                paramName: "value",
                wrappingMessageTypename: .init(
                    packageName: defaultPackageName,
                    typename: makeProtoMessageTypename(for: endpoint, context: .response)
                )
            )
        )
        return endpointResponseType
    }
    
    
    private enum ImplicitWrapperMessageTypenameContext {
        case input
        case response
    }
    
    
    private func makeProtoMessageTypename<H: Handler>(for endpoint: Endpoint<H>, context: ImplicitWrapperMessageTypenameContext) -> String {
        switch context {
        case .input:
            if let name = endpoint[Context.self].get(valueFor: HandlerInputProtoMessageName.Key.self) {
                return name
            } else {
                return getProtoTypename(H.self).typename.appending(Self.endpointInputSuffix)
            }
        case .response:
            if let name = endpoint[Context.self].get(valueFor: HandlerResponseProtoMessageName.Key.self) {
                return name
            } else {
                return getProtoTypename(H.self).typename.appending(Self.endpointOutputSuffix)
            }
        }
    }
    
    
    /// Returns the package unit of which the specified typename is a part.
    public func getPackageUnit(forProtoTypename typename: ProtoTypename) -> ProtobufPackageUnit? {
        if let packageUnit = protoTypenameToPackageUnitMapping[typename] {
            return packageUnit
        } else {
            // We're probably dealing with one of the auto-generated wrapper messages, which are always in the default package
            precondition(self.defaultPackageName == typename.packageName)
            return ProtobufPackageUnit(packageName: typename.packageName)
        }
    }
    
    
    private func getProtoTypename(_ type: Any.Type) -> ProtoTypename {
        // The issue here (and the reason why we can't just do `return "\(type)\(suffix)"` is that the type might be generic,
        // in which case it'd contain invalid characters that would result in it not being a valid proto typename.
        // We have to map such types into valid proto typenames, with the properties that they:
        //   1. Do no longer contain any invalid characters (e.g. the '<')
        //   2. Still retain the information contained in the generic parameters (this might be important in case a client wants to re-assemble the type)
        //   3. Still uniquely identify the type. What this means is that if we have multiple instantiations of a generic type, all with the same parameters, they should result in the same proto typename. (assuming of course we also use the same prefix)
        // Note also that the same type (same in the sense that `ObjectIdentifier(a) == ObjectIdentifier(b)` would be true) can end up getting mapped to multiple typenames,
        // depending on the context in which the type is used. Therefore, typenames generated for Swift types cannot be cached.
        func cacheRetval(_ typename: ProtoTypename) -> ProtoTypename {
            let packageIdentifier = (type as? ProtoTypeInPackage.Type)?.package ?? .init(packageName: defaultPackageName)
            let inlineInParentPackageName = ProtobufPackageUnit.inlineInParentTypePackage.packageName

            if let oldValue = protoTypenameToPackageUnitMapping.updateValue(packageIdentifier, forKey: typename) {
                switch (oldValue.packageName == inlineInParentPackageName, packageIdentifier.packageName == inlineInParentPackageName) {
                case (true, true), (false, false):
                    precondition(oldValue == packageIdentifier)
                case (false, true), (true, false):
                    break
                }
            }
            return typename
        }
        // There are some generic types where we don't want the generic outer type to be included in the resulting proto
        // name, since it is already mapped to some other proto concept. (e.g.: optional or repeated fields)
        if let optionalTy = type as? AnyOptional.Type {
            // intentionally not caching here, bc we want the actual type as the cache key, rather than the Optional version
            return getProtoTypename(optionalTy.wrappedType)
        } else if let repeatedElementTy = getProtoRepeatedElementType(type) {
            return cacheRetval(getProtoTypename(repeatedElementTy))
        }
        
        let swiftTypename = SwiftTypename(type: type)
        if let protoTypename = (type as? ProtoTypeWithCustomProtoName.Type)?.protoTypename {
            swiftTypename.baseName = protoTypename
        }

        return cacheRetval(ProtoTypename(
            packageName: (type as? ProtoTypeInPackage.Type)?.package.packageName ?? defaultPackageName,
            typename: swiftTypename.mangleForProto(strict: false)
        ))
    }
    
    
    @discardableResult
    private func collectTypes(in protoType: ProtoType) throws -> ProtoType {
        precondition(!isFinalized, "Cannot add type to already finalized schema")
        let setMapping = { (dst: inout [ProtoTypename: ProtoType], name: ProtoTypename) in
            if let oldValue = dst[name] {
                guard oldValue.isEqual(to: protoType, onlyCheckSemanticEquivalence: false) else {
                    throw ProtoValidationError.conflictingMessageTypeNames(oldValue, protoType)
                }
                switch (oldValue, protoType) {
                case (.message, .refdMessageType):
                    // If we'd overwrite a "full" (i.e. non-ref) type with a ref, let's not do that
                    return
                default:
                    break
                }
            }
            dst[name] = protoType
        }
        switch protoType {
        case .primitive:
            break
        case let .message(name, underlyingType: _, nestedOneofTypes: _, fields):
            try setMapping(&allMessageTypes, name)
            for field in fields {
                try collectTypes(in: field.type)
            }
        case .enumTy(let name, enumType: _, cases: _):
            try setMapping(&allEnumTypes, name)
        case .refdMessageType:
            break
        }
        return protoType
    }
    
    
    /// Informs the schema about a message type, and computes a corresponding ProtoType
    @discardableResult
    public func informAboutMessageType(_ type: ProtobufMessage.Type) throws -> ProtoType {
        precondition(!isFinalized, "Cannot add type to already finalized schema")
        precondition(getProtoCodingKind(type) == .message)
        let result = try protoType(for: type, requireTopLevelCompatibleOutput: false)
        try collectTypes(in: result)
        return result
    }
    
    
    /// Informs the schema about a type, and computes a corresponding ProtoType
    /// - Note: Depending on the input type, this may or may not ourput a top-level-compatible type.
    @discardableResult
    public func informAboutType(_ type: Any.Type) throws -> ProtoType {
        precondition(!isFinalized, "Cannot add type to already finalized schema")
        let result = try protoType(for: type, requireTopLevelCompatibleOutput: false)
        try collectTypes(in: result)
        return result
    }
    
    
    private func combineIntoCompoundMessageType( // swiftlint:disable:this cyclomatic_complexity
        typename: ProtoTypename,
        underlyingType: Any.Type?,
        elements: [(String, Any.Type)]
    ) throws -> ProtoType {
        let underlyingTypeFieldNumbersMapping: [String: Int]? = { // swiftlint:disable:this discouraged_optional_collection
            guard let messageTy = underlyingType as? AnyProtobufTypeWithCustomFieldMapping.Type else {
                return nil
            }
            // intentionally not using the getProtoFieldNumber thing here bc the user -- by declaring conformance to the AnyProtobufTypeWithCustomFieldMapping protocol --- has stated that they want to provide a custom mapping (which we expect to be nonnil)
            return .init(uniqueKeysWithValues: messageTy.getCodingKeysType().allCases.map { ($0.stringValue, $0.intValue!) })
        }()
        let (allElements, nestedOneofTypes) = try elements.enumerated().reduce(
            into: ([], []) as (Set<ProtoType.MessageField>, Set<ProtoType.OneofType>)
        ) { partialResult, arg0 in
            let (idx, (fieldName, fieldType)) = arg0
            let newFields: [ProtoType.MessageField]
            if let assocEnumTy = fieldType as? AnyProtobufEnumWithAssociatedValues.Type {
                let typeInfo = try Runtime.typeInfo(of: assocEnumTy)
                precondition(typeInfo.kind == .enum)
                let fieldNumbersByFieldName: [String: Int] = .init(uniqueKeysWithValues: assocEnumTy.getCodingKeysType().allCases.map {
                    // intentionally not using the getProtoFieldNumber thing here bc the AnyProtobufEnumWithAssociatedValues requires the user provide a custom mapping with nonnil field numbers
                    ($0.stringValue, $0.intValue!)
                })
                newFields = try typeInfo.cases.map { enumCase in
                    guard let payloadType = enumCase.payloadType else {
                        fatalError("Runtime introspection error: Unable to get payload type for enum w/ associated values")
                    }
                    if isProtoRepeatedEncodableOrDecodable(payloadType) {
                        throw ProtoValidationError.invalidRepeatedInOneof(payloadType)
                    }
                    if enumCase.payloadType as? AnyOptional.Type != nil {
                        throw ProtoValidationError.invalidOptionalInOneof(payloadType)
                    }
                    return ProtoType.MessageField(
                        name: enumCase.name,
                        fieldNumber: fieldNumbersByFieldName[enumCase.name]!,
                        // We currently don't support cases w/out a payload. Instead, the user should use the `EmptyMessage` type as a payload.
                        // ideally we'd just add some dummy value that subsequently gets ignored.
                        // would need to support that in the en/decoders as well, though.
                        // probably easier to simply require the user define that unused value (eg what the reflection API does...)
                        type: try protoType(for: payloadType, requireTopLevelCompatibleOutput: false),
                        isOptional: false, // Fields inside a oneof cannot be optional
                        isRepeated: false, // not supported
                        isPacked: false, // if it can't be repeated, it also can't be packed
                        containingOneof: assocEnumTy
                    )
                }
                precondition(partialResult.1.insert(ProtoType.OneofType(
                    name: fieldName,
                    underlyingType: assocEnumTy,
                    fields: newFields
                )).inserted)
                // The insertion check here is to ensure that a type contains at most one property of a given enum w/ assoc values.
                // This is the limit since we'd otherwise have duplicate field numbers.
            } else {
                // The field's type is not an enum w/ associated values, meaning that the field simply gets turned into one field in the resulting message.
                newFields = [.init( // swiftlint:disable:this multiline_literal_brackets
                    name: fieldName,
                    fieldNumber: { () -> Int in
                        if let fieldNumbersMapping = underlyingTypeFieldNumbersMapping {
                            return fieldNumbersMapping[fieldName]!
                        } else {
                            return idx + 1
                        }
                    }(),
                    type: try { () -> ProtoType in
                        var fieldProtoType: ProtoType
                        if let repeatedElementType = getProtoRepeatedElementType(fieldType), fieldType as? ProtobufBytesMapped.Type == nil {
                            guard repeatedElementType as? AnyOptional.Type == nil else {
                                throw ProtoValidationError.arrayOfOptionalsNotAllowed(fieldType)
                            }
                            fieldProtoType = try protoType(for: repeatedElementType, requireTopLevelCompatibleOutput: false)
                        } else {
                            fieldProtoType = try protoType(for: fieldType, requireTopLevelCompatibleOutput: false)
                        }
                        // Adjust the field type's package if necessary
                        if let fieldProtoTypename = fieldProtoType.typename,
                           let fieldProtoUnderlyingType = fieldProtoType.underlyingType,
                           fieldProtoTypename.packageName == ProtobufPackageUnit.inlineInParentTypePackage.packageName {
                            precondition(((fieldProtoUnderlyingType as? ProtoTypeInPackage.Type)?.package == .inlineInParentTypePackage))
                            // The field's underlying Swift type has stated that it wants to be "inlined" into the parent type's package.
                            // (The parent type being the type to which this field belongs.)
                            let parentPackage = self.protoTypenameToPackageUnitMapping[typename] ?? .init(packageName: self.defaultPackageName)
                            fieldProtoType = fieldProtoType.movedIntoPackage(typename.packageName)
                            precondition(fieldProtoType.typename != fieldProtoTypename)
                            if self.protoTypenameToPackageUnitMapping.removeValue(forKey: fieldProtoTypename) != nil {
                                // If the type being moved into the current package already had a typename -> package mapping,
                                // adjust that to point to the new pacjage
                                self.protoTypenameToPackageUnitMapping[fieldProtoType.typename!] = parentPackage
                            }
                        }
                        return fieldProtoType
                    }(),
                    isOptional: fieldType as? AnyOptional.Type != nil,
                    isRepeated: isProtoRepeatedEncodableOrDecodable(fieldType),
                    isPacked: isProtoRepeatedPacked(fieldType),
                    containingOneof: nil
                )] // swiftlint:disable:this multiline_literal_brackets
            }
            for field in newFields {
                guard partialResult.0.insert(field).inserted else {
                    throw ProtoValidationError.messageTypeContainsDuplicateFieldNames(typename)
                }
            }
        }
        return .message(
            name: typename,
            underlyingType: underlyingType,
            nestedOneofTypes: Array(nestedOneofTypes),
            fields: Array(allElements)
        )
    }
    
    
    private struct CachedProtoTypesKey: Hashable {
        let type: Any.Type
        let requireTopLevelCompatibleOutput: Bool
        let primitiveTypeHandlingContext: SingleParamHandlingContext?
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(ObjectIdentifier(type))
            hasher.combine(requireTopLevelCompatibleOutput)
            hasher.combine(primitiveTypeHandlingContext)
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            ObjectIdentifier(lhs.type) == ObjectIdentifier(rhs.type)
                && lhs.requireTopLevelCompatibleOutput == rhs.requireTopLevelCompatibleOutput
                && lhs.primitiveTypeHandlingContext == rhs.primitiveTypeHandlingContext
        }
    }
    
    private var cachedResults: [CachedProtoTypesKey: ProtoType] = [:]
    private var currentTypesStack: Stack<CachedProtoTypesKey> = []
    
    
    /// Helper type which provides context used when mapping a primitive type into a message type
    private struct SingleParamHandlingContext: Hashable {
        let paramName: String
        let wrappingMessageTypename: ProtoTypename
    }
    
    /// Returns a proto type representing the Swift type `type` in a proto definition.
    /// - parameter requireTopLevelCompatibleOutput: whether the function is required to produce types that are value "top-level" types in protobuf (i.e. messages or enums).
    ///         If set to true, types which can not be used as top-level types (e.g. primitive types, oneofs, etc) will be wrapped in a wrapper message type
    private func protoType( // swiftlint:disable:this cyclomatic_complexity
        for type: Any.Type,
        requireTopLevelCompatibleOutput: Bool,
        singleParamHandlingContext: SingleParamHandlingContext? = nil
    ) throws -> ProtoType {
        let protoTypename = getProtoTypename(type)
        
        if String(reflecting: type) == "Builtin.\(String(describing: type))" {
            fatalError("Delved too greedily and too deep into the type hierarchy and reached one of the Builtin types: '\(type)'")
        }
        
        let cacheKey = CachedProtoTypesKey(
            type: type,
            requireTopLevelCompatibleOutput: requireTopLevelCompatibleOutput,
            primitiveTypeHandlingContext: singleParamHandlingContext
        )
        
        if currentTypesStack.contains(cacheKey) {
            precondition(getProtoCodingKind(type) == .message)
            return .refdMessageType(protoTypename)
        }
        currentTypesStack.push(cacheKey)
        defer {
            currentTypesStack.pop()
        }
        
        if let cached = cachedResults[cacheKey] {
            return cached
        }
        
        precondition(!isFinalized, "Cannot call '\(#function)' on finalized schema.")
        
        func cacheRetval(_ retval: ProtoType) -> ProtoType {
            cachedResults[cacheKey] = retval
            return retval
        }
        
        func wrapSingleFieldInMessageType(type: Any.Type, fallbackTypename: String) throws -> ProtoType {
            if let singleParamHandlingContext = singleParamHandlingContext {
                return try combineIntoCompoundMessageType(
                    typename: singleParamHandlingContext.wrappingMessageTypename,
                    underlyingType: nil,
                    elements: [(singleParamHandlingContext.paramName, type)]
                )
            } else {
                return try combineIntoCompoundMessageType(
                    typename: .init(packageName: defaultPackageName, typename: fallbackTypename),
                    underlyingType: nil,
                    elements: [("value", type)]
                )
            }
        }
        
        if let optionalTy = type as? AnyOptional.Type {
            guard !isProtoRepeatedEncodableOrDecodable(optionalTy.wrappedType) else {
                // type is an `[T]?`, which is not an allowed proto field type
                throw ProtoValidationError.optionalArrayNotAllowed(optionalTy)
            }
            return try protoType(
                for: optionalTy.wrappedType,
                requireTopLevelCompatibleOutput: requireTopLevelCompatibleOutput,
                singleParamHandlingContext: singleParamHandlingContext
            )
        } else if type == Never.self {
            return cacheRetval(try protoType(
                for: EmptyMessage.self,
                requireTopLevelCompatibleOutput: requireTopLevelCompatibleOutput,
                singleParamHandlingContext: singleParamHandlingContext
            ))
        } else if type == Array<UInt8>.self || type == Data.self {
            precondition((type as? ProtobufBytesMapped.Type) != nil)
            if !requireTopLevelCompatibleOutput {
                return cacheRetval(.bytes)
            } else {
                return cacheRetval(try wrapSingleFieldInMessageType(type: type, fallbackTypename: makeUniqueMessageTypename()))
            }
        } else if let repeatedElementTy = getProtoRepeatedElementType(type) {
            // The check above will only succeed if type conforms is an en- or decodable repeated type.
            precondition(isProtoRepeatedEncodableOrDecodable(type))
            precondition((type as? ProtobufBytesMapped.Type) == nil)
            guard (repeatedElementTy as? AnyOptional.Type) == nil else {
                throw ProtoValidationError.arrayOfOptionalsNotAllowed(type)
            }
            if requireTopLevelCompatibleOutput {
                // We're asked to wrap an array into a message
                return cacheRetval(try wrapSingleFieldInMessageType(type: type, fallbackTypename: makeUniqueMessageTypename()))
            } else {
                // We're given an array, which cannot be a top-level type, and not told to turn it into a top-level type
                throw ProtoValidationError.topLevelArrayNotAllowed(type)
            }
        } else if type == EmptyMessage.self || type == Void.self {
            return cacheRetval(.message(name: protoTypename, underlyingType: EmptyMessage.self, nestedOneofTypes: [], fields: []))
        } else if [UUID.self, URL.self].contains(type) {
            return cacheRetval(try protoType(
                for: String.self,
                requireTopLevelCompatibleOutput: requireTopLevelCompatibleOutput,
                singleParamHandlingContext: singleParamHandlingContext
            ))
        } else if type == Date.self {
            return cacheRetval(try protoType(
                for: ProtoTimestamp.self,
                requireTopLevelCompatibleOutput: requireTopLevelCompatibleOutput,
                singleParamHandlingContext: singleParamHandlingContext
            ))
        } else if [Int8.self, UInt8.self, Int16.self, UInt16.self].contains(type) {
            throw ProtoValidationError.unsupportedIntegerType(type)
        }
        
        let typeInfo: TypeInfo
        do {
            typeInfo = try Runtime.typeInfo(of: type)
        } catch {
            throw ProtoValidationError.unableToGetTypeMetadata(type, underlyingError: error)
        }
        let protoCodingKind = getProtoCodingKind(type)
        
        switch protoCodingKind {
        case nil:
            throw ProtoValidationError.unableToDetermineProtoCodingKind(type)
        case .message:
            switch typeInfo.kind {
            case .struct:
                switch typeInfo.properties.count {
                case 0:
                    return try protoType(
                        for: EmptyMessage.self,
                        requireTopLevelCompatibleOutput: requireTopLevelCompatibleOutput,
                        singleParamHandlingContext: singleParamHandlingContext
                    )
                default:
                    return cacheRetval(try combineIntoCompoundMessageType(
                        typename: protoTypename,
                        underlyingType: type,
                        elements: typeInfo.properties.map { ($0.name, $0.type) }
                    ))
                }
            default:
                fatalError("Unsupported type: \(typeInfo.kind)")
            }
        case .primitive:
            guard let primitiveTy = type as? ProtobufPrimitive.Type else {
                throw ProtoValidationError.other(
                    message: "Type with proto coding kind .primitive does not conform to '\(ProtobufPrimitive.self)'",
                    type: type
                )
            }
            if !requireTopLevelCompatibleOutput {
                return cacheRetval(.primitive(primitiveTy))
            } else {
                return cacheRetval(try wrapSingleFieldInMessageType(type: primitiveTy, fallbackTypename: makeUniqueMessageTypename()))
            }
        case .repeated:
            fatalError("unreachable, already handled above")
        case .enum:
            guard let enumTy = type as? AnyProtobufEnum.Type else {
                fatalError("unreachable")
            }
            precondition(typeInfo.cases.count == enumTy.allCases.count)
            let enumCases: [ProtoType.EnumCase] = zip(typeInfo.cases, enumTy.allCases).map {
                precondition($0.0.name == String(String(reflecting: $0.1).split(separator: ".").last!))
                return .init(name: $0.0.name, value: $0.1.rawValue)
            }
            if (type as? Proto2Codable.Type == nil) && !enumCases.contains(where: { $0.value == 0 }) {
                throw ProtoValidationError.proto3EnumMissingCaseWithZeroValue(enumTy)
            }
            if !requireTopLevelCompatibleOutput {
                return cacheRetval(.enumTy(name: protoTypename, enumType: enumTy, cases: enumCases))
            } else {
                return cacheRetval(try wrapSingleFieldInMessageType(type: enumTy, fallbackTypename: makeUniqueMessageTypename()))
            }
        case .oneof:
            precondition(type as? AnyProtobufEnumWithAssociatedValues.Type != nil)
            // shouldn't end up here since enums w/ assoc values are handled as part of processing a message's fields into a composite.
            fatalError(
                "Attempted to turn an enum with associated values into a proto type, which is invalid. Embed in a message type instead."
            )
        }
    }
}


extension ProtoSchema {
    private struct MapMessageTypeResult: Hashable {
        var typeDescriptor: DescriptorProto
        let protoSyntax: ProtoSyntax
        var referencedTypes: Set<String> // Array of fully qualified types
    }
    
    /// Seals the schema, i.e. not allowing any further types to be added, and resolves the types that have been added so far into a proto descriptor
    public func finalize() throws {
        guard !isFinalized else {
            return
        }
        isFinalized = true
        try processTypes()
    }
    
    private func processTypes() throws { // swiftlint:disable:this cyclomatic_complexity
        precondition(isFinalized, "Cannot process types of finalized schema")
        
        self.fqtnByPackageMapping = { () -> [ProtobufPackageUnit: Set<String>] in
            var retval: [ProtobufPackageUnit: Set<String>] = [:]
            let insert = { (key: ProtobufPackageUnit, value: String) in
                if retval[key] == nil {
                    retval[key] = Set([value])
                } else {
                    retval[key]!.insert(value)
                }
            }
            precondition(protoTypenameToPackageUnitMapping.keys.allSatisfy {
                $0.packageName != ProtobufPackageUnit.inlineInParentTypePackage.packageName
            })
            for enumTypename in self.allEnumTypes.keys {
                insert(protoTypenameToPackageUnitMapping[enumTypename]!, enumTypename.fullyQualified)
            }
            for msgTypename in self.allMessageTypes.keys {
                insert(protoTypenameToPackageUnitMapping[msgTypename] ?? .init(packageName: msgTypename.packageName), msgTypename.fullyQualified)
            }
            return retval
        }()
        
        // We start out by making every type a top-level type
        // Firstly, we process enums, since these are the simplest types (enums can't contain other types, they are a simple key-value mapping)
        var topLevelEnumTypeDescs = try allEnumTypes.values.map { protoType -> (EnumDescriptorProto, ProtoSyntax) in
            switch protoType {
            case .primitive, .message, .refdMessageType:
                throw ProtoValidationError.typeNotTopLevelCompatible(protoType)
            case let .enumTy(typename, enumType, cases):
                self.protoNameToSwiftTypeMapping[typename] = String(reflecting: enumType)

                let desc = EnumDescriptorProto(
                    name: typename.mangled, // We keep the full typename since we need that for the type containment checks...
                    values: cases.map { enumCase -> EnumValueDescriptorProto in
                        EnumValueDescriptorProto(
                            name: enumCase.name,
                            number: enumCase.value,
                            options: nil
                        )
                    },
                    options: nil,
                    reservedRanges: { () -> [EnumDescriptorProto.EnumReservedRange] in
                        let reserved = enumType.reservedFields.allReservedFieldNumbers()
                        var retval: [EnumDescriptorProto.EnumReservedRange] = []
                        retval.reserveCapacity(reserved.indices.count + reserved.ranges.count)
                        for idx in reserved.indices {
                            retval.append(.init(start: idx, end: idx))
                        }
                        for range in reserved.ranges {
                            retval.append(.init(start: range.lowerBound, end: range.upperBound))
                        }
                        return retval
                    }(),
                    reservedNames: enumType.reservedFields.allReservedNames()
                )
                precondition(enumType is Proto2Codable.Type == (enumType as? Proto2Codable.Type != nil))
                return (desc, (enumType as? Proto2Codable.Type != nil) ? .proto2 : .proto3)
            }
        }
        
        // Next, we process message types. Again, we first map them all into the global namespace, ignoring any potential nesting
        // This step will already take care of nested enums, which will be moved out of the top-level namespace and put into their respective parent message types.
        var topLevelMessageTypeDescs = try allMessageTypes.values.map { protoType -> MapMessageTypeResult in
            try mapMessageType(protoType, topLevelEnumTypes: &topLevelEnumTypeDescs)
        }
        
        // Next, we have to go through the message types and determine which of them are top-level types, and which are not.
        // For types which are not top-level types, we move them into their parent type.
        do { // lmao all of this is so fucking inefficient
            var potentiallyNestedTypes = Stack(topLevelMessageTypeDescs
                .filter { ty1 in
                    topLevelMessageTypeDescs.contains { ty2 in
                        ty1.typeDescriptor.name.count > ty2.typeDescriptor.name.count
                        && ty1.typeDescriptor.name.hasPrefix(ty2.typeDescriptor.name)
                    }
                }
                .sorted { lhs, rhs in
                    let lhsNestingDepth = lhs.typeDescriptor.name.count { $0 == "." }
                    let rhsNestingDepth = rhs.typeDescriptor.name.count { $0 == "." }
                    return rhsNestingDepth > lhsNestingDepth
                })
            
            while let typeEntry = potentiallyNestedTypes.pop() {
                // Check whether the type is in fact nested.
                // If yes, move it into its parent type and remove it from the list of top-level types.
                let typeDesc = typeEntry.typeDescriptor
                let expectedParentName = getParentTypename(typeDesc.name)!
                guard let containingTypeIdx = topLevelMessageTypeDescs.firstIndex(where: {
                    $0.typeDescriptor.name == expectedParentName
                }) else {
                    continue
                }
                // We add it into its containing type, with the typename adjusted accordingly
                guard topLevelMessageTypeDescs[containingTypeIdx].protoSyntax == typeEntry.protoSyntax else {
                    throw ProtoValidationError.invalidProto2AndProto3TypeNesting(
                        parent: ProtoTypename(mangled: expectedParentName),
                        prospectiveChild: ProtoTypename(mangled: typeDesc.name)
                    )
                }
                topLevelMessageTypeDescs[containingTypeIdx].referencedTypes.formUnion(typeEntry.referencedTypes)
                topLevelMessageTypeDescs[containingTypeIdx].typeDescriptor.nestedTypes.append(DescriptorProto(
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
                topLevelMessageTypeDescs.removeFirstOccurrence(of: typeEntry)
            }
        }
        
        
        /// Parses a `ProtoTypename` and extracts the typename part (i.e. drops the package)
        func handleTypename(_ mangledName: String) throws -> String {
            let protoTypename = ProtoTypename(mangled: mangledName)
            let newName = protoTypename.typename
            if newName.rangeOfCharacter(from: CharacterSet(charactersIn: ".<>[]")) != nil {
                throw ProtoValidationError.unableToResolveNestedProtoType(protoTypename)
            } else {
                return newName
            }
        }
        
        self.finalizedTopLevelEnumTypesByPackage = try Dictionary(
            grouping: topLevelEnumTypeDescs,
            by: { getPackageUnit(forProtoTypename: ProtoTypename(mangled: $0.0.name))! }
        )
            .mapValues { packageUnit, typeEntries -> PackageTypeDescriptors<EnumDescriptorProto> in
                precondition(!typeEntries.isEmpty)
                // Make sure that all top-level enums declared in this package have the same proto syntax version.
                let packageSyntax: ProtoSyntax = typeEntries.first!.1
                for (_, enumProtoSyntax) in typeEntries {
                    guard packageSyntax == enumProtoSyntax else {
                        fatalError("Cannot put \(enumProtoSyntax) and \(packageSyntax) enums in the same package.")
                    }
                }
                return PackageTypeDescriptors(
                    packageUnit: packageUnit,
                    packageSyntax: packageSyntax,
                    referencedSymbols: [], // Enums never reference anything
                    descriptors: try typeEntries.map { enumEntry -> EnumDescriptorProto in
                        let enumTypeDesc = enumEntry.0
                        return EnumDescriptorProto(
                            name: try handleTypename(enumTypeDesc.name),
                            values: enumTypeDesc.values,
                            options: enumTypeDesc.options,
                            reservedRanges: enumTypeDesc.reservedRanges,
                            reservedNames: enumTypeDesc.reservedNames
                        )
                    }
                )
            }

        self.finalizedTopLevelMessageTypesByPackage = try Dictionary(
            grouping: topLevelMessageTypeDescs,
            by: { getPackageUnit(forProtoTypename: ProtoTypename(mangled: $0.typeDescriptor.name))! }
        )
            .mapValues { packageUnit, mappedTypes -> PackageTypeDescriptors<DescriptorProto> in
                precondition(!mappedTypes.isEmpty)
                // Make sure that all top-level message types declared in this package have the same proto syntax version.
                let packageSyntax: ProtoSyntax = mappedTypes.first!.protoSyntax
                for type in mappedTypes {
                    guard packageSyntax == type.protoSyntax else {
                        throw ProtoValidationError.invalidProto2AndProto3TypeMixing
                    }
                }
                let allTypesInPackage = fqtnByPackageMapping[packageUnit]!
                return PackageTypeDescriptors(
                    packageUnit: packageUnit,
                    packageSyntax: packageSyntax,
                    referencedSymbols: Set(mappedTypes.flatMap(\.referencedTypes).filter { !allTypesInPackage.contains($0) }),
                    descriptors: try mappedTypes.map { type -> DescriptorProto in
                        var msgTypeDesc = type.typeDescriptor
                        msgTypeDesc.name = try handleTypename(msgTypeDesc.name)
                        return msgTypeDesc
                    }
                )
            }
        
        let allPackageUnits = Set(finalizedTopLevelMessageTypesByPackage.keys).union(finalizedTopLevelEnumTypesByPackage.keys)
        for packageUnit in allPackageUnits {
            let (messageTypes, enumTypes) = try topLevelTypeDescriptors(forPackage: packageUnit)
            self.finalizedPackages[packageUnit] = FinalizedPackage(
                packageUnit: packageUnit,
                packageSyntax: messageTypes.packageSyntax,
                referencedSymbols: messageTypes.referencedSymbols,
                messageTypes: messageTypes.descriptors,
                enumTypes: enumTypes.descriptors
            )
        }
    }
    
    
    /// Fetches the type descriptors of all top-level message and enum types in te specified proto package.
    /// - Note: This function may only be called after finalizing the schema
    /// - Throws: If the resulting package would be invalid, e.g. because it contains both proto2 and proto3 types.
    private func topLevelTypeDescriptors(
        forPackage packageUnit: ProtobufPackageUnit
    ) throws -> (messages: PackageTypeDescriptors<DescriptorProto>, enums: PackageTypeDescriptors<EnumDescriptorProto>) {
        precondition(isFinalized, "Cannot access type descriptors: Schema not yet finalized")
        let messages = finalizedTopLevelMessageTypesByPackage[packageUnit]
        let enums = finalizedTopLevelEnumTypesByPackage[packageUnit]
        switch (messages, enums) {
        case (.none, .none):
            return (
                messages: .init(packageUnit: packageUnit, packageSyntax: .proto3, referencedSymbols: [], descriptors: []),
                enums: .init(packageUnit: packageUnit, packageSyntax: .proto3, referencedSymbols: [], descriptors: [])
            )
        case (.some(let messages), .none):
            return (
                messages: messages,
                enums: .init(packageUnit: packageUnit, packageSyntax: messages.packageSyntax, referencedSymbols: [], descriptors: [])
            )
        case (.none, .some(let enums)):
            return (
                messages: .init(packageUnit: packageUnit, packageSyntax: enums.packageSyntax, referencedSymbols: [], descriptors: []),
                enums: enums
            )
        case let (.some(messages), .some(enums)):
            guard messages.packageSyntax == enums.packageSyntax else {
                throw ProtoValidationError.invalidProto2AndProto3TypeMixing
            }
            return (messages, enums)
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
    
    
    private func mapMessageType( // swiftlint:disable:this cyclomatic_complexity
        _ protoType: ProtoType,
        topLevelEnumTypes: inout [(EnumDescriptorProto, ProtoSyntax)]
    ) throws -> MapMessageTypeResult {
        switch protoType {
        case .primitive, .enumTy:
            fatalError("'\(#function)' called with non-top-level proto type \(protoType)")
        case .refdMessageType:
            // Shouldn't be a problem since this function only gets called for top-level types. riiiight?
            fatalError("'\(#function)' unexpectedly called with \(protoType)")
        case let .message(messageTypename, underlyingType, nestedOneofTypes, fields):
            let swiftTypeName: String?
            if let underlyingType = underlyingType {
                swiftTypeName = String(reflecting: underlyingType)
            } else {
                swiftTypeName = nil
            }
            self.protoNameToSwiftTypeMapping[messageTypename] = swiftTypeName

            let fieldNumbersMapping: [String: Int]
            if let protoCodableWithCodingKeysTy = underlyingType as? AnyProtobufTypeWithCustomFieldMapping.Type {
                let codingKeys = protoCodableWithCodingKeysTy.getCodingKeysType().allCases
                // intentionally not using the getProtoFieldNumber thing here,
                // bc we want the user to define int values
                // (and, in fact, require it so the force unwrap shouldn't be a problem anyway)
                fieldNumbersMapping = .init(uniqueKeysWithValues: codingKeys.map { ($0.stringValue, $0.intValue!) })
            } else {
                fieldNumbersMapping = .init(uniqueKeysWithValues: fields.map { ($0.name, $0.fieldNumber) })
            }
            var referencedTypes = Set<String>()
            let messageProtoSyntax: ProtoSyntax = (underlyingType as? Proto2Codable.Type != nil) ? .proto2 : .proto3
            let desc = DescriptorProto(
                // Same as with enums, we intentionally keep the full name so that the type containment handling works correctly.
                name: messageTypename.mangled,
                fields: fields.map { field -> FieldDescriptorProto in
                    FieldDescriptorProto(
                        name: field.name,
                        number: Int32(fieldNumbersMapping[field.name]!),
                        label: { () -> FieldDescriptorProto.Label? in
                            if field.isRepeated {
                                return .LABEL_REPEATED
                            } else if underlyingType as? Proto2Codable.Type != nil {
                                // the field belongs to a proto2 type
                                if field.isOptional {
                                    return .LABEL_OPTIONAL
                                } else {
                                    return .LABEL_REQUIRED
                                }
                            } else {
                                return nil
                            }
                        }(),
                        type: { () -> FieldDescriptorProto.FieldType? in
                            switch field.type {
                            case .primitive(let type):
                                return getProtoFieldType(type)
                            case .message, .refdMessageType:
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
                            case .message(let typename, _, _, _), .enumTy(let typename, _, _), .refdMessageType(let typename):
                                referencedTypes.insert(typename.fullyQualified)
                                return typename.fullyQualified
                            }
                        }(),
                        extendee: nil,
                        defaultValue: nil,
                        oneofIndex: { () -> Int32? in
                            // If set, gives the index of a oneof in the containing type's oneof_decl
                            // list.  This field is a member of that oneof.
                            if let containingOneofTy = field.containingOneof {
                                return Int32(nestedOneofTypes.firstIndex {
                                    ObjectIdentifier($0.underlyingType) == ObjectIdentifier(containingOneofTy)
                                }!)
                            } else {
                                return nil
                            }
                        }(),
                        jsonName: { () -> String? in
                            // JSON name of this field. The value is set by protocol compiler. If the
                            // user has set a "json_name" option on this field, that option's value
                            // will be used. Otherwise, it's deduced from the field's name by converting
                            // it to camelCase.
                            return nil
                        }(),
                        options: FieldOptions(
                            ctype: nil,
                            // The packed option can be enabled for repeated primitive fields to enable
                            // a more efficient representation on the wire. Rather than repeatedly
                            // writing the tag and type for each element, the entire array is encoded as
                            // a single length-delimited blob. In proto3, only explicit setting it to
                            // false will avoid using packed encoding.
                            packed: field.isPacked,
                            jsType: nil,
                            lazy: false,
                            deprecated: false,
                            weak: false,
                            uninterpretedOptions: []
                        ),
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
                        proto3Optional: (underlyingType as? Proto2Codable.Type == nil) && field.isOptional
                    )
                },
                extensions: [],
                nestedTypes: [],
                enumTypes: try { () -> [EnumDescriptorProto] in
                    // All enum types nested in this message.
                    // In contrast to nested messages, this is actually simple to obtain
                    // (because we first process enums, meaning that by the time we end up here, we already have all enums processed).
                    // Also, enums can't reference messages so we don't have to take anything else into account here.
                    let nestedEnumTypes = topLevelEnumTypes.filter { enumTypeDesc, _ in
                        guard let expectedParentTypename = getParentTypename(enumTypeDesc.name) else {
                            return false
                        }
                        return expectedParentTypename == messageTypename.mangled
                    }
                    for (enumTypeDesc, enumProtoSyntax) in nestedEnumTypes {
                        guard enumProtoSyntax == messageProtoSyntax else {
                            throw ProtoValidationError.invalidProto2AndProto3TypeNesting(
                                parent: messageTypename,
                                prospectiveChild: ProtoTypename(mangled: enumTypeDesc.name)
                            )
                        }
                    }
                    topLevelEnumTypes.subtract(nestedEnumTypes)
                    return nestedEnumTypes.map { enumTypeDesc, _ -> EnumDescriptorProto in
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
                            // Note: de-qualifying the oneof name here is only needed when using the enum typename,
                            // as opposed to using the @Property's name.
                            name: String(oneofType.name.split(separator: ".").last!),
                            options: nil
                        )
                    }
                }(),
                options: MessageOptions(
                    deprecated: false,
                    mapEntry: (underlyingType as? AnyProtobufMapFieldEntry.Type) != nil
                ),
                reservedRanges: { () -> [DescriptorProto.ReservedRange] in
                    guard let reserved = (underlyingType as? __ProtoTypeWithReservedFields.Type)?.reservedFields.allReservedFieldNumbers() else {
                        return []
                    }
                    var retval: [DescriptorProto.ReservedRange] = []
                    for idx in reserved.indices {
                        retval.append(.init(start: idx, end: idx))
                    }
                    for range in reserved.ranges {
                        retval.append(.init(start: range.lowerBound, end: range.upperBound))
                    }
                    return retval
                }(),
                reservedNames: (underlyingType as? __ProtoTypeWithReservedFields.Type)?.reservedFields.allReservedNames() ?? []
            )
            return .init(typeDescriptor: desc, protoSyntax: messageProtoSyntax, referencedTypes: referencedTypes)
        }
    }
}
