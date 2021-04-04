//
//  Keys.swift
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
    
}
