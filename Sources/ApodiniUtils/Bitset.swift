//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

// Extensions on `FixedWidthInteger` to make it act like a bitset
extension FixedWidthInteger {
    private func assertIsValidIndex(_ idx: Int) {
        precondition(
            idx >= 0 && idx < Self.bitWidth,
            "\(idx) is not a valid index for type '\(Self.self)' with bit width \(Self.bitWidth)"
        )
    }
    
    private func assertIsValidRange(_ range: Range<Int>) {
        assertIsValidIndex(range.lowerBound)
        assertIsValidIndex(range.upperBound)
    }
    
    
    /// Access the state of the bit at the specified index
    public subscript(bitAt idx: Int) -> Bool {
        get {
            assertIsValidIndex(idx)
            return (self & (1 << idx)) != 0
        }
        mutating set {
            if newValue {
                self |= 1 << idx
            } else {
                self &= ~(1 << idx)
            }
        }
    }
    
    /// Toggles the bit at `idx`
    public mutating func toggleBit(at idx: Int) {
        assertIsValidIndex(idx)
        self[bitAt: idx].toggle()
    }

    /// Replace the bits in the specified range with the equivalent bits (in terms of range) in the other bitset
    mutating func replaceBits(in range: Range<Int>, withEquivalentRangeIn otherBitset: Self) {
        assertIsValidRange(range)
        for idx in range {
            self[bitAt: idx] = otherBitset[bitAt: idx]
        }
    }
    
    /// Returns a string representation of the base-2 encoded integer value
    public var binaryString: String {
        (0..<Self.bitWidth).reduce(into: "") { string, idx in
            string += self[bitAt: idx] ? "1" : "0"
        }
    }
}
