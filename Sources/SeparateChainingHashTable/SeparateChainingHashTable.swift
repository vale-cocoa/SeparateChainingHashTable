//
//  SeparateChainingHashTable.swift
//  SeparateChainingHashTable
//
//  Created by Valeriano Della Longa on 2021/02/14.
//  Copyright © 2021 Valeriano Della Longa
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use, copy,
//  modify, merge, publish, distribute, sublicense, and/or sell copies
//  of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
//  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
//  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//
import Foundation

/// A collection whose elements are key-value pairs, stored via a separate chaining hash table.
///
/// `SeparateChainingHashTable` shares the same functionalities
/// of Swift `Dictionary`, except for invalidating its `Indicies` every time
/// a call to a mutating method was done —no matter if a mutation has really took effect or not.
/// - ToDo: Add `CustomStringConvertible` and
///         `CustomDebugStringConvertible` conformances.
public struct SeparateChainingHashTable<Key: Hashable, Value> {
    /// The element type of an hash table: a tuple containing an individual
    /// key-value pair.
    public typealias Element = (key: Key, value: Value)
    
    private(set) var buffer: HashTableBuffer<Key, Value>? = nil
    
    private(set) var id = ID()
    
    /// The total number of key-value pairs that the hash table can contain without
    /// allocating new storage.
    ///
    /// - Complexity: O(1)
    @inline(__always)
    public var capacity: Int { buffer?.capacity ?? 0 }
    
    /// The number of key-value pairs in the hash table.
    ///
    /// - Complexity: O(1).
    @inline(__always)
    public var count: Int { buffer?.count ?? 0 }
    
    /// A Boolean value that indicates whether the hash table is empty.
    ///
    /// Hash table are empty when created with an initializer or an empty
    /// dictionary literal.
    ///
    ///     var frequencies: SeparateChainingHashTable<String, Int> = [:]
    ///     print(frequencies.isEmpty)
    ///     // Prints "true"
    ///
    /// - Complexity: O(1).
    @inline(__always)
    public var isEmpty: Bool { buffer?.isEmpty ?? true }
    
    /// A collection containing just the keys of the hash table.
    ///
    /// When iterated over, keys appear in this collection in the same order as
    /// they occur in the hash table's key-value pairs. Each key in the keys
    /// collection has a unique value.
    ///
    ///     let countryCodes: SeparateChainingHashTable<String, String> = ["BR": "Brazil", "GH": "Ghana", "JP": "Japan"]
    ///     print(countryCodes)
    ///     // Prints "["BR": "Brazil", "JP": "Japan", "GH": "Ghana"]"
    ///
    ///     for k in countryCodes.keys {
    ///         print(k)
    ///     }
    ///     // Prints "BR"
    ///     // Prints "JP"
    ///     // Prints "GH"
    ///
    /// - Complexity: O(*n*) where *n* is lenght of this hash table.
    @inline(__always)
    public var keys: Keys { Keys(self) }
    
    /// A collection containing just the values of the hash table.
    ///
    /// When iterated over, values appear in this collection in the same order as
    /// they occur in the hash table's key-value pairs.
    ///
    ///     let countryCodes: SeparateChainingHashTable<String, String> = ["BR": "Brazil", "GH": "Ghana", "JP": "Japan"]
    ///     print(countryCodes)
    ///     // Prints "["BR": "Brazil", "JP": "Japan", "GH": "Ghana"]"
    ///
    ///     for v in countryCodes.values {
    ///         print(v)
    ///     }
    ///     // Prints "Brazil"
    ///     // Prints "Japan"
    ///     // Prints "Ghana"
    ///
    /// - Complexity: O(*n*) where *n* is lenght of this hash table.
    @inline(__always)
    public var values: Values {
        get { Values(self) }
        
        _modify {
            var values = Values(Self())
            swap(&values.ht, &self)
            defer {
                self = values.ht
            }
            yield &values
        }
    }
    
    @inline(__always)
    fileprivate var freeCapacity: Int { capacity - count }
    
    @inline(__always)
    fileprivate static var minBufferCapacity: Int {
        HashTableBuffer<Key, Value>.minTableCapacity
    }
    
    /// Creates an empty hash table.
    public init() {  }
    
    /// Creates an empty hash table with preallocated space for at least the
    /// specified number of elements.
    ///
    /// Use this initializer to avoid intermediate reallocations of an hash table's
    /// storage buffer when you know how many key-value pairs you are adding to an
    /// hash table after creation.
    ///
    /// - Parameter minimumCapacity: The minimum number of key-value pairs that
    ///   the newly created hash table should be able to store without
    ///   reallocating its storage buffer.
    public init(minimumCapacity k: Int) {
        precondition(k >= 0, "minimumCapacity must not be negative")
        guard k > 0 else { return }
        
        let minimumCapacity = Swift.max(Self.minBufferCapacity, k)
        
        self.buffer = HashTableBuffer(minimumCapacity: minimumCapacity)
    }
    
    /// Creates a new hash table from the key-value pairs in the given sequence.
    ///
    /// You use this initializer to create an hash table when you have a sequence
    /// of key-value tuples with unique keys. Passing a sequence with duplicate
    /// keys to this initializer results in a runtime error. If your
    /// sequence might have duplicate keys, use the
    /// `init(_:uniquingKeysWith:)` initializer instead.
    ///
    /// The following example creates a new hash table using an array of strings
    /// as the keys and the integers in a countable range as the values:
    ///
    ///     let digitWords = ["one", "two", "three", "four", "five"]
    ///     let wordToValue = SeparateChainingHAshTable(uniqueKeysWithValues: zip(digitWords, 1...5))
    ///     print(wordToValue["three"]!)
    ///     // Prints "3"
    ///     print(wordToValue)
    ///     // Prints "["three": 3, "four": 4, "five": 5, "one": 1, "two": 2]"
    ///
    /// - Parameter keysAndValues: A sequence of key-value pairs to use for
    ///   the new hash table. Every key in `keysAndValues` must be unique.
    /// - Returns: A new hash table initialized with the elements of
    ///   `keysAndValues`.
    /// - Precondition: The sequence must not have duplicate keys.
    public init<S: Sequence>(uniqueKeysWithValues keysAndValues: S) where S.Iterator.Element == (Key, Value) {
        if let other = keysAndValues as? SeparateChainingHashTable<Key, Value> {
            self.init(other)
            
            return
        }
        
        self.init(keysAndValues) { _, _ in
            preconditionFailure("keys must be unique")
        }
    }
    
    /// Creates a new hash table from the key-value pairs in the given sequence,
    /// using a combining closure to determine the value for any duplicate keys.
    ///
    /// You use this initializer to create an hash table when you have a sequence
    /// of key-value tuples that might have duplicate keys. As the hash table is
    /// built, the initializer calls the `combine` closure with the current and
    /// new values for any duplicate keys. Pass a closure as `combine` that
    /// returns the value to use in the resulting hash table: the closure can
    /// choose between the two values, combine them to produce a new value, or
    /// even throw an error.
    ///
    /// The following example shows how to choose the first and last values for
    /// any duplicate keys:
    ///
    ///     let pairsWithDuplicateKeys = [("a", 1), ("b", 2), ("a", 3), ("b", 4)]
    ///
    ///     let firstValues = SeparateChainingHashTable(pairsWithDuplicateKeys,
    ///                                  uniquingKeysWith: { (first, _) in first })
    ///     // ["b": 2, "a": 1]
    ///
    ///     let lastValues = Dictionary(pairsWithDuplicateKeys,
    ///                                 uniquingKeysWith: { (_, last) in last })
    ///     // ["b": 4, "a": 3]
    ///
    /// - Parameters:
    ///   - keysAndValues:  A sequence of key-value pairs to use for
    ///                     the new hash table
    ///   - combine:    A closure that is called with the values for any
    ///                 duplicate keys that are encountered.
    ///                 The closure returns the desired value for the final hash table.
    public init<S>(_ keysAndValues: S, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows where S : Sequence, S.Iterator.Element == (Key, Value) {
        if let other = keysAndValues as? SeparateChainingHashTable<Key, Value> {
            self.init(other)
            
            return
        }
        
        var newBuffer: HashTableBuffer<Key, Value>? = nil
        let done: Bool = try keysAndValues
            .withContiguousStorageIfAvailable { kvBuffer in
                guard
                    kvBuffer.baseAddress != nil && kvBuffer.count > 0
                else { return true }
                
                newBuffer = HashTableBuffer(minimumCapacity: Swift.max(Self.minBufferCapacity, (kvBuffer.count * 3) / 2))
                for (key, value) in keysAndValues {
                    try newBuffer!.setValue(value, forKey: key, uniquingKeysWith: combine)
                }
                
                return true
            } ?? false
        if !done {
            var kvIter = keysAndValues.makeIterator()
            if let (firstKey, firstValue) = kvIter.next() {
                newBuffer = HashTableBuffer(minimumCapacity: Swift.max(Self.minBufferCapacity, (keysAndValues.underestimatedCount * 3) / 2))
                try newBuffer!.setValue(firstValue, forKey: firstKey, uniquingKeysWith: combine)
                while let (key, value) = kvIter.next() {
                    try newBuffer!.setValue(value, forKey: key, uniquingKeysWith: combine)
                    if newBuffer!.tableIsTooTight {
                        newBuffer!.resizeTo(newCapacity: newBuffer!.capacity * 2)
                    }
                }
            }
            
        }
        self.init(buffer: newBuffer)
    }
    
    /// Creates a new hash table whose keys are the groupings returned by the
    /// given closure and whose values are arrays of the elements that returned
    /// each key.
    ///
    /// The arrays in the "values" position of the new hash table each contain at
    /// least one element, with the elements in the same order as the source
    /// sequence.
    ///
    /// The following example declares an array of names, and then creates an
    /// hash table from that array by grouping the names by first letter:
    ///
    ///     let students = ["Kofi", "Abena", "Efua", "Kweku", "Akosua"]
    ///     let studentsByLetter = SeparateChainingHashTable(grouping: students, by: { $0.first! })
    ///     // ["E": ["Efua"], "K": ["Kofi", "Kweku"], "A": ["Abena", "Akosua"]]
    ///
    /// The new `studentsByLetter` hash table has three entries, with students'
    /// names grouped by the keys `"E"`, `"K"`, and `"A"`.
    ///
    /// - Parameters:
    ///   - values: A sequence of values to group into an hash table.
    ///   - keyForValue: A closure that returns a key for each element in
    ///     `values`.
    public init<S>(grouping values: S, by keyForValue: (S.Element) throws -> Key) rethrows where Value == [S.Element], S : Sequence {
        var newBuffer: HashTableBuffer<Key, Value>? = nil
        let done: Bool = try values
            .withContiguousStorageIfAvailable { vBuff in
                guard
                    vBuff.baseAddress != nil && vBuff.count > 0
                else { return true }
                newBuffer = HashTableBuffer(minimumCapacity: (vBuff.count * 3) / 2)
                for v in vBuff {
                    let k = try keyForValue(v)
                    newBuffer!.setValue([v], forKey: k, uniquingKeysWith: +)
                }
                
                return true
            } ?? false
        
        if !done {
            var valuesIter = values.makeIterator()
            if let firstValue = valuesIter.next() {
                newBuffer = HashTableBuffer(minimumCapacity: Swift.max(Self.minBufferCapacity, (values.underestimatedCount * 3) / 2))
                let fKey = try keyForValue(firstValue)
                newBuffer!.setValue([firstValue], forKey: fKey, uniquingKeysWith: +)
                while let value = valuesIter.next() {
                    let key = try keyForValue(value)
                    newBuffer!.setValue([value], forKey: key, uniquingKeysWith: +)
                    if newBuffer!.tableIsTooTight {
                        newBuffer!.resizeTo(newCapacity: newBuffer!.capacity * 2)
                    }
                }
            }
        }
        
        self.init(buffer: newBuffer)
    }
    
    fileprivate init(_ other: SeparateChainingHashTable) {
        self.init(buffer: other.buffer)
    }
    
    fileprivate init(buffer: HashTableBuffer<Key, Value>?) {
        self.buffer = buffer
    }
    
}

// MARK: - C.R.U.D. methods
extension SeparateChainingHashTable {
    /// Accesses the value associated with the given key for reading and writing.
    ///
    /// This *key-based* subscript returns the value for the given key if the key
    /// is found in the hash table, or `nil` if the key is not found.
    /// The setter of this subscript might invalidate all indices of the hash table.
    ///
    /// The following example creates a new hash table and prints the value of a
    /// key found in the has table (`"Coral"`) and a key not found in the
    /// hash table (`"Cerise"`).
    ///
    ///     var hues: SepartateChainingHashTable<String, Int> = ["Heliotrope": 296, "Coral": 16, "Aquamarine": 156]
    ///     print(hues["Coral"])
    ///     // Prints "Optional(16)"
    ///     print(hues["Cerise"])
    ///     // Prints "nil"
    ///
    /// When you assign a value for a key and that key already exists, the
    /// hash table overwrites the existing value. If the hash table doesn't
    /// contain the key, the key and value are added as a new key-value pair.
    ///
    /// Here, the value for the key `"Coral"` is updated from `16` to `18` and a
    /// new key-value pair is added for the key `"Cerise"`.
    ///
    ///     hues["Coral"] = 18
    ///     print(hues["Coral"])
    ///     // Prints "Optional(18)"
    ///
    ///     hues["Cerise"] = 330
    ///     print(hues["Cerise"])
    ///     // Prints "Optional(330)"
    ///
    /// If you assign `nil` as the value for the given key, the hash table
    /// removes that key and its associated value.
    ///
    /// In the following example, the key-value pair for the key `"Aquamarine"`
    /// is removed from the hash table by assigning `nil` to the key-based
    /// subscript.
    ///
    ///     hues["Aquamarine"] = nil
    ///     print(hues)
    ///     // Prints "["Coral": 18, "Heliotrope": 296, "Cerise": 330]"
    ///
    /// - Parameter key: The key to find in the hash table.
    /// - Returns: The value associated with `key` if `key` is in the hash table;
    ///   otherwise, `nil`.
    public subscript(_ k: Key) -> Value? {
        get { getValue(forKey: k) }
        
        mutating set {
            guard let v = newValue else {
                removeValue(forKey: k)
                
                return
            }
            
            updateValue(v, forKey: k)
        }
    }
    
    /// Accesses the value with the given key. If the hash table doesn't contain
    /// the given key, accesses the provided default value as if the key and
    /// default value existed in the hash table.
    ///
    /// Use this subscript when you want either the value for a particular key
    /// or, when that key is not present in the hash table, a default value.
    /// The setter of this subscript might invalidate all indices of the hash table.
    /// This example uses the subscript with a message to use in case an HTTP response
    /// code isn't recognized:
    ///
    ///     var responseMessages: SeparateChainingHashTable<Int, String> = [
    ///         200: "OK",
    ///         403: "Access forbidden",
    ///         404: "File not found",
    ///         500: "Internal server error"
    ///     ]
    ///
    ///     let httpResponseCodes = [200, 403, 301]
    ///     for code in httpResponseCodes {
    ///         let message = responseMessages[code, default: "Unknown response"]
    ///         print("Response \(code): \(message)")
    ///     }
    ///     // Prints "Response 200: OK"
    ///     // Prints "Response 403: Access Forbidden"
    ///     // Prints "Response 301: Unknown response"
    ///
    /// When an hash table's `Value` type has value semantics, you can use this
    /// subscript to perform in-place operations on values in the hash table.
    /// The following example uses this subscript while counting the occurrences
    /// of each letter in a string:
    ///
    ///     let message = "Hello, Elle!"
    ///     var letterCounts: SeparateChainingHashTable<Character, Int> = [:]
    ///     for letter in message {
    ///         letterCounts[letter, default: 0] += 1
    ///     }
    ///     // letterCounts == ["H": 1, "e": 2, "l": 4, "o": 1, ...]
    ///
    /// When `letterCounts[letter, defaultValue: 0] += 1` is executed with a
    /// value of `letter` that isn't already a key in `letterCounts`, the
    /// specified default value (`0`) is returned from the subscript,
    /// incremented, and then added to the hash table under that key.
    ///
    /// - Note: Do not use this subscript to modify hash table values if the
    ///   dictionary's `Value` type is a class. In that case, the default value
    ///   and key are not written back to the hash table after an operation.
    ///
    /// - Parameters:
    ///   - key: The key to look up in the hash table.
    ///   - defaultValue:   The default value to use if `key` doesn't exist
    ///                     in the hash table.
    /// - Returns:  The value associated with `key` in the hash table;
    ///             otherwise, `defaultValue`.
    public subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
        get {
            buffer?.getValue(forKey: key) ?? defaultValue()
        }
        
        mutating set {
            updateValue(newValue, forKey: key)
        }
    }
    
    /// Returns the value associated to the the given key. If such key doesn't exists in the hash
    /// table, then returns `nil`.
    ///
    /// - Parameter forKey: The key to lookup in the hash table.
    /// - Returns:  The value associated to the given key, if such key exists in the
    ///             hash table; otherwise `nil`.
    public func getValue(forKey k: Key) -> Value? {
        buffer?.getValue(forKey: k)
    }
    
    /// Updates the value stored in the hash table for the given key, or adds a
    /// new key-value pair if the key does not exist.
    ///
    /// Use this method instead of key-based subscripting when you need to know
    /// whether the new value supplants the value of an existing key. If the
    /// value of an existing key is updated, `updateValue(_:forKey:)` returns
    /// the original value. This method might invalidate all indices of the hash table.
    ///
    ///     var hues: SeparateChainingHashTable<String, Int> = ["Heliotrope": 296, "Coral": 16, "Aquamarine": 156]
    ///
    ///     if let oldValue = hues.updateValue(18, forKey: "Coral") {
    ///         print("The old value of \(oldValue) was replaced with a new one.")
    ///     }
    ///     // Prints "The old value of 16 was replaced with a new one."
    ///
    /// If the given key is not present in the hash table, this method adds the
    /// key-value pair and returns `nil`.
    ///
    ///     if let oldValue = hues.updateValue(330, forKey: "Cerise") {
    ///         print("The old value of \(oldValue) was replaced with a new one.")
    ///     } else {
    ///         print("No value was found in the hash table for that key.")
    ///     }
    ///     // Prints "No value was found in the hash table for that key."
    ///
    /// - Parameters:
    ///   - value: The new value to add to the hash table.
    ///   - key:    The key to associate with `value`. If `key` already exists in
    ///             the hash table, `value` replaces the existing associated value.
    ///             If `key` isn't already a key of the hash table,
    ///             the `(key, value)` pair is added.
    /// - Returns:  The value that was replaced, or `nil` if a new key-value pair
    ///             was added.
    @discardableResult
    public mutating func updateValue(_ v: Value, forKey k: Key) -> Value? {
        makeUniqueEventuallyIncreasingCapacity()
        
        return buffer!.updateValue(v, forKey: k)
    }
    
    /// Removes the given key and its associated value from the hash table.
    ///
    /// If the key is found in the hash table, this method returns the key's
    /// associated value. This method invalidates all indices of the hash table.
    ///
    ///     var hues: SeparateChainingHashTable<String, Int> = ["Heliotrope": 296, "Coral": 16, "Aquamarine": 156]
    ///     if let value = hues.removeValue(forKey: "Coral") {
    ///         print("The value \(value) was removed.")
    ///     }
    ///     // Prints "The value 16 was removed."
    ///
    /// If the key isn't found in the hash table, `removeValue(forKey:)` returns
    /// `nil`.
    ///
    ///     if let value = hues.removeValueForKey("Cerise") {
    ///         print("The value \(value) was removed.")
    ///     } else {
    ///         print("No value found for that key.")
    ///     }
    ///     // Prints "No value found for that key.""
    ///
    /// - Parameter key: The key to remove along with its associated value.
    /// - Returns:  The value that was removed, or `nil` if the key was not
    ///             present in the hash table.
    ///
    /// - Complexity: Amortized O(1).
    @discardableResult
    public mutating func removeValue(forKey k: Key) -> Value? {
        makeUniqueEventuallyReducingCapacity()
        
        return buffer?.removeElement(withKey: k)
    }
    
    /// Removes all key-value pairs from the hash table.
    ///
    /// Calling this method invalidates all indices of the hash table.
    ///
    /// - Parameter keepCapacity:   Whether the hash table should keep its
    ///                             underlying buffer.
    ///                             If you pass `true`, the operation
    ///                             preserves the buffer capacity that
    ///                             the collection has, otherwise the underlying
    ///                             buffer is released.  The default is `false`.
    ///
    /// - Complexity: Amortized O(*n*), where *n* is the lenght of the hash table.
    public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
        id = ID()
        guard buffer != nil else { return }
        
        guard keepCapacity else {
            buffer = nil
            
            return
        }
        
        let prevCapacity = capacity
        buffer = HashTableBuffer(minimumCapacity: prevCapacity)
    }
    
}

// MARK: - Other methods
extension SeparateChainingHashTable {
    /// Reserves enough space to store the specified number of key-value pairs.
    ///
    /// If you are adding a known number of key-value pairs to an hash table, use this
    /// method to avoid multiple reallocations. This method ensures that the
    /// hash table has unique, mutable, contiguous storage, with space allocated
    /// for at least the requested number of key-value pairs.
    /// This method might invalidate all indices of the hash table.
    ///
    /// - Parameter minimumCapacity:    The requested number of
    ///                                 key-value pairs to store.
    /// - Complexity: O(*k*) where *k* is the final capacity for the hash table.
    public mutating func reserveCapacity(_ minimumCapacity: Int) {
        precondition(minimumCapacity >= 0, "minimumCapacity must not be negative")
        makeUniqueReserving(minimumCapacity: minimumCapacity)
    }
    
    /// Merges the key-value pairs in the given sequence into the hash table,
    /// using a combining closure to determine the value for any duplicate keys.
    ///
    /// Use the `combine` closure to select a value to use in the updated
    /// hash table, or to combine existing and new values. As the key-value
    /// pairs are merged with the hash table, the `combine` closure is called
    /// with the current and new values for any duplicate keys that are
    /// encountered.
    ///
    /// This method invalidates all indices of the hash table.
    /// This example shows how to choose the current or new values for any
    /// duplicate keys:
    ///
    ///     var dictionary: SeparateChainingHashTable<String, Key> = ["a": 1, "b": 2]
    ///
    ///     // Keeping existing value for key "a":
    ///     dictionary.merge(zip(["a", "c"], [3, 4])) { (current, _) in current }
    ///     // ["b": 2, "a": 1, "c": 4]
    ///
    ///     // Taking the new value for key "a":
    ///     dictionary.merge(zip(["a", "d"], [5, 6])) { (_, new) in new }
    ///     // ["b": 2, "a": 5, "c": 4, "d": 6]
    ///
    /// - Parameters:
    ///   - other:  A sequence of key-value pairs.
    ///   - combine:    A closure that takes the current and new values for any
    ///                 duplicate keys. The closure returns the desired value
    ///                 for the final hash table.
    public mutating func merge<S: Sequence>(_ keysAndValues: S, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows where S.Iterator.Element == (Key, Value) {
        if let other = keysAndValues as? SeparateChainingHashTable<Key, Value> {
            try merge(other, uniquingKeysWith: combine)
        } else {
            id = ID()
            makeUnique()
            try buffer!.merge(keysAndValues, uniquingKeysWith: combine)
        }
    }
    
    /// Merges the given hash table into this hash table, using a combining
    /// closure to determine the value for any duplicate keys.
    ///
    /// Use the `combine` closure to select a value to use in the updated
    /// hash table, or to combine existing and new values. As the key-values
    /// pairs in `other` are merged with this hash table, the `combine` closure
    /// is called with the current and new values for any duplicate keys that
    /// are encountered.
    ///
    /// This method might invalidate all indices of the hash table.
    /// This example shows how to choose the current or new values for any
    /// duplicate keys:
    ///
    ///     var dictionary: SeparateChainingHashTable<String, Int> = ["a": 1, "b": 2]
    ///     var other = SeparateChainingHashTable<String, Int> = ["a": 3, "c": 4]
    ///
    ///     // Keeping existing value for key "a":
    ///     dictionary.merge(other) { (current, _) in current }
    ///     // ["b": 2, "a": 1, "c": 4]
    ///
    ///     // Taking the new value for key "a":
    ///     other = ["a": 5, "d": 6]
    ///     dictionary.merge(other) { (_, new) in new }
    ///     // ["b": 2, "a": 5, "c": 4, "d": 6]
    ///
    /// - Parameters:
    ///   - other:  An hash table to merge.
    ///   - combine:    A closure that takes the current and new values for any
    ///                 duplicate keys. The closure returns the desired value
    ///                 for the final hash table.
    public mutating func merge(_ other: SeparateChainingHashTable, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows {
        guard !other.isEmpty else { return }
        
        makeUnique()
        id = ID()
        try! buffer!.merge(other.buffer!, uniquingKeysWith: combine)
    }
    
    /// Creates an hash table by merging the given hash table into this
    /// hash table, using a combining closure to determine the value for
    /// duplicate keys.
    ///
    /// Use the `combine` closure to select a value to use in the returned
    /// hash table, or to combine existing and new values. As the key-value
    /// pairs in `other` are merged with this hash table, the `combine` closure
    /// is called with the current and new values for any duplicate keys that
    /// are encountered.
    ///
    /// This example shows how to choose the current or new values for any
    /// duplicate keys:
    ///
    ///     let dictionary: SeparateChainingHashTable<String, Int> = ["a": 1, "b": 2]
    ///     let other: SeparateChianingHashTable<String, Int> = ["a": 3, "b": 4]
    ///
    ///     let keepingCurrent = dictionary.merging(other)
    ///           { (current, _) in current }
    ///     // ["b": 2, "a": 1]
    ///     let replacingCurrent = dictionary.merging(other)
    ///           { (_, new) in new }
    ///     // ["b": 4, "a": 3]
    ///
    /// - Parameters:
    ///   - other:  An hash table to merge.
    ///   - combine:    A closure that takes the current and new values for any
    ///                 duplicate keys. The closure returns the desired value
    ///                 for the final hash table.
    /// - Returns:  A new hash table with the combined keys and values
    ///             of this hash table and `other`.
    func merging(_ other: SeparateChainingHashTable, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows -> SeparateChainingHashTable {
        guard !isEmpty else { return other }
        
        guard !other.isEmpty else { return self }
        
        let mergedBuffer = (buffer!.copy() as! HashTableBuffer<Key, Value>)
        try mergedBuffer.merge(other.buffer!, uniquingKeysWith: combine)
        
        return SeparateChainingHashTable(buffer: mergedBuffer)
    }
    
    /// Creates an hash table by merging key-value pairs in a sequence into the
    /// hash table, using a combining closure to determine the value for
    /// duplicate keys.
    ///
    /// Use the `combine` closure to select a value to use in the returned
    /// hash table, or to combine existing and new values. As the key-value
    /// pairs are merged with the hash table, the `combine` closure is called
    /// with the current and new values for any duplicate keys that are
    /// encountered.
    ///
    /// This example shows how to choose the current or new values for any
    /// duplicate keys:
    ///
    ///     let dictionary: SeparateChainingHashTable<String, Int> = ["a": 1, "b": 2]
    ///     let newKeyValues = zip(["a", "b"], [3, 4])
    ///
    ///     let keepingCurrent = dictionary.merging(newKeyValues) { (current, _) in current }
    ///     // ["b": 2, "a": 1]
    ///     let replacingCurrent = dictionary.merging(newKeyValues) { (_, new) in new }
    ///     // ["b": 4, "a": 3]
    ///
    /// - Parameters:
    ///   - other:  A sequence of key-value pairs.
    ///   - combine:    A closure that takes the current and new values for any
    ///                 duplicate keys. The closure returns the desired value
    ///                 for the final hash table.
    /// - Returns:  A new hash table with the combined keys and values
    ///             of this hash table and `other`.
    func merging<S>(_ other: S, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows -> SeparateChainingHashTable where S : Sequence, S.Element == (Key, Value) {
        if let otherHT = other as? SeparateChainingHashTable {
            
            return try merging(otherHT, uniquingKeysWith: combine)
        }
        
        guard
            !isEmpty
        else {
            return try SeparateChainingHashTable(other, uniquingKeysWith: combine)
        }
        
        let mergedBuffer = (buffer!.copy() as! HashTableBuffer<Key, Value>)
        try mergedBuffer.merge(other, uniquingKeysWith: combine)
        
        return SeparateChainingHashTable(buffer: mergedBuffer)
    }
    
    /// Returns a new hash table containing the keys of this hash table with the
    /// values transformed by the given closure.
    ///
    /// - Parameter transform: A closure that transforms a value. `transform`
    ///   accepts each value of the hash table as its parameter and returns a
    ///   transformed value of the same or of a different type.
    /// - Returns:  An hash table containing the keys and transformed values
    ///             of this hash table.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the hash table.
    public func mapValues<T>(_ transform: (Value) throws -> T) rethrows -> SeparateChainingHashTable<Key, T> {
        let mappedBuffer = try buffer?.mapValues(transform)
        
        return SeparateChainingHashTable<Key, T>(buffer: mappedBuffer)
    }
    
    /// Returns a new hash table containing only the key-value pairs that have
    /// non-`nil` values as the result of transformation by the given closure.
    ///
    /// Use this method to receive an hash table with non-optional values when
    /// your transformation produces optional values.
    ///
    /// In this example, note the difference in the result of using `mapValues`
    /// and `compactMapValues` with a transformation that returns an optional
    /// `Int` value.
    ///
    ///     let data: SeparateChainingHashTable<String, String> = ["a": "1", "b": "three", "c": "///4///"]
    ///
    ///     let m: SeparateChainingHashTable<String, Int?> = data.mapValues { str in Int(str) }
    ///     // ["a": 1, "b": nil, "c": nil]
    ///
    ///     let c: SeparateChainingHashTable<String, Int> = data.compactMapValues { str in Int(str) }
    ///     // ["a": 1]
    ///
    /// - Parameter transform:  A closure that transforms a value. `transform`
    ///                         accepts each value of the hash table as
    ///                         its parameter and returns an optional transformed
    ///                         value of the same or of a different type.
    /// - Returns:  An hash table containing the keys and non-`nil` transformed values
    ///             of this hash table.
    ///
    /// - Complexity:   O(*m* + *n*), where *n* is the length of the original
    ///                 hash table and *m* is the length of the resulting hash table.
    public func compactMapValues<T>(_ transform: (Value) throws -> T?) rethrows -> SeparateChainingHashTable<Key, T> {
        let mappedBuffer = try buffer?.compactMapValues(transform)
        
        return SeparateChainingHashTable<Key, T>(buffer: mappedBuffer)
    }
    
    /// Returns a new hash table containing the key-value pairs of the hash table
    /// that satisfy the given predicate.
    ///
    /// - Parameter isIncluded: A closure that takes a key-value pair as its
    ///   argument and returns a Boolean value indicating whether the pair
    ///   should be included in the returned hash table.
    /// - Returns: An hash table of the key-value pairs that `isIncluded` allows.
    public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> SeparateChainingHashTable {
        let filtered = try self.buffer?.filter(isIncluded)
        
        return SeparateChainingHashTable(buffer: filtered)
    }
    
    /// Removes and returns the key-value pair at the specified index.
    ///
    /// Calling this method invalidates any existing indices for use with this
    /// hash table.
    ///
    /// - Parameter index:  The position of the key-value pair to remove. `index`
    ///                     must be a valid index of the hash table,
    ///                     and must not equal the hash table's end index.
    /// - Returns: The key-value pair that correspond to `index`.
    ///
    /// - Complexity: Amortized O(1).
    @discardableResult
    public mutating func remove(at index: Index) -> Element {
        precondition(index.isValidFor(self), "invalid index for this hash table")
        guard
            let removedElement = index.currentBag(on: buffer)?.element else {
            preconditionFailure("index out of bounds")
        }
        makeUniqueEventuallyReducingCapacity()
        defer { removeValue(forKey: removedElement.key) }
        
        return removedElement
    }
    
}

// MARK: - C.O.W. internal utilities
extension SeparateChainingHashTable {
    @inline(__always)
    mutating func makeUniqueEventuallyIncreasingCapacity() {
        guard
            (buffer?.tableIsTooTight ?? false)
        else {
            makeUnique()
            
            return
        }
        
        id = ID()
        buffer = buffer!.clone(newCapacity: capacity * 2)
    }
    
    @inline(__always)
    mutating func makeUniqueEventuallyReducingCapacity() {
        id = ID()
        guard
            !isEmpty
        else {
            buffer = nil
            
            return
        }
        
        guard
            (buffer!.tableIsTooSparse)
        else {
            makeUnique()
            
            return
        }
        
        let mCapacity = Swift.max(capacity / 2, Self.minBufferCapacity)
        buffer = buffer!.clone(newCapacity: mCapacity)
    }
    
    @inline(__always)
    mutating func makeUniqueReserving(minimumCapacity k: Int) {
        assert(k >= 0, "minimumCapacity musty not be negative")
        guard
            freeCapacity < k
        else {
            makeUnique()
            
            return
        }
        
        id = ID()
        let mCapacity = buffer == nil ? Swift.max(k, Self.minBufferCapacity) : Swift.max(((count + k) * 3) / 2, capacity * 2)
        buffer = buffer?.clone(newCapacity: mCapacity) ?? HashTableBuffer(minimumCapacity: mCapacity)
    }
    
    @inline(__always)
    mutating func makeUnique() {
        guard buffer != nil else {
            id = ID()
            buffer = HashTableBuffer(minimumCapacity: Self.minBufferCapacity)
            
            return
        }
        
        if !isKnownUniquelyReferenced(&buffer!) {
            buffer = (buffer!.copy() as! HashTableBuffer<Key, Value>)
        }
    }
    
}

// MARK: - Sequence conformance
extension SeparateChainingHashTable: Sequence {
    /// An iterator over the members of a `SeparateChainingHashTable<Key, Value>`.
    public struct Iterator: IteratorProtocol {
        private var htBuffer: HashTableBuffer<Key, Value>?
        
        private var bufferIterator: AnyIterator<Element>?
        
        private var nextElement: Element?
        
        fileprivate init(ht: SeparateChainingHashTable) {
            self.htBuffer = ht.buffer
            self.bufferIterator = ht.buffer?.makeIterator()
            moveToNextElement()
        }
        
        public mutating func next() -> Element? {
            defer { moveToNextElement() }
            
            return nextElement
        }
        
        private mutating func moveToNextElement() {
            guard bufferIterator != nil else { return }
            
            nextElement = bufferIterator!.next()
            guard
                nextElement != nil
            else {
                bufferIterator = nil
                htBuffer = nil
                
                return
            }
        }
        
    }
    
    /// A value equal to the number of key-value pairs stored in the hash table.
    ///
    /// - Complexity: O(1).
    @inlinable
    public var underestimatedCount: Int { count }
    
    /// Returns an iterator over the hash table's key-value pairs.
    ///
    /// Iterating over an hash table yields the key-value pairs as two-element
    /// tuples. You can decompose the tuple in a `for`-`in` loop, which calls
    /// `makeIterator()` behind the scenes, or when calling the iterator's
    /// `next()` method directly.
    ///
    ///     let hues: SeparateChainingHashTable<String, Int> = ["Heliotrope": 296, "Coral": 16, "Aquamarine": 156]
    ///     for (name, hueValue) in hues {
    ///         print("The hue of \(name) is \(hueValue).")
    ///     }
    ///     // Prints "The hue of Heliotrope is 296."
    ///     // Prints "The hue of Coral is 16."
    ///     // Prints "The hue of Aquamarine is 156."
    ///
    /// - Returns:  An iterator over the hash table with elements of type
    ///             `(key: Key, value: Value)`.
    public func makeIterator() -> Iterator {
        Iterator(ht: self)
    }
    
}

// MARK: - Collection conformance
extension SeparateChainingHashTable: Collection {
    final class ID {  }
    
    /// The position of a key-value pair in an hash table.
    ///
    /// Hash table has two subscripting interfaces:
    ///
    /// 1. Subscripting with a key, yielding an optional value:
    ///
    ///        v = d[k]!
    ///
    /// 2. Subscripting with an index, yielding a key-value pair:
    ///
    ///        (k, v) = d[i]
    public struct Index: Comparable {
        internal var id: ID
        
        internal var currentTableIndex: Int
        
        internal var currentBagOffset: Int = 0
        
        internal init(asStartIndexOf ht: SeparateChainingHashTable) {
            self.id = ht.id
            self.currentTableIndex = ht.buffer?.firstTableElement ?? ht.capacity
        }
        
        internal init(asEndIndexOf ht: SeparateChainingHashTable) {
            self.id = ht.id
            self.currentTableIndex = ht.capacity
        }
        
        internal init(asIndexOfKey k: Key, for ht: SeparateChainingHashTable) {
            self.id = ht.id
            guard !ht.isEmpty else {
                self.currentTableIndex = ht.capacity
                
                return
            }
            
            self.currentTableIndex = ht.buffer!.hashIndex(forKey: k)
            
            guard
                var currentBag = ht.buffer!.table[currentTableIndex]
            else {
                self.currentTableIndex = ht.capacity
                
                return
            }
            
            guard
                currentBag.key != k
            else { return }
            
            while let n = currentBag.next {
                self.currentBagOffset += 1
                if n.key == k { return }
                
                currentBag = n
            }
            currentTableIndex = ht.capacity
            currentBagOffset = 0
        }
        
        @discardableResult
        internal func currentBag(on buffer: HashTableBuffer<Key, Value>?) -> HashTableBuffer<Key, Value>.Bag? {
            guard
                currentTableIndex < (buffer?.capacity ?? 0)
            else { return nil }
            
            guard
                var bag = buffer?.table[currentTableIndex]
            else { return nil }
            
            if currentBagOffset == 0 { return bag }
            precondition(currentBagOffset < bag.count, "Malformed index")
            for _ in 0..<currentBagOffset {
                bag = bag.next!
            }
            
            return bag
        }
        
        @discardableResult
        internal mutating func moveToNextElement(on buffer: HashTableBuffer<Key, Value>?) -> HashTableBuffer<Key, Value>.Bag? {
            guard
                let thisBag = currentBag(on: buffer)
            else { return nil }
            
            if let nextBag = thisBag.next {
                currentBagOffset += 1
                
                return nextBag
            }
            
            currentTableIndex += 1
            currentBagOffset = 0
            while currentTableIndex < buffer!.capacity {
                if let nextBag = buffer!.table[currentTableIndex] {
                    
                    return nextBag
                }
                
                currentTableIndex += 1
            }
            
            return nil
        }
        
        @inline(__always)
        internal func isValidFor(_ ht: SeparateChainingHashTable) -> Bool {
            id === ht.id && currentTableIndex <= ht.capacity
            
        }
        
        @inline(__always)
        internal static func areValid(lhs: Index, rhs: Index) -> Bool {
            lhs.id === rhs.id
        }
        
        // MARK: - Index Comparable conformance
        public static func == (lhs: Index, rhs: Index) -> Bool {
            precondition(areValid(lhs: lhs, rhs: rhs), "indexes from two different hash tables cannot be compared")
            
            return lhs.currentTableIndex == rhs.currentTableIndex && lhs.currentBagOffset == rhs.currentBagOffset
        }
        
        public static func < (lhs: Index, rhs: Index) -> Bool {
            precondition(areValid(lhs: lhs, rhs: rhs), "indexes from two different hash tables cannot be compared")
            guard
                lhs.currentTableIndex != rhs.currentTableIndex
            else {
                
                return lhs.currentBagOffset < rhs.currentBagOffset
            }
            
            return lhs.currentTableIndex < rhs.currentTableIndex
        }
        
    }
    
    public var startIndex: Index { Index(asStartIndexOf: self) }
    
    public var endIndex: Index { Index(asEndIndexOf: self) }
    
    public func formIndex(after i: inout Index) {
        precondition(i.isValidFor(self), "invalid index for this hash table")
        
        i.moveToNextElement(on: self.buffer)
    }
    
    public func index(after i: Index) -> Index {
        precondition(i.isValidFor(self), "invalid index for this hash table")
        
        var nextIndex = i
        nextIndex.moveToNextElement(on: self.buffer)
        
        return nextIndex
    }
    
    public func formIndex(_ i: inout Index, offsetBy distance: Int) {
        precondition(distance >= 0 , "distance must not be negative")
        precondition(i.isValidFor(self), "invalid index for this hash table")
        let end = endIndex
        var offset = 0
        while offset < distance && i < end {
            i.moveToNextElement(on: self.buffer)
            offset += 1
        }
    }
    
    public func index(_ i: Index, offsetBy distance: Int) -> Index {
        var offSetted = i
        formIndex(&offSetted, offsetBy: distance)
        
        return offSetted
    }
 
    public func formIndex(_ i: inout Self.Index, offsetBy distance: Int, limitedBy limit: Self.Index) -> Bool {
        precondition(distance >= 0 , "distance must not be negative")
        precondition(i.isValidFor(self), "invalid index for this hash table")
        precondition(limit.isValidFor(self), "invalid limit index for this hash table")
        
        guard
            distance > 0
        else { return i <= limit }
        
        let end = endIndex
        var offset = 0
        while offset < distance && i < end && i < limit {
            i.moveToNextElement(on: self.buffer)
            offset += 1
        }
        
        return distance == offset
    }
    
    public func index(_ i: Self.Index, offsetBy distance: Int, limitedBy limit: Self.Index) -> Self.Index? {
        var offsetted = i
        let formed = formIndex(&offsetted, offsetBy: distance, limitedBy: limit)
        return  formed == true ? offsetted : nil
    }
    
    /// Returns the index for the given key.
    ///
    /// If the given key is found in the hash table, this method returns an index
    /// into the dictionary that corresponds with the key-value pair.
    ///
    ///     let countryCodes: SeparateChainingHashTable<String, String> = ["BR": "Brazil", "GH": "Ghana", "JP": "Japan"]
    ///     let index = countryCodes.index(forKey: "JP")
    ///
    ///     print("Country code for \(countryCodes[index!].value): '\(countryCodes[index!].key)'.")
    ///     // Prints "Country code for Japan: 'JP'."
    ///
    /// - Parameter key: The key to find in the hash table.
    /// - Returns:  The index for `key` and its associated value if `key` is in
    ///             the hash table; otherwise, `nil`.
    public func index(forKey key: Key) -> Index? {
        let idx = Index(asIndexOfKey: key, for: self)
        
        guard
            idx < endIndex
        else { return nil }
        
        return idx
    }
    
    /// Accesses the key-value pair at the specified position.
    ///
    /// This subscript takes an index into the hash table, instead of a key, and
    /// returns the corresponding key-value pair as a tuple. When performing
    /// collection-based operations that return an index into an hash table, use
    /// this subscript with the resulting value.
    ///
    /// For example, to find the key for a particular value in an hash table, use
    /// the `firstIndex(where:)` method.
    ///
    ///     let countryCodes: SeparateChainingHashTable<String, String> = ["BR": "Brazil", "GH": "Ghana", "JP": "Japan"]
    ///     if let index = countryCodes.firstIndex(where: { $0.value == "Japan" }) {
    ///         print(countryCodes[index])
    ///         print("Japan's country code is '\(countryCodes[index].key)'.")
    ///     } else {
    ///         print("Didn't find 'Japan' as a value in the dictionary.")
    ///     }
    ///     // Prints "("JP", "Japan")"
    ///     // Prints "Japan's country code is 'JP'."
    ///
    /// - Parameter position:   The position of the key-value pair to access.
    ///                         `position` must be a valid index of the hash table
    ///                         and not equal to `endIndex`.
    /// - Returns:  A two-element tuple with the key and value corresponding to
    ///             `position`.
    public subscript(position: Index) -> (key: Key, value: Value) {
        get {
            precondition(position.isValidFor(self), "invalid index for this hash table")
            guard
                let element = position.currentBag(on: self.buffer)?.element
            else {
                preconditionFailure("index out of bounds")
            }
           
            return element
        }
    }
    
}

// MARK: - ExpressibleByDictionaryLiteral conformance
extension SeparateChainingHashTable: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (Key, Value)...) {
        self.init(uniqueKeysWithValues: elements)
    }
    
}

// MARK: - Equatable conformance
extension SeparateChainingHashTable: Equatable where Value: Equatable {
    public static func == (lhs: SeparateChainingHashTable<Key, Value>, rhs: SeparateChainingHashTable<Key, Value>) -> Bool {
        lhs.buffer == rhs.buffer
    }
    
}

// MARK: - Hashable conformance
extension SeparateChainingHashTable: Hashable where Value: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(buffer)
    }
    
}

// MARK: - Codable conformance
extension SeparateChainingHashTable: Codable where Key: Codable, Value: Codable {
    public enum Error: Swift.Error {
        case keysAndValuesCountsNotMatching
        case duplicateKeys
        
    }
    
    enum CodingKeys: String, CodingKey {
        case keys
        case values
    }
    
    public func encode(to encoder: Encoder) throws {
        var keys: [Key] = []
        var values: [Value] = []
        forEach {
            keys.append($0.key)
            values.append($0.value)
        }
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keys, forKey: .keys)
        try container.encode(values, forKey: .values)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let keys = try container.decode(Array<Key>.self, forKey: .keys)
        let values = try container.decode(Array<Value>.self, forKey: .values)
        guard
            keys.count == values.count
        else { throw Error.keysAndValuesCountsNotMatching }
        
        try self.init(zip(keys, values), uniquingKeysWith: { _, _ in
            throw Error.duplicateKeys
        })
    }
    
}

// MARK: - Keys and Values
extension SeparateChainingHashTable {
    /// A view of an hash table's keys.
    public struct Keys: Collection, Equatable {
        fileprivate let ht: SeparateChainingHashTable
        
        fileprivate init(_ ht: SeparateChainingHashTable) {
            self.ht = ht
        }
        
        // Collection conformance
        public typealias Element = SeparateChainingHashTable.Key
        
        public typealias Index = SeparateChainingHashTable.Index
        
        public var count: Int { ht.count }
        
        public var underestimatedCount: Int { ht.count }
        
        public var isEmpty: Bool { ht.isEmpty }
        
        public var startIndex: Index { ht.startIndex }
        
        public var endIndex: Index { ht.endIndex }
        
        public func formIndex(after i: inout Index) {
            ht.formIndex(after: &i)
        }
        
        public func index(after i: Index) -> Index {
            ht.index(after: i)
        }
        
        public func formIndex(_ i: inout Index, offsetBy distance: Int) {
            ht.formIndex(&i, offsetBy: distance)
        }
        
        public func index(_ i: Index, offsetBy distance: Int) -> Index {
            ht.index(i, offsetBy: distance)
        }
        
        public func formIndex(_ i: inout Index, offsetBy distance: Int, limitedBy limit: Index) -> Bool {
            ht.formIndex(&i, offsetBy: distance, limitedBy: limit)
        }
        
        public func index(_ i: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? {
            ht.index(i, offsetBy: distance, limitedBy: limit)
        }
        
        public subscript(position: Index) -> Element {
            ht[position].key
        }
        
        // Equatable
        public static func == (lhs: Keys, rhs: Keys) -> Bool {
            guard lhs.count == rhs.count else { return false }
            for (lElement, rElement) in zip(lhs.ht, rhs.ht) where lElement.key != rElement.key { return false }
            
            return true
        }
        
    }
    
    /// A view of an hash table's values.
    public struct Values: MutableCollection {
        fileprivate var ht: SeparateChainingHashTable
        
        fileprivate init(_ ht: SeparateChainingHashTable) {
            self.ht = ht
        }
        
        // Collection conformance
        public typealias Element = SeparateChainingHashTable.Value
        
        public typealias Index = SeparateChainingHashTable.Index
        
        public var count: Int { ht.count }
        
        public var underestimatedCount: Int { ht.count }
        
        public var isEmpty: Bool { ht.isEmpty }
        
        public var startIndex: Index { ht.startIndex }
        
        public var endIndex: Index { ht.endIndex }
        
        public func formIndex(after i: inout Index) {
            ht.formIndex(after: &i)
        }
        
        public func index(after i: Index) -> Index {
            ht.index(after: i)
        }
        
        public func formIndex(_ i: inout Index, offsetBy distance: Int) {
            ht.formIndex(&i, offsetBy: distance)
        }
        
        public func index(_ i: Index, offsetBy distance: Int) -> Index {
            ht.index(i, offsetBy: distance)
        }
        
        public func formIndex(_ i: inout Index, offsetBy distance: Int, limitedBy limit: Index) -> Bool {
            ht.formIndex(&i, offsetBy: distance, limitedBy: limit)
        }
        
        public func index(_ i: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? {
            ht.index(i, offsetBy: distance, limitedBy: limit)
        }
        
        public subscript(position: Index) -> Element {
            get {
                ht[position].value
            }
            
            mutating set {
                ht.makeUnique()
                guard
                    let b = position.currentBag(on: ht.buffer)
                else { preconditionFailure("index out of bounds") }
                
                b.value = newValue
            }
        }
    }
    
}

// Equatable conformance for Values
extension SeparateChainingHashTable.Values: Equatable where Value: Equatable {
    public static func == (lhs: SeparateChainingHashTable.Values, rhs: SeparateChainingHashTable.Values) -> Bool {
        guard lhs.count == rhs.count else { return false }
        
        for (lElement, rElement) in zip(lhs.ht, rhs.ht) where lElement.value != rElement.value { return false }
        
        return true
    }
    
}
