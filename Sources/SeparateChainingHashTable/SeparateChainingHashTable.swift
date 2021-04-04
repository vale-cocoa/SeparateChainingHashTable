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
/// of Swift `Dictionary`.
/// - ToDo: Add `CustomStringConvertible` and
///         `CustomDebugStringConvertible` conformances.
public struct SeparateChainingHashTable<Key: Hashable, Value> {
    final class ID {  }
    
    private(set) var buffer: HashTableBuffer<Key, Value>? = nil
    
    private(set) var id = ID()
    
    @inline(__always)
    internal static var minBufferCapacity: Int {
        HashTableBuffer<Key, Value>.minTableCapacity
    }
    
    /// Creates an empty hash table.
    public init() {  }
    
    internal init(_ other: SeparateChainingHashTable) {
        self.init(buffer: other.buffer, id: other.id)
    }
    
    internal init(buffer: HashTableBuffer<Key, Value>?, id: ID = ID()) {
        self.buffer = buffer
        self.id = id
    }
    
    // MARK: - Copy On Write helpers
    @inline(__always)
    internal mutating func makeUnique() {
        guard buffer != nil else {
            id = ID()
            buffer = HashTableBuffer(minimumCapacity: Self.minBufferCapacity)
            
            return
        }
        
        if !isKnownUniquelyReferenced(&buffer!) {
            buffer = (buffer!.copy() as! HashTableBuffer<Key, Value>)
        }
    }
    
    @inline(__always)
    internal mutating func makeUniqueReserving(minimumCapacity k: Int) {
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
    internal mutating func makeUniqueEventuallyIncreasingCapacity() {
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
    internal mutating func makeUniqueEventuallyReducingCapacity() {
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
    
    // MARK: - Other helpers
    @inline(__always)
    fileprivate var freeCapacity: Int {
        guard buffer != nil else { return 0 }
        
        return buffer!.capacity - buffer!.count
    }
    
    @inline(__always)
    internal mutating func changeIndexID() { id = ID() }
    
}

