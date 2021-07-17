//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//    

/// A single captures context value with its respective `Scope`.

struct ContextValueEntry<Key: OptionalContextKey> {
    let value: Key.Value
    let scope: Scope
}

/// Type erased version of a `ContextEntry`.
protocol AnyContextEntry {
    /// Adds a new context value.
    /// - Parameters:
    ///   - value: The value which should be added. The Type must match the expected Type of the `OptionalContextKey`.
    ///   - scope: The `Scope` in which the value should be captured.
    func add(value: Any, in scope: Scope)

    /// Filters all local only context values of the `AnyContextEntry`.
    /// - Returns: Returns a new `AnyContextEntry` containing only context value captured in
    ///     `Scope.environment` scope. If the entry doesn't contain any global values, nil is returned.
    func filterLocalValues() -> AnyContextEntry?

    /// Joins the given `ContextEntry` with the passed `ContextEntry`.
    /// The self entry acts as the left hand side `ContextEntry`.
    ///
    /// - Parameters:
    ///   - rhs: The right hand side `AnyContextEntry`.
    ///   - filterForLocalScope: Specifies if the left hand side (or the local entry) should
    ///     be filtered for local scoped values.
    /// - Returns: A new instance of `AnyContextEntry` combining both `AnyContextEntry` according to the supplied parameters.
    func join(with rhs: AnyContextEntry, filterForLocalScope: Bool) -> AnyContextEntry

    /// Reduces all collected context keys according to the respective `OptionalContextKey.reduce(...)`.
    /// - Returns: Returns the reduced value of the respective `OptionalContextKey.Value` type.
    func reduce() -> Any

    /// Creates a new `ContextEntryCollection` with expected generic typing.
    /// - Parameters:
    ///   - entry: The initial entry which should be added
    ///   - derivedFromModifier: Defines if the initial entry is derived from a `Modifier`.
    /// - Returns: Returns the created instance of a `ContextEntryCollection`, added with a initial `AnyContextEntry`.
    func deriveCollection(entry: AnyContextEntry, derivedFromModifier: Bool) -> AnyContextEntryCollection
}

/// A `ContextEntry` represents all collected values of a specific `OptionalContextKey`.
/// All values of a `OptionalContextKey` captured inside a `Component` are captured inside a single `ContextEntry`
class ContextEntry<Key: OptionalContextKey>: AnyContextEntry {
    var values: [ContextValueEntry<Key>]

    init(_ values: [ContextValueEntry<Key>]) {
        self.values = values
        precondition(!values.isEmpty, "\(type(of: self)) was created with empty values!")
    }

    convenience init(value: Key.Value, scope: Scope) {
        self.init([ContextValueEntry<Key>(value: value, scope: scope)])
    }

    func add(value: Any, in scope: Scope) {
        guard let castedValue = value as? Key.Value else {
            fatalError("Tried to add context entry with differing value type, expected \(Key.Value.self) got \(type(of: value)))")
        }

        values.append(ContextValueEntry(value: castedValue, scope: scope))
    }

    func filterLocalValues() -> AnyContextEntry? {
        let globalValues = values.filter { $0.scope == .environment }
        return !globalValues.isEmpty ? ContextEntry(globalValues) : nil
    }

    func join(with rhs: AnyContextEntry, filterForLocalScope: Bool) -> AnyContextEntry {
        guard let selfRHS = rhs as? Self else {
            fatalError("RHS with type \(type(of: rhs)) doesn't match in type with \(Self.self)")
        }

        let lhsValues = filterForLocalScope
            ? values.filter { $0.scope == .environment }
            : values

        return ContextEntry(lhsValues + selfRHS.values)
    }

    func reduce() -> Any {
        guard var value = values.first?.value else {
            // we guarantee in the initializer that values won't ever be empty
            fatalError("Found inconsistency. \(type(of: self)) was found with empty values array.")
        }

        if let collectionEntry = self as? EntryWithRangeReplaceableCollectionEntry {
            for index in 1 ..< values.count {
                collectionEntry.collectionReduce(value: &value, nextValue: values[index].value)
            }
        } else {
            for index in 1 ..< values.count {
                Key.reduce(value: &value, nextValue: values[index].value)
            }
        }

        return value
    }

    func deriveCollection(entry: AnyContextEntry, derivedFromModifier: Bool) -> AnyContextEntryCollection {
        ContextEntryCollection<Key>(entry: entry, derivedFromModifier: derivedFromModifier)
    }
}

// MARK: ContextKey With Array based Value

private protocol EntryWithRangeReplaceableCollectionEntry {
    func collectionReduce<T>( value: inout T, nextValue: T)
}

extension ContextEntry: EntryWithRangeReplaceableCollectionEntry where Key.Value: AnyArray {
    func collectionReduce<T>( value: inout T, nextValue: T) {
        guard var castedValue = value as? Key.Value, let castedNextValue = nextValue as? Key.Value else {
            fatalError("Failed to cast either \(T.self) to expected type \(Key.Value.self)")
        }

        Key.reduce(value: &castedValue, nextValue: castedNextValue)

        guard let result = castedValue as? T else {
            fatalError("Failed to reverse type cast from \(Key.Value.self) to \(T.self)")
        }

        value = result
    }
}
