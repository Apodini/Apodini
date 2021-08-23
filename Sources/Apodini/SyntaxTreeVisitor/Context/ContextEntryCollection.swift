//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

/// A type erased version of `ContextEntryCollection`.
protocol AnyContextEntryCollection {
    /// Append a `AnyContextEntry` to the collection.
    /// - Parameters:
    ///   - entry: The `AnyContextEntry` to be added.
    ///   - derivedFromModifier: Defines if the supplied `AnyContextEntry`
    func add(entry: AnyContextEntry, derivedFromModifier: Bool)

    /// This method joins all `AnyContextEntry`s in the collection.
    /// - Returns: The resulting `AnyContextEntry` containing all entries of the entries of this collection.
    func joined() -> AnyContextEntry
}

/// A `ContextEntryCollection` represents a collection of `ContextEntry`s for a given `OptionalContextKey`.
class ContextEntryCollection<Key: OptionalContextKey>: AnyContextEntryCollection {
    var entries: [ContextEntry<Key>] = []
    /// `ContextEntry`s of Modifiers are collected separately to restore ordering
    /// once parsing is finished.
    var modifierEntries: [ContextEntry<Key>] = []

    init(entry: AnyContextEntry, derivedFromModifier: Bool) {
        add(entry: entry, derivedFromModifier: derivedFromModifier)
    }

    func add(entry: AnyContextEntry, derivedFromModifier: Bool) {
        guard let castedEntry = entry as? ContextEntry<Key> else {
            fatalError("Tried adding entry of type \(type(of: entry)) to collection when expected type was \(ContextEntry<Key>.self)")
        }

        if derivedFromModifier {
            modifierEntries.append(castedEntry)
        } else {
            entries.append(castedEntry)
        }
    }

    func joined() -> AnyContextEntry {
        let entries = self.entries + modifierEntries.reversed()

        guard var entry: AnyContextEntry = entries.first else {
            fatalError("Found inconsistency. \(Self.self) found to be empty!")
        }

        for index in 1 ..< entries.count {
            entry = entry.join(with: entries[index], filterForLocalScope: false)
        }

        return entry
    }
}
