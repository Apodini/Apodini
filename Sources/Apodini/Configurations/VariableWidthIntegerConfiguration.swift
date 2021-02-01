//
//  Created by Nityananda on 28.01.21.
//

/// A `Configuration` for the protocol buffer coding strategy of `FixedWidthInteger`s that depend on
/// the target architecture.
///
/// - **Example:**
///     Using `VariableWidthIntegerConfiguration.thirtyTwo` on a 64-bit architecture limits the
///     encoding and decoding of `Int`s and `UInts` to `Int32` and `UInt32`, respectively.
///     Disregarding their `.bitWidth` of 64.
///
///     The `.proto` file of the web service will only contain `int32` and `uint32` as well.
///
/// We assume only the most common architectures, 32 and 64-bit.
public enum VariableWidthIntegerConfiguration: Int, Configuration {
    case thirtyTwo = 32
    case sixtyFour = 64
    
    // MARK: Nested Types
    enum Key: StorageKey {
        typealias Value = VariableWidthIntegerConfiguration
    }
    
    // MARK: Methods
    public func configure(_ app: Application) {
        guard rawValue <= Int.bitWidth else {
            preconditionFailure(
                """
                \(self) requires architecture to have a wider integer bit width. \
                Try using a smaller option.
                """
            )
        }
        
        app.storage[Key.self] = self
    }
}
