//
//  Bitset.swift
//
//
//  Created by Lukas Kollmer on 16.02.21.
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

    mutating public func toggleBit(at idx: Int) {
        assertIsValidIndex(idx)
        self[bitAt: idx].toggle()
    }

    
    mutating func replaceBits(in range: Range<Int>, withEquivalentRangeIn otherBitfield: Self) {
        assertIsValidRange(range)
        for idx in range {
            self[bitAt: idx] = otherBitfield[bitAt: idx]
        }
    }
    
    
    public var binaryString: String {
        return (0..<Self.bitWidth).reduce(into: "") { string, idx in
            string += self[bitAt: idx] ? "1" : "0"
        }
    }
}

