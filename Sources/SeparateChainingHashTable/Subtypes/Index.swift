//
//  Index.swift
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
        internal var currentTableIndex: Int
        
        internal var currentBagOffset: Int = 0
        
        internal init(asStartIndexOf ht: SeparateChainingHashTable) {
            self.currentTableIndex = ht.buffer?.firstTableElement ?? ht.capacity
        }
        
        internal init(asEndIndexOf ht: SeparateChainingHashTable) {
            self.currentTableIndex = ht.capacity
        }
        
        internal init?(asIndexOfKey k: Key, for ht: SeparateChainingHashTable) {
            guard !ht.isEmpty else { return nil }
            
            self.currentTableIndex = ht.buffer!.hashIndex(forKey: k)
            var currentBag = ht.buffer!.table[currentTableIndex]
            while currentBag != nil {
                guard currentBag?.key != k else { return }
                
                self.currentBagOffset += 1
                currentBag = currentBag?.next
            }
            
            return nil
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
            guard currentBagOffset < bag.count else { return nil }
            
            for _ in 0..<currentBagOffset {
                bag = bag.next!
            }
            
            return bag
        }
        
        @discardableResult
        internal mutating func moveToNextElement(on buffer: HashTableBuffer<Key, Value>?) -> HashTableBuffer<Key, Value>.Bag? {
            if
                let nextBag = currentBag(on: buffer)?.next {
                currentBagOffset += 1
                
                return nextBag
            }
            let bufferCapacity = buffer?.capacity ?? 0
            currentBagOffset = 0
            currentTableIndex += 1
            
            while currentTableIndex < bufferCapacity {
                if let nextBag = buffer?.table[currentTableIndex] { return nextBag }
                currentTableIndex += 1
            }
            
            return nil
        }
        
        // MARK: - Index Comparable conformance
        public static func == (lhs: Index, rhs: Index) -> Bool {
            lhs.currentTableIndex == rhs.currentTableIndex && lhs.currentBagOffset == rhs.currentBagOffset
        }
        
        public static func < (lhs: Index, rhs: Index) -> Bool {
            guard
                lhs.currentTableIndex != rhs.currentTableIndex
            else {
                
                return lhs.currentBagOffset < rhs.currentBagOffset
            }
            
            return lhs.currentTableIndex < rhs.currentTableIndex
        }
        
    }
    
}
