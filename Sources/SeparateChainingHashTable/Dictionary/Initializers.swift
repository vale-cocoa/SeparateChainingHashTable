//
//  Initializers.swift
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

// MARK: - ExpressibleByDictionaryLiteral conformance
extension SeparateChainingHashTable: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (Key, Value)...) {
        self.init(uniqueKeysWithValues: elements)
    }
    
}

extension SeparateChainingHashTable {    
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
        guard
            k > 0
        else {
            self.init()
            
            return
        }
        
        let minimumCapacity = Swift.max(Self.minBufferCapacity, k)
        let newBuffer = HashTableBuffer<Key, Value>(minimumCapacity: minimumCapacity)
        self.init(buffer: newBuffer)
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
    
}

