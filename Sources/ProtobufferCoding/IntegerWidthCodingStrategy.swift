//
//  Created by Nityananda on 31.01.21.
//

/// `IntegerWidthCodingStrategy` may be used to override a protocol buffers coder's strategy
/// for en/decoding `Int`s and `UInt`s.
public enum IntegerWidthCodingStrategy {
    /// `Int`s and `UInt`s are encoded with a 32 bit wide field.
    case thirtyTwo
    /// `Int`s and `UInt`s are encoded with a 64 bit wide field.
    case sixtyFour
}
