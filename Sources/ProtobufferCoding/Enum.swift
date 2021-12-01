import Foundation


public protocol AnyProtobufEnum: __ProtoTypeWithReservedFields {
    static var allCases: [Self] { get }
    var rawValue: Int32 { get }
}


/// A Swift enum type which can be stored into protobuffer messages.
public protocol ProtobufEnum: AnyProtobufEnum, Codable, CaseIterable, RawRepresentable where RawValue == Int32 {}
