//import Foundation
//import Runtime
//import ApodiniDeployBuildSupport
//
//
//protocol LKCodableEnumWithAssociatedValues_old: Codable {
//    associatedtype Discriminant: Codable
//    
//    init?(lk_unsafeWithDiscriminant discriminant: Discriminant, value: Decodable)
//    // The current instance's discriminant
//    func lk_currentDiscriminant() -> Discriminant
//    // The type associated w/ the discriminant
//    static func lk_assocValuesType(forDiscriminant discriminant: Discriminant) -> Codable.Type
//}
//
//
//
//enum LKCodableEnumWithAssociatedValuesCodingKeys_old: CodingKey {
//    case discriminant
//    case encodedValue
//}
//
//
//
//extension Encodable {
//    func lk_toJsonData() throws -> Data {
//        try JSONEncoder().encode(self)
//    }
//}
//
//
//extension Decodable {
//    static func lk_fromJsonData(_ data: Data) throws -> Self {
//        try JSONDecoder().decode(Self.self, from: data)
//    }
//}
//
//
//
//extension LKCodableEnumWithAssociatedValues_old {
//    public init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: LKCodableEnumWithAssociatedValuesCodingKeys_old.self)
//        let discriminant = try container.decode(Discriminant.self, forKey: .discriminant)
//        let encodedValue = try container.decode(Data.self, forKey: .encodedValue)
//        let assocType: Decodable.Type = Self.lk_assocValuesType(forDiscriminant: discriminant)
//        let assocValue = try assocType.lk_fromJsonData(encodedValue)
//        if let selfObj = Self.init(lk_unsafeWithDiscriminant: discriminant, value: assocValue) {
//            self = selfObj
//        } else {
//            throw NSError.apodiniDeploy(localizedDescription: "Unable to instantiate enum instance from decoder. Enum type: '\(Self.self)'.")
//        }
//    }
//    
//    
//    func encode(to encoder: Encoder) throws {
////        var container = encoder.container(keyedBy: LKCodableEnumWithAssociatedValuesCodingKeys.self)
////        //try container.encode(, forKey: <#T##KeyedEncodingContainer<LKCodableEnumWithAssociatedValuesCodingKeys>.Key#>)
////        let TI = try typeInfo(of: Self.self)
////        print(TI)
//        
//        fatalError()
//    }
//}
//
//
////extension ProcessedHandlerDependencyElement: Codable {
////    public init(from decoder: Decoder) throws {
////        <#code#>
////    }
////}
//
//
//
//
////public enum ProcessedHandlerDependencyElement: LKCodableEnumWithAssociatedValues {
////    enum Discriminant: String, Codable { // String, Int, whatever. only thing that matters is that its stable
////        case handlerId, handlerType
////    }
////
////    case handlerId(String)
////    case handlerType(String)
////
////    init?(lk_unsafeWithDiscriminant discriminant: Discriminant, value: Decodable) {
////        switch discriminant {
////        case .handlerId:
////            self = .handlerId(value as! String)
////        case .handlerType:
////            self = .handlerId(value as! String)
////        }
////    }
////
////    static func assocValuesType(forDiscriminant discriminant: Discriminant) -> Codable.Type {
////        switch discriminant {
////        case .handlerId, .handlerType:
////            return String.self
////        default:
////            fatalError()
////        }
////    }
////}
//
//
//
//public struct ProcessedHandlerDependency: Codable {
//    //let source: ProcessedHandlerDependencyElement
//    //let target: [ProcessedHandlerDependencyElement]
//}
//
//
//
//
//
//
//
//
//
//
//
//
//protocol LKCodableEnumWithAssociatedValues: Codable {}
//
//extension LKCodableEnumWithAssociatedValues {
//    init(from decoder: Decoder) throws {
//        let TI = try typeInfo(of: Self.self)
//        precondition(TI.kind == .enum) // guard
//        
//        let x = try Runtime.createInstance(of: Self.self) { PI -> Any in
//            print("OWOOO CTOR", PI)
//        }
//        print("x", x)
//        
//        var container = try decoder.unkeyedContainer()
//        let caseName = try container.decode(String.self)
//        
//        let caseInfo = TI.cases.first(where: { $0.name == caseName })!
//        guard let assocValueTy = caseInfo.payloadType else {
//            // if there's no assoc type info, the case does not have an associated type
//            fatalError()
//        }
//        fatalError()
//    }
//}
//
//
//
//
//
//
//
//
//
//enum Barcode: LKCodableEnumWithAssociatedValues, Equatable {
////enum Barcode {
//    case ugh
//    case qr(String)
//    case custom1(Int)
//    case custom2(Bool, Int)
//    case ean(Data)
//}
//
//
//
//let TI = try typeInfo(of: Barcode.self)
//precondition(TI.kind == .enum)
//print("numberOfEnumCases", TI.numberOfEnumCases)
//print("numberOfPayloadEnumCases", TI.numberOfPayloadEnumCases)
//
//
//for enumCase in TI.cases {
//    print(enumCase.name, enumCase.payloadType)
//}
//
//
//
//
//let testObjects: [Barcode] = [
//    .ugh, .custom1(123), .custom1(456), .custom1(914), .custom2(true, 12222), .custom2(false, -1), .ean(Data([1, 2, 3, 4, 5, 6]))
//]
//
//
//
//let encoded = testObjects.map { try! JSONEncoder().encode($0) }
//let decoded = encoded.map { try! JSONDecoder().decode(Barcode.self, from: $0) }
//precondition(encoded == decoded)
//
//
//
//fatalError()
