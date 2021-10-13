//
// Created by Andreas Bauer on 21.06.21.
//


/// This protocol represents a type erased `Array`.
public protocol AnyArray: RangeReplaceableCollection, RandomAccessCollection, MutableCollection {}

extension Array: AnyArray {}
