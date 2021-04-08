//
//  Merge.swift
//  SeparateChainingHashTable
//
//  Created by Valeriano Della Longa on 2021/04/05.
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

extension SeparateChainingHashTable {
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
        
        guard
            !isEmpty
        else {
            self = other
            
            return
        }
        
        makeUnique()
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
        guard !other.isEmpty else { return self }
        
        guard !isEmpty else { return other }
        
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
    
}
