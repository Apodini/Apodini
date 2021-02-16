//
//  Bitset.swift
//
//
//  Created by Lukas Kollmer on 16.02.21.
//

// TODO turn this into a proper bitset type?

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
    
    
    public subscript(lk_bitAt idx: Int) -> Bool {
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

    mutating public func lk_toggleBit(at idx: Int) {
        assertIsValidIndex(idx)
        self[lk_bitAt: idx].toggle()
    }

    
    mutating func lk_replaceBits(in range: Range<Int>, withEquivalentRangeIn otherBitfield: Self) {
        assertIsValidRange(range)
        for idx in range {
            self[lk_bitAt: idx] = otherBitfield[lk_bitAt: idx]
        }
//        self = (self & )
    }
    
    
    public var lk_binaryString: String {
        return (0..<Self.bitWidth).reduce(into: "") { string, idx in
            string += self[lk_bitAt: idx] ? "1" : "0"
        }
    }
}

