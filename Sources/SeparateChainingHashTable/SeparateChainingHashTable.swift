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

public final class SeparateChainingHashTable<Key: Hashable, Value>: NSCopying {
    public internal(set) var count: Int
    
    public internal(set) var capacity: Int
    
    internal private(set) var hashTableCapacity: Int
    
    internal private(set) var hashTable: UnsafeMutablePointer<Node?>
    
    public init(minimumCapacity capacity: Int) {
        self.hashTableCapacity = Self.hashTableCapacityFor(requestedCapacity: capacity)
        self.capacity = capacity
        self.count = 0
        self.hashTable = UnsafeMutablePointer<Node?>.allocate(capacity: hashTableCapacity)
        self.hashTable.initialize(repeating: nil, count: hashTableCapacity)
    }
    
    deinit {
        hashTable.deinitialize(count: hashTableCapacity)
        hashTable.deallocate()
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let clone = SeparateChainingHashTable(minimumCapacity: 0)
        clone.capacity = capacity
        clone.count = count
        clone.hashTableCapacity = hashTableCapacity
        clone.hashTable = UnsafeMutablePointer.allocate(capacity: hashTableCapacity)
        for i in 0..<hashTableCapacity {
            let copiedNode = hashTable[i]?.copy(with: zone) as? Node
            clone.hashTable.advanced(by: i).initialize(to: copiedNode)
        }
        
        return clone
    }
    
    internal init(_ other: SeparateChainingHashTable) {
        self.capacity = other.capacity
        self.count = other.count
        self.hashTableCapacity = other.hashTableCapacity
        self.hashTable = UnsafeMutablePointer.allocate(capacity: hashTableCapacity)
        for i in 0..<hashTableCapacity {
            let otherNodeClone = other.hashTable[i]?.clone()
            self.hashTable.advanced(by: i).initialize(to: otherNodeClone)
        }
    }
    
}

// MARK: - Computed properties
extension SeparateChainingHashTable {
    @inlinable
    public var isFull: Bool { availableFreeCapacity == 0 }
    
    @inlinable
    public var isEmpty: Bool { count == 0 }
    
    @inlinable
    var availableFreeCapacity: Int { capacity - count }
    
}

// MARK: - Convenience initializers
extension SeparateChainingHashTable {
    public convenience init<S: Sequence>(uniqueKeysWithValues keysAndValues: S) where S.Iterator.Element == Element {
        self.init(keysAndValues) { _, _ in
            preconditionFailure("keys must be unique")
        }
    }
    
    public convenience init<S>(_ keysAndValues: S, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows where S : Sequence, S.Iterator.Element == Element {
        if let other = keysAndValues as? SeparateChainingHashTable<Key, Value> {
            self.init(other)
        } else {
            self.init(minimumCapacity: keysAndValues.underestimatedCount)
            var iter = keysAndValues.makeIterator()
            while let element = iter.next() {
                try self.setValue(element.1, forKey: element.0, uniquingKeysWith: combine)
            }
        }
    }
    
    public convenience init<S>(grouping values: S, by keyForValue: (S.Element) throws -> Key) rethrows where Value == [S.Element], S : Sequence {
        self.init(minimumCapacity: values.underestimatedCount)
        var valuesIter = values.makeIterator()
        
        while let value = valuesIter.next() {
            let key = try keyForValue(value)
            self.setValue([value], forKey: key, uniquingKeysWith: +)
        }
    }
    
}

// MARK: - Public methods
extension SeparateChainingHashTable {
    public func clone() -> SeparateChainingHashTable {
        SeparateChainingHashTable(self)
    }
    
    public func reserveCapacity(_ k: Int) {
        let needed = hashTableCapacityNeededTo(reserveCapacity: k)
        guard needed > hashTableCapacity else { return }
        
        self.capacity = count + k
        resizeHashTableTo(hashTableCapacity: needed)
    }
    
    public func merge<S: Sequence>(_ keysAndValues: S, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows where S.Iterator.Element == Element {
        if let other = keysAndValues as? SeparateChainingHashTable<Key, Value> {
            try merge(other, uniquingKeysWith: combine)
        } else {
            var iter = keysAndValues.makeIterator()
            while let element = iter.next() {
                try setValue(element.1, forKey: element.0, uniquingKeysWith: combine)
            }
        }
    }
    
    public func merge(_ other: SeparateChainingHashTable, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows {
        guard !other.isEmpty else { return }
        
        var keysAndValues: [Element] = Array(UnsafeBufferPointer(start: other.hashTable, count: other.hashTableCapacity))
            .compactMap { $0 }
            .flatMap { $0 }
        let newCapacity = count + other.count
        let newHTCapacity = hashTableCapacityNeededTo(reserveCapacity: newCapacity)
        if newHTCapacity > hashTableCapacity {
            let thisKeysAndValues: [Element] = Array(UnsafeBufferPointer(start: hashTable, count: hashTableCapacity))
                .compactMap { $0 }
                .flatMap { $0 }
            keysAndValues.append(contentsOf: thisKeysAndValues)
            capacity = newCapacity
            hashTable.deinitialize(count: hashTableCapacity)
            hashTable.deallocate()
            hashTable = UnsafeMutablePointer.allocate(capacity: newHTCapacity)
            hashTable.initialize(repeating: nil, count: newHTCapacity)
            hashTableCapacity = newHTCapacity
            count = 0
        }
        for element in keysAndValues {
            let idx = hashIndex(forKey: element.0)
            if let n = hashTable[idx] {
                let prevNCount = n.count
                try n.setValue(element.1, forKey: element.0, uniquingKeysWith: combine)
                if prevNCount < n.count {
                    count += 1
                }
            } else {
                let n = Node(key: element.0, value: element.1)
                hashTable[idx] = n
                count += 1
            }
        }
    }
    
    public func mapValues<T>(_ transform: (Value) throws -> T) rethrows -> SeparateChainingHashTable<Key, T> {
        let mapped = SeparateChainingHashTable<Key, T>(minimumCapacity: 0)
        mapped.hashTable.deinitialize(count: mapped.hashTableCapacity)
        mapped.hashTable.deallocate()
        mapped.capacity = capacity
        mapped.hashTableCapacity = hashTableCapacity
        mapped.hashTable = UnsafeMutablePointer.allocate(capacity: mapped.hashTableCapacity)
        mapped.hashTable.initialize(repeating: nil, count: hashTableCapacity)
        for idx in 0..<hashTableCapacity where hashTable[idx] != nil {
            let newNode = try SeparateChainingHashTable<Key, T>.Node(key: hashTable[idx]!.key, value: transform(hashTable[idx]!.value))
            var current = hashTable[idx]?.next
            while current != nil {
                try newNode.setValue(transform(current!.value), forKey: current!.key)
                current = current?.next
            }
            mapped.hashTable[idx] = newNode
        }
        mapped.count = count
        
        return mapped
    }
    
    func compactMapValues<T>(_ transform: (Value) throws -> T?) rethrows -> SeparateChainingHashTable<Key, T> {
        let mapped = SeparateChainingHashTable<Key, T>(minimumCapacity: 0)
        mapped.hashTable.deinitialize(count: mapped.hashTableCapacity)
        mapped.hashTable.deallocate()
        mapped.capacity = capacity
        mapped.hashTableCapacity = hashTableCapacity
        mapped.hashTable = UnsafeMutablePointer.allocate(capacity: mapped.hashTableCapacity)
        mapped.hashTable.initialize(repeating: nil, count: hashTableCapacity)
        for idx in 0..<hashTableCapacity {
            var current = hashTable[idx]
            while let currentElement = current?.element {
                if let mappedValue = try transform(currentElement.1) {
                    let mIdx = mapped.hashIndex(forKey: currentElement.0)
                    if let mNode = mapped.hashTable[mIdx] {
                        mNode.setValue(mappedValue, forKey: currentElement.0)
                    } else {
                        let mNode = SeparateChainingHashTable<Key, T>.Node(key: currentElement.0, value: mappedValue)
                        mapped.hashTable[mIdx] = mNode
                    }
                    count += 1
                }
                current = current?.next
            }
        }
        
        return mapped
    }
    
}

// MARK: - C.R.U.D.
extension SeparateChainingHashTable {
    @discardableResult
    public func getValue(forKey k: Key) -> Value? {
        let idx = hashIndex(forKey: k)
        
        return hashTable[idx]?.getValue(forKey: k)
    }
    
    public func setValue(_ v: Value, forKey k: Key, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows {
        resizeCapacityIfNeeded()
        let idx = hashIndex(forKey: k)
        if let node = hashTable[idx] {
            let prevNodeCount = node.count
            try node.setValue(v, forKey: k, uniquingKeysWith: combine)
            count += prevNodeCount < node.count ? 1 : 0
        } else {
            let newNode = Node(key: k, value: v)
            hashTable[idx] = newNode
            count += 1
        }
    }
    
    public func setValue(_ v: Value, forKey k: Key) {
        setValue(v, forKey: k, uniquingKeysWith: { _, newValue in newValue })
    }
    
    public func removeValue(forKey k: Key) {
        let idx = hashIndex(forKey: k)
        guard
            let node = hashTable[idx]
        else { return }
        
        let prevNodeCount = node.count
        hashTable[idx] = node.removingValue(forKey: k)
        if prevNodeCount > (hashTable[idx]?.count ?? 0) {
            count -= 1
            resizeCapacityIfNeeded()
        }
    }
    
}

// MARK: - Helpers
extension SeparateChainingHashTable {
    func hashIndex(forKey k: Key) -> Int {
        var hasher = Hasher()
        hasher.combine(k)
        let hasValue = hasher.finalize()
        
        return (hasValue & 0x7fffffff) % hashTableCapacity
    }
    
}

// MARK: - buffer resizing and capacity helpers
extension SeparateChainingHashTable {
    static var minHashTableCapacity: Int { 3 }
    
    static func hashTableCapacityFor(requestedCapacity k: Int) -> Int {
        precondition(k >= 0, "requested capacity must not be negative")
        guard k > 0 else { return Self.minHashTableCapacity }
        
        return ((k * 3) / 2)
    }
    
    func hashTableCapacityNeededTo(reserveCapacity k: Int) -> Int {
        precondition(k >= 0, "requested capacity must not be negative")
        guard
            k > availableFreeCapacity
        else { return hashTableCapacity }
        
        return Self.hashTableCapacityFor(requestedCapacity: count + k)
    }
    
    func resizeCapacityIfNeeded() {
        var newCapacity = capacity
        if isFull {
            newCapacity = capacity * 2
        } else if count <= capacity / 8 {
            newCapacity = capacity / 2
        }
        
        defer { capacity = newCapacity }
        
        let newHTCapacity = hashTableCapacityNeededTo(reserveCapacity: newCapacity)
        guard
            newHTCapacity != hashTableCapacity
        else { return }
        
        resizeHashTableTo(hashTableCapacity: newHTCapacity)
    }
    
    func resizeHashTableTo(hashTableCapacity k: Int) {
        assert(k >= ((count * 3) / 2), "proposed capacity must be greater than or equal 3/2 of current count")
        let oldHTCapacity = hashTableCapacity
        hashTableCapacity = k
        let newHashTable = UnsafeMutablePointer<Node?>.allocate(capacity: hashTableCapacity)
        newHashTable.initialize(repeating: nil, count: hashTableCapacity)
        for oldIdx in 0..<oldHTCapacity {
            var current = hashTable.advanced(by: oldIdx).move()
            while current != nil {
                let oldNext = current?.next
                current!.next = nil
                current!.count = 1
                let newIdx = hashIndex(forKey: current!.key)
                if newHashTable[newIdx] != nil {
                    let newNode = newHashTable.advanced(by: newIdx).move()!
                    current!.next = newNode
                    current!.count += newNode.count
                    newHashTable.advanced(by: newIdx).initialize(to: current)
                } else {
                    newHashTable[newIdx] = current
                }
                current = oldNext
            }
        }
        hashTable.deallocate()
        hashTable = newHashTable
    }
    
}

// MARK: - Sequence conformance
extension SeparateChainingHashTable: Sequence {
    public typealias Element = (Key, Value)
    
    public var underestimatedCount: Int { count }
    
    public func makeIterator() -> AnyIterator<Element> {
        withExtendedLifetime(self, { AnyIterator(_Iterator($0)) })
    }
    
    private struct _Iterator: IteratorProtocol {
        unowned(unsafe) var ht: SeparateChainingHashTable
        
        var currentIdx: Int = 0
        
        var currentNodeIterator: AnyIterator<Element>? = nil
        
        init(_ ht: SeparateChainingHashTable) {
            self.ht = ht
            moveToNextNodeIterator()
        }
        
        mutating func next() -> Element? {
            if let nextElement = currentNodeIterator?.next() {
                
                return nextElement
            } else {
                moveToNextNodeIterator()
            }
            
            return currentNodeIterator?.next()
        }
        
        private mutating func moveToNextNodeIterator() {
            while currentIdx < ht.hashTableCapacity {
                if ht.hashTable[currentIdx] != nil {
                    withExtendedLifetime(ht.hashTable[currentIdx]!, { currentNodeIterator = $0.makeIterator() })
                    currentIdx += 1
                    
                    return
                }
                currentIdx += 1
            }
        }
        
    }
    
}

// MARK: - ExpressibleByDictionaryLiteral conformance
extension SeparateChainingHashTable: ExpressibleByDictionaryLiteral {
    public convenience init(dictionaryLiteral elements: (Key, Value)...) {
        self.init(uniqueKeysWithValues: elements)
    }
    
}

// MARK: - Equatable conformance
extension SeparateChainingHashTable: Equatable where Value: Equatable {
    public static func == (lhs: SeparateChainingHashTable<Key, Value>, rhs: SeparateChainingHashTable<Key, Value>) -> Bool {
        guard lhs !== rhs else { return true }
            
        guard lhs.count == rhs.count else { return false }
        
        for (lE, rE) in zip(lhs, rhs) where lE.0 != rE.0 || lE.1 != rE.1 {
            return false
        }
        
        return true
    }
    
}

// MARK: - Hashable conformance
extension SeparateChainingHashTable: Hashable where Value: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(count)
        for element in self {
            hasher.combine(element.0)
            hasher.combine(element.1)
        }
    }
    
}

// MARK: - Codable conformance
extension SeparateChainingHashTable: Codable where Key: Codable, Value: Codable {
    public enum Error: Swift.Error {
        case duplicateKeys
        case keysAndValuesNotEqualCount
        
    }
    
    enum CodingKeys: String, CodingKey {
        case keys
        case values
    }
    
    public func encode(to encoder: Encoder) throws {
        var keys: [Key] = []
        var values: [Value] = []
        forEach {
            keys.append($0.0)
            values.append($0.1)
        }
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keys, forKey: .keys)
        try container.encode(values, forKey: .values)
    }
    
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let keys = try container.decode(Array<Key>.self, forKey: .keys)
        let values = try container.decode(Array<Value>.self, forKey: .values)
        guard
            keys.count == values.count
        else { throw Error.keysAndValuesNotEqualCount }
        
        try self.init(zip(keys, values), uniquingKeysWith: { _, _ in
            throw Error.duplicateKeys
        })
    }
    
}
