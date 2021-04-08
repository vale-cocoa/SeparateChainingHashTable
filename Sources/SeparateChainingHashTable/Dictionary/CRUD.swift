//
//  CRUD.swift
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
    /// the original value. This method might invalidate indices of the hash table that were previously stored.
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
    /// associated value. This method might invalidate indices of the hash table that were previously stored.
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
    /// Calling this method might invalidate indices of the hash table that were previously stored.
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
        guard buffer != nil else { return }
        
        guard keepCapacity else {
            self = Self()
            
            return
        }
        
        guard !isEmpty else { return }
        
        self = Self(buffer: HashTableBuffer(minimumCapacity: capacity))
    }
    
    /// Reserves enough space to store the specified number of key-value pairs.
    ///
    /// If you are adding a known number of key-value pairs to an hash table, use this
    /// method to avoid multiple reallocations. This method ensures that the
    /// hash table has unique, mutable, contiguous storage, with space allocated
    /// for at least the requested number of key-value pairs.
    /// This method might invalidate indices of the hash table that were previously stored.
    ///
    /// - Parameter minimumCapacity:    The requested number of
    ///                                 key-value pairs to store.
    /// - Complexity: O(*k*) where *k* is the final capacity for the hash table.
    public mutating func reserveCapacity(_ minimumCapacity: Int) {
        precondition(minimumCapacity >= 0, "minimumCapacity must not be negative")
        makeUniqueReserving(minimumCapacity: minimumCapacity)
    }
    
    /// The total number of key-value pairs that the hash table can contain without
    /// allocating new storage.
    ///
    /// - Complexity: O(1)
    @inline(__always)
    public var capacity: Int { buffer?.capacity ?? 0 }
    
}
