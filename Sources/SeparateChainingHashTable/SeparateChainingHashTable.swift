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

public struct SeparateChainingHashTable<Key: Hashable, Value> {
    public typealias Element = (key: Key, value: Value)
    
    final class ID {  }
    
    private(set) var buffer: HashTableBuffer<Key, Value>? = nil
    
    private(set) var id = ID()
    
    @inline(__always)
    public var capacity: Int { buffer?.capacity ?? 0 }
    
    @inline(__always)
    public var count: Int { buffer?.count ?? 0 }
    
    @inline(__always)
    public var isEmpty: Bool { buffer?.isEmpty ?? true }
    
    @inline(__always)
    fileprivate var freeCapacity: Int { capacity - count }
    
    @inline(__always)
    fileprivate static var minBufferCapacity: Int {
        HashTableBuffer<Key, Value>.minTableCapacity
    }
    
    public init() {  }
    
    public init(minimumCapacity k: Int) {
        precondition(k >= 0, "minimumCapacity must not be negative")
        guard k > 0 else { return }
        
        let minimumCapacity = Swift.max(Self.minBufferCapacity, k)
        
        self.buffer = HashTableBuffer(minimumCapacity: minimumCapacity)
    }
    
    public init<S: Sequence>(uniqueKeysWithValues keysAndValues: S) where S.Iterator.Element == Element {
        self.init(keysAndValues) { _, _ in
            preconditionFailure("keys must be unique")
        }
    }
    
    public init<S>(_ keysAndValues: S, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows where S : Sequence, S.Iterator.Element == Element {
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
                for keyValuePair in keysAndValues {
                    try newBuffer!.setValue(keyValuePair.value, forKey: keyValuePair.key, uniquingKeysWith: combine)
                }
                
                return true
            } ?? false
        if !done {
            var kvIter = keysAndValues.makeIterator()
            if let firstElement = kvIter.next() {
                newBuffer = HashTableBuffer(minimumCapacity: Swift.max(Self.minBufferCapacity, (keysAndValues.underestimatedCount * 3) / 2))
                try newBuffer!.setValue(firstElement.value, forKey: firstElement.key, uniquingKeysWith: combine)
                while let element = kvIter.next() {
                    try newBuffer!.setValue(element.value, forKey: element.key, uniquingKeysWith: combine)
                    if newBuffer!.tableIsTooTight {
                        newBuffer!.resizeTo(newCapacity: newBuffer!.capacity * 2)
                    }
                }
            }
            
        }
        self.init(buffer: newBuffer)
    }
    
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
    
    public func getValue(forKey k: Key) -> Value? {
        buffer?.getValue(forKey: k)
    }
    
    @discardableResult
    public mutating func updateValue(_ v: Value, forKey k: Key) -> Value? {
        makeUniqueEventuallyIncreasingCapacity()
        
        return buffer!.updateValue(v, forKey: k)
    }
    
    @discardableResult
    public mutating func removeValue(forKey k: Key) -> Value? {
        makeUniqueEventuallyReducingCapacity()
        
        return buffer?.removeElement(withKey: k)
    }
    
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
    public mutating func reserveCapacity(_ minimumCapacity: Int) {
        precondition(minimumCapacity >= 0, "minimumCapacity must not be negative")
        makeUniqueReserving(minimumCapacity: minimumCapacity)
    }
    
    public mutating func merge<S: Sequence>(_ keysAndValues: S, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows where S.Iterator.Element == Element {
        if let other = keysAndValues as? SeparateChainingHashTable<Key, Value> {
            try merge(other, uniquingKeysWith: combine)
        } else {
            makeUnique()
            try buffer!.merge(keysAndValues, uniquingKeysWith: combine)
        }
    }
    
    public mutating func merge(_ other: SeparateChainingHashTable, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows {
        makeUnique()
        guard !other.isEmpty else { return }
        
        try! buffer!.merge(other.buffer!, uniquingKeysWith: combine)
    }
    
    func merging(_ other: SeparateChainingHashTable, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows -> SeparateChainingHashTable {
        guard !isEmpty else { return other }
        
        guard !other.isEmpty else { return self }
        
        let mergedBuffer = (buffer!.copy() as! HashTableBuffer<Key, Value>)
        try mergedBuffer.merge(other.buffer!, uniquingKeysWith: combine)
        
        return SeparateChainingHashTable(buffer: mergedBuffer)
    }
    
    func merging<S>(_ other: S, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows -> SeparateChainingHashTable where S : Sequence, S.Element == Element {
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
    
    public func mapValues<T>(_ transform: (Value) throws -> T) rethrows -> SeparateChainingHashTable<Key, T> {
        let mappedBuffer = try buffer?.mapValues(transform)
        
        return SeparateChainingHashTable<Key, T>(buffer: mappedBuffer)
    }
    
    public func compactMapValues<T>(_ transform: (Value) throws -> T?) rethrows -> SeparateChainingHashTable<Key, T> {
        let mappedBuffer = try buffer?.compactMapValues(transform)
        
        return SeparateChainingHashTable<Key, T>(buffer: mappedBuffer)
    }
    
    public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> SeparateChainingHashTable {
        let filtered = try self.buffer?.filter(isIncluded)
        
        return SeparateChainingHashTable(buffer: filtered)
    }
    
    @discardableResult
    public mutating func remove(at index: Index) -> Element {
        precondition(index.isValidFor(self), "invalid index for this hash table")
        precondition(index.currentBag != nil, "index out of bounds")
        let removedElement = index.currentBag!.element
        makeUniqueEventuallyReducingCapacity()
        defer { removeValue(forKey: removedElement.key) }
        
        return removedElement
    }
    
}

// MARK: - C.O.W. internal utilities
extension SeparateChainingHashTable {
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
    
    mutating func makeUniqueEventuallyReducingCapacity() {
        guard
            !isEmpty
        else {
            id = ID()
            buffer = nil
            
            return
        }
        
        guard
            (buffer!.tableIsTooSparse)
        else {
            makeUnique()
            
            return
        }
        
 
        id = ID()
        let mCapacity = Swift.max(capacity / 2, Self.minBufferCapacity)
        buffer = buffer!.clone(newCapacity: mCapacity)
    }
    
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
    
    mutating func makeUnique() {
        id = ID()
        if !isKnownUniquelyReferenced(&buffer) {
            buffer = buffer?.copy() as? HashTableBuffer<Key, Value> ?? HashTableBuffer(minimumCapacity: Self.minBufferCapacity)
        }
    }
    
}

// MARK: - Sequence conformance
extension SeparateChainingHashTable: Sequence {
    public var underestimatedCount: Int { count }
    
    public func makeIterator() -> AnyIterator<Element> {
        guard
            !isEmpty
        else {
            
            return AnyIterator { return nil }
        }
        
        return buffer!.makeIterator()
    }
    
}

// MARK: - Collection conformance
extension SeparateChainingHashTable: Collection {
    public struct Index: Comparable {
        internal var id: ID
        
        internal var currentTableIndex: Int
        
        internal unowned(unsafe) var currentBag: HashTableBuffer<Key, Value>.Bag?
        
        internal unowned(unsafe) var buffer: HashTableBuffer<Key, Value>?
        
        internal init(asStartIndexOf ht: SeparateChainingHashTable) {
            self.id = ht.id
            self.currentTableIndex = 0
            self.buffer = ht.buffer
            moveToNextElement()
        }
        
        internal init(asEndIndexOf ht: SeparateChainingHashTable) {
            self.id = ht.id
            self.buffer = ht.buffer
            self.currentTableIndex = ht.capacity
        }
        
        internal init(asIndexOfKey k: Key, for ht: SeparateChainingHashTable) {
            self.id = ht.id
            self.buffer = ht.buffer
            self.currentTableIndex = 0
            while currentTableIndex < (buffer?.capacity ?? 0) {
                currentBag = self.buffer?.table[currentTableIndex]
                while let e = currentBag {
                    guard e.key != k else { return }
                    
                    currentBag = e.next
                }
                
                currentTableIndex += 1
            }
        }
        
        internal mutating func moveToNextElement() {
            guard
                buffer != nil
            else { return }
            
            currentBag = currentBag?.next
            
            if currentBag == nil {
                while currentTableIndex < buffer!.capacity {
                    if let bag = buffer!.table[currentTableIndex] {
                        currentBag = bag
                        currentTableIndex += 1
                        
                        break
                    }
                    currentTableIndex += 1
                }
            }
        }
        
        internal func isValidFor(_ ht: SeparateChainingHashTable) -> Bool {
            id === ht.id && buffer === ht.buffer
        }
        
        internal static func areValid(lhs: Index, rhs: Index) -> Bool {
            lhs.id === rhs.id && lhs.buffer === rhs.buffer
        }
        
        public static func == (lhs: Index, rhs: Index) -> Bool {
            precondition(areValid(lhs: lhs, rhs: rhs), "indexes from two different hash tables cannot be compared")
            
            return lhs.currentTableIndex == rhs.currentTableIndex && lhs.currentBag === rhs.currentBag
        }
        
        // MARK: - Index Comparable conformance
        public static func < (lhs: Index, rhs: Index) -> Bool {
            precondition(areValid(lhs: lhs, rhs: rhs), "indexes from two different hash tables cannot be compared")
            guard
                lhs.currentTableIndex != rhs.currentTableIndex
            else {
                switch (lhs.currentBag, rhs.currentBag) {
                case (nil, nil): return false
                case (.some(_ ), nil): return true
                case (nil, .some(_ )): return false
                case (.some(let lB), .some(let rB)):
                    if lB === rB { return false }
                    return rB.count < lB.count
                }
            }
            
            return lhs.currentTableIndex < rhs.currentTableIndex
        }
        
    }
    
    public var startIndex: Index { Index(asStartIndexOf: self) }
    
    public var endIndex: Index { Index(asEndIndexOf: self) }
    
    public func formIndex(after i: inout Index) {
        precondition(i.isValidFor(self), "invalid index for this hash table")
        
        i.moveToNextElement()
    }
    
    public func index(after i: Index) -> Index {
        precondition(i.isValidFor(self), "invalid index for this hash table")
        
        var nextIndex = i
        nextIndex.moveToNextElement()
        
        return nextIndex
    }
    
    public subscript(position: Index) -> (key: Key, value: Value) {
        get {
            precondition(position.isValidFor(self), "invalid index for this hash table")
            precondition(position.currentBag != nil, "index out of bounds")
           
            return position.currentBag!.element
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
        
        let keysAndValues = zip(keys, values)
            .lazy
            .map { (key: $0.0, value: $0.1) }
        try self.init(keysAndValues, uniquingKeysWith: { _, _ in
            throw Error.duplicateKeys
        })
    }
    
}
