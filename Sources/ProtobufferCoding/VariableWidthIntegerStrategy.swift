//
//  Created by Nityananda on 31.01.21.
//

/// `VariableWidthIntegerStrategy` may be used to override `ProtobufferEncoder`s encoding strategy
/// for `Int`s and `UInt`s.
public enum VariableWidthIntegerStrategy {
    /// `Int`s and `UInt`s are encoded with a 32 bit wide field.
    case thirtyTwo
    /// `Int`s and `UInt`s are encoded with a 64 bit wide field.
    case sixtyFour
}
