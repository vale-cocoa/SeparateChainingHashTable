//
//  SeparateChainingHashTable+Collection.swift
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

extension SeparateChainingHashTable: Collection {
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
    
    public var startIndex: Index { Index(asStartIndexOf: self) }
    
    public var endIndex: Index { Index(asEndIndexOf: self) }
    
    public func formIndex(after i: inout Index) {
        i.moveToNextElement(on: self.buffer)
    }
    
    public func index(after i: Index) -> Index {
        var nextIndex = i
        nextIndex.moveToNextElement(on: self.buffer)
        
        return nextIndex
    }
    
    public func formIndex(_ i: inout Index, offsetBy distance: Int) {
        precondition(distance >= 0 , "distance must not be negative")
        for _ in stride(from: 0, to: distance, by: 1) {
            i.moveToNextElement(on: self.buffer)
        }
    }
    
    public func index(_ i: Index, offsetBy distance: Int) -> Index {
        var offSetted = i
        formIndex(&offSetted, offsetBy: distance)
        
        return offSetted
    }
    
    public func index(_ i: Self.Index, offsetBy distance: Int, limitedBy limit: Self.Index) -> Self.Index? {
        precondition(distance >= 0 , "distance must not be negative")
        
        // Just ignore the limit when is less than i
        if limit < i { return index(i, offsetBy: distance) }
        
        // let's stride indices:
        var result = i
        for _ in stride(from: 0, to: distance, by: 1) {
            // When we're gonna end up after limit we return nil
            if result == limit { return nil }
            result.moveToNextElement(on: self.buffer)
        }
        
        return result
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
        Index(asIndexOfKey: key, for: self)
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
            guard
                let element = position.currentBag(on: self.buffer)?.element
            else {
                preconditionFailure("Index out of bounds")
            }
           
            return element
        }
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
        guard
            let removedElement = index.currentBag(on: buffer)?.element
        else {
            preconditionFailure("Index out of bounds")
        }
        
        makeUniqueEventuallyReducingCapacity()
        defer { removeValue(forKey: removedElement.key) }
        
        return removedElement
    }
    
}
