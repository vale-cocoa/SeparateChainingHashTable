//
//  MapValuesAndFilter.swift
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
    
}
