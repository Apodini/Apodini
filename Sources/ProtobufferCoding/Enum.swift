import Foundation


public protocol AnyProtobufEnum {
    static var allCases: [Self] { get }
    var rawValue: Int32 { get }
    static var reservedRanges: Set<ClosedRange<Int32>> { get }
    static var reservedNames: Set<String> { get }
}


/// A Swift enum type which can be stored into protobuffer messages.
public protocol ProtobufEnum: AnyProtobufEnum, Codable, CaseIterable, RawRepresentable where RawValue == Int32 {}


public extension ProtobufEnum {
    static var reservedRanges: Set<ClosedRange<Int32>> { [] }
    static var reservedNames: Set<String> { [] }
}
