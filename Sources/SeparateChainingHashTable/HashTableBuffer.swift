//
//  HashTableBuffer.swift
//  SeparateChainingHashTable
//
//  Created by Valeriano Della Longa on 2021/02/18.
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

final class HashTableBuffer<Key: Hashable, Value>: NSCopying {
    static var minTableCapacity: Int { 3 }
    
    private(set) var table: UnsafeMutablePointer<Bag?>
    
    private(set) var firstTableElement: Int
    
    private(set) var capacity: Int
    
    private(set) var count: Int
    
    var isEmpty: Bool { count == 0 }
    
    var tableIsTooTight: Bool { count >= capacity }
    
    var tableIsTooSparse: Bool { capacity > Self.minTableCapacity && count <= capacity / 4 }
    
    init(minimumCapacity capacity: Int) {
        precondition(capacity >= Self.minTableCapacity, "capacity must be greater than or equal to \(Self.minTableCapacity)")
        self.count = 0
        
        self.capacity = capacity
        
        self.table = UnsafeMutablePointer.allocate(capacity: capacity)
        
        self.table.initialize(repeating: nil, count: capacity)
        
        self.firstTableElement = capacity
    }
    
    private init(capacity: Int, count: Int, table: UnsafeMutablePointer<Bag?>, firstTableElementIndex: Int) {
        self.capacity = capacity
        self.count = count
        self.table = table
        self.firstTableElement = firstTableElementIndex
    }
    
    deinit {
        self.table.deinitialize(count: capacity)
        self.table.deallocate()
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let tableCopy = UnsafeMutablePointer<Bag?>.allocate(capacity: capacity)
        for idx in 0..<capacity {
            tableCopy.advanced(by: idx).initialize(to: table[idx]?.copy(with: zone) as? Bag)
        }
        let clone = HashTableBuffer(capacity: capacity, count: count, table: tableCopy, firstTableElementIndex: firstTableElement)
        
        return clone
    }
    
    @inlinable
    func updateFirstTableElement() {
        firstTableElement = capacity
        for idx in 0..<capacity where table[idx] != nil {
            firstTableElement = idx
            
            break
        }
    }
    
    @inlinable
    func hashIndex(forKey k: Key) -> Int {
        Self.hashIndex(forKey: k, inBufferOfCapacity: capacity)
    }
    
    @inlinable
    static func hashIndex(forKey k: Key, inBufferOfCapacity capacity: Int) -> Int {
        var hasher = Hasher()
        hasher.combine(k)
        let hv = hasher.finalize()
        
        return (hv & 0x7fffffff) % capacity
    }
    
    @inlinable
    @discardableResult
    func getValue(forKey k: Key) -> Value? {
        let idx = hashIndex(forKey: k)
        
        return table[idx]?.getValue(forKey: k)
    }
    
    @discardableResult
    @inlinable
    func updateValue(_ v: Value, forKey k: Key) -> Value? {
        let idx = hashIndex(forKey: k)
        
        guard let bag = table[idx] else {
            table[idx] = Bag(key: k, value: v)
            count += 1
            if idx < firstTableElement { firstTableElement = idx }
            
            return nil
        }
        
        let prevBagCount = bag.count
        let result = bag.updateValue(v, forKey: k)
        if bag.count > prevBagCount { count += 1 }
        
        return result
    }
    
    func setValue(_ v: Value, forKey k: Key, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows {
        let idx = hashIndex(forKey: k)
        
        guard
            let bag = table[idx]
        else {
            let bag = Bag(key: k, value: v)
            table[idx] = bag
            count += 1
            if idx < firstTableElement { firstTableElement = idx }
            
            return
        }
        
        let prevBagCount = bag.count
        try bag.setValue(v, forKey: k, uniquingKeysWith: combine)
        if bag.count > prevBagCount { count += 1 }
    }
    
    @inlinable
    func setValue(_ v: Value, forKey k: Key) {
        setValue(v, forKey: k, uniquingKeysWith: { _, newValue in
            newValue
        })
    }
    
    @discardableResult
    @inlinable
    func removeElement(withKey k: Key) -> Value? {
        let idx = hashIndex(forKey: k)
        
        guard
            let bag = table[idx]
        else { return nil }
        
        let prevBagCount = bag.count
        let r = bag.removingValue(forKey: k)
        table[idx] = r.afterRemoval
        let actualBagCount = table[idx]?.count ?? 0
        if prevBagCount > actualBagCount {
            count -= 1
            if actualBagCount == 0 && idx <= firstTableElement {
                updateFirstTableElement()
            }
        }
        
        return r.removedValue
    }
    
    @inlinable
    func merge<S: Sequence>(_ keysAndValues: S, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows where S.Iterator.Element == Element {
        if let other = keysAndValues as? HashTableBuffer {
            try merge(other, uniquingKeysWith: combine)
            
            return
        }
        
        let done: Bool = try keysAndValues
            .withContiguousStorageIfAvailable { kvBuffer in
                guard
                    kvBuffer.baseAddress != nil && kvBuffer.count > 0
                else { return true }
                
                let newCapacity = self.count + kvBuffer.count >= self.capacity ? Swift.max((((self.count + kvBuffer.count) * 3) / 2), self.capacity * 2) : capacity
                self.resizeTo(newCapacity: newCapacity)
                for keyValuePair in kvBuffer {
                    try self.setValue(keyValuePair.value, forKey: keyValuePair.key, uniquingKeysWith: combine)
                }
                
                return true
            } ?? false
        guard !done else { return }
        
        var otherIter = keysAndValues.makeIterator()
        guard
            let firstOther = otherIter.next()
        else { return }
        
        let additionalCount = Swift.max(1, keysAndValues.underestimatedCount)
        let newCapacity = count + additionalCount >= capacity ? capacity : Swift.max((((count + additionalCount) * 3) / 2), capacity * 2)
        resizeTo(newCapacity: newCapacity)
        try self.setValue(firstOther.value, forKey: firstOther.key, uniquingKeysWith: combine)
        while let otherElement = otherIter.next() {
            try self.setValue(otherElement.value, forKey: otherElement.key, uniquingKeysWith: combine)
            if tableIsTooTight {
                let newCapacity = Swift.max((count * 3 / 2), capacity * 2)
                resizeTo(newCapacity: newCapacity)
            }
        }
    }
    
    @inlinable
    func merge(_ other: HashTableBuffer, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows {
        guard
            !other.isEmpty
        else { return }
        
        let newCapacity = count + other.count >= capacity ? Swift.max((((count + other.count) * 3) / 2), capacity * 2) : capacity
        resizeTo(newCapacity: newCapacity)
        for element in other {
            try setValue(element.value, forKey: element.key, uniquingKeysWith: combine)
        }
    }
    
    @inlinable
    func mapValues<T>(_ transform: (Value) throws -> T) rethrows -> HashTableBuffer<Key, T> {
        let mappedTable = UnsafeMutablePointer<HashTableBuffer<Key, T>.Bag?>.allocate(capacity: capacity)
        for idx in 0..<capacity {
            if let bag = table[idx] {
                let mappedBag = try bag.mapValue(transform)
                mappedTable.advanced(by: idx).initialize(to: mappedBag)
            } else {
                mappedTable.advanced(by: idx).initialize(to: nil)
            }
        }
        
        return HashTableBuffer<Key, T>.init(capacity: capacity, count: count, table: mappedTable, firstTableElementIndex: firstTableElement)
    }
    
    @inlinable
    func compactMapValues<T>(_ transform: (Value) throws -> T?) rethrows -> HashTableBuffer<Key, T> {
        let mappedTable = UnsafeMutablePointer<HashTableBuffer<Key, T>.Bag?>.allocate(capacity: capacity)
        var newCount = 0
        var mappedFirstTableIndex = capacity
        for idx in 0..<capacity {
            var mappedBag: HashTableBuffer<Key, T>.Bag? = nil
            if let bag = table[idx] {
                mappedBag = try bag.compactMapValue(transform)
            }
            mappedTable.advanced(by: idx).initialize(to: mappedBag)
            let mappedBagCount = mappedBag?.count ?? 0
            newCount += mappedBagCount
            if mappedBagCount > 0 && idx < mappedFirstTableIndex {
                mappedFirstTableIndex = idx
            }
        }
        
        return HashTableBuffer<Key, T>(capacity: capacity, count: newCount, table: mappedTable, firstTableElementIndex: mappedFirstTableIndex)
    }
    
    @inlinable
    func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> HashTableBuffer {
        let filteredTable = UnsafeMutablePointer<Bag?>.allocate(capacity: capacity)
        var filteredCount = 0
        var filteredFirstTableIndex = capacity
        for idx in 0..<capacity {
            try filteredTable
                .advanced(by: idx)
                .initialize(to: table[idx]?.clone().filter(isIncluded))
            let thisFilteredBagCount = filteredTable[idx]?.count ?? 0
            filteredCount += thisFilteredBagCount
            if thisFilteredBagCount > 0 && idx < filteredFirstTableIndex {
                filteredFirstTableIndex = idx
            }
        }
        
        return HashTableBuffer(capacity: capacity, count: filteredCount, table: filteredTable, firstTableElementIndex: filteredFirstTableIndex)
    }
    
    @inlinable
    func clone(newCapacity k: Int) -> HashTableBuffer {
        precondition(k >= Self.minTableCapacity, "capacity must be greater than or equal \(Self.minTableCapacity)")
        guard
            k != capacity
        else { return copy() as! HashTableBuffer<Key, Value> }
        
        let cloneTable = UnsafeMutablePointer<Bag?>.allocate(capacity: k)
        cloneTable.initialize(repeating: nil, count: k)
        var cloneFirstTableIndex = k
        for thisIdx in 0..<capacity {
            var clonedBag: Bag? = table[thisIdx]?.clone()
            while let element = clonedBag?.element {
                let idx = Self.hashIndex(forKey: element.key, inBufferOfCapacity: k)
                if let newBag = cloneTable[idx] {
                    newBag.setValue(element.value, forKey: element.key)
                } else {
                    cloneTable[idx] = Bag(element)
                }
                clonedBag = clonedBag?.next
                if idx < cloneFirstTableIndex {
                    cloneFirstTableIndex = idx
                }
            }
        }
        
        return HashTableBuffer(capacity: k, count: count, table: cloneTable, firstTableElementIndex: cloneFirstTableIndex)
    }
    
    @inlinable
    func resizeTo(newCapacity: Int) {
        precondition(newCapacity >= Self.minTableCapacity, "newCapacity must be greater than or equal to minTableCapacity")
        guard
            newCapacity != capacity
        else { return }
        
        let newTable = UnsafeMutablePointer<Bag?>.allocate(capacity: newCapacity)
        newTable.initialize(repeating: nil, count: newCapacity)
        firstTableElement = newCapacity
        for idx in 0..<capacity {
            let bag = self.table.advanced(by: idx).move()
            if let oldBag = bag {
                for element in oldBag {
                    let newIdx = Self.hashIndex(forKey: element.key, inBufferOfCapacity: newCapacity)
                    if let newBag = newTable[newIdx] {
                        newBag.setValue(element.value, forKey: element.key)
                    } else {
                        newTable[newIdx] = Bag(element)
                    }
                    if newIdx < firstTableElement {
                        firstTableElement = newIdx
                    }
                }
            }
        }
        self.table.deallocate()
        self.capacity = newCapacity
        self.table = newTable
    }
    
}

// MARK: - Sequence conformance
extension HashTableBuffer: Sequence {
    typealias Element = (key: Key, value: Value)
    
    @inlinable
    var underestimatedCount: Int { count }
    
    func makeIterator() -> AnyIterator<Element> {
        var currentIdx: Int = firstTableElement
        var currentBagIterator: AnyIterator<Element>?
 
        return AnyIterator { 
            guard
                let nextElement = currentBagIterator?.next()
            else {
                while currentIdx < self.capacity {
                    if let bag = self.table[currentIdx] {
                        currentIdx += 1
                        currentBagIterator = bag.makeIterator()
                        break
                    }
                    currentIdx += 1
                }
                
                return currentBagIterator?.next()
            }
            
            return nextElement
        }
    }
    
}

// MARK: - Equatable conformance
extension HashTableBuffer: Equatable where Value: Equatable {
    static func == (lhs: HashTableBuffer<Key, Value>, rhs: HashTableBuffer<Key, Value>) -> Bool {
        guard lhs !== rhs else { return true }
        
        guard
            lhs.capacity == rhs.capacity,
            lhs.count == rhs.count
        else { return false }
        
        guard lhs.table != rhs.table else { return true }
        
        for idx in 0..<lhs.capacity where lhs.table[idx] != rhs.table[idx] {
            return false
        }
        
        return true
    }
    
}

// MARK: - Hashable conformance
extension HashTableBuffer: Hashable where Value: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(capacity)
        hasher.combine(count)
        for idx in 0..<capacity {
            hasher.combine(table[idx])
        }
    }
    
}

// MARK: - Bag
extension HashTableBuffer {
    final class Bag: NSCopying {
        typealias Element = (key: Key, value: Value)
        
        var key: Key
        
        var value: Value
        
        var next: Bag? = nil
        
        var count: Int = 1
        
        var element: Element { (key, value) }
        
        init(key: Key, value: Value) {
            self.key = key
            self.value = value
        }
        
        init(_ element: Element) {
            self.key = element.key
            self.value = element.value
        }
        
        func copy(with zone: NSZone? = nil) -> Any {
            let kClone: Key!
            let vClone: Value!
            if let k = key as? NSCopying {
                kClone = (k.copy(with: zone) as! Key)
            } else {
                kClone = key
            }
            if let v = value as? NSCopying {
                vClone = (v.copy(with: zone) as! Value)
            } else {
                vClone = value
            }
            
            let clone = Bag(key: kClone, value: vClone)
            clone.count = count
            clone.next = next?.copy(with: zone) as? Bag
            
            return clone
        }
        
        @inlinable
        func clone() -> Bag {
            copy() as! Bag
        }
        
        @discardableResult
        func getValue(forKey k: Key) -> Value? {
            guard key != k else { return value }
            
            return next?.getValue(forKey: k)
        }
        
        @discardableResult
        func updateValue(_ v: Value, forKey k: Key) -> Value? {
            guard
                k != key
            else {
                let oldValue = value
                value = v
                
                return oldValue
            }
            
            guard
                next != nil
            else {
                next = Bag(key: k, value: v)
                count += 1
                
                return nil
            }
    
            let result = next!.updateValue(v, forKey: k)
            updateCount()
            
            return result
        }
        
        func setValue(_ v: Value, forKey k: Key, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows {
            guard key != k else {
                let newValue = try combine(value, v)
                value = newValue
                
                return
            }
            
            guard next != nil else {
                next = Bag(key: k, value: v)
                count += 1
                
                return
            }
            
            try next!.setValue(v, forKey: k, uniquingKeysWith: combine)
            updateCount()
        }
        
        @inlinable
        func setValue(_ v: Value, forKey k: Key) {
            setValue(v, forKey: k, uniquingKeysWith: { _, new in new })
        }
        
        func removingValue(forKey k: Key) -> (afterRemoval: Bag?, removedValue: Value?) {
            guard k != key else {
                let n = next
                next = nil
                
                return (n, value)
            }
            
            let removingOnNext = next?.removingValue(forKey: k)
            self.next = removingOnNext?.afterRemoval
            updateCount()
            
            return (self, removingOnNext?.removedValue)
        }
        
        func mapValue<T>(_ transform: (Value) throws -> T) rethrows -> HashTableBuffer<Key, T>.Bag {
            let mappedValue: T = try transform(value)
            let mappedBag = HashTableBuffer<Key, T>.Bag(key: key, value: mappedValue)
            mappedBag.count = count
            mappedBag.next = try next?.mapValue(transform)
            
            return mappedBag
        }
        
        func compactMapValue<T>(_ transform: (Value) throws -> T?) rethrows -> HashTableBuffer<Key, T>.Bag? {
            guard
                let mappedValue = try transform(value)
            else {
                
                return try next?.compactMapValue(transform)
            }
            
            let mappedBag = HashTableBuffer<Key, T>.Bag(key: key, value: mappedValue)
            mappedBag.next = try next?.compactMapValue(transform)
            mappedBag.updateCount()
            
            return mappedBag
        }
        
        func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> Bag? {
            guard
                try isIncluded(element)
            else {
                return try next?.filter(isIncluded)
            }
            next = try next?.filter(isIncluded)
            updateCount()
            
            return self
        }
        
        @inline(__always)
        private func updateCount() {
            count = 1 + (next?.count ?? 0)
        }
        
    }
    
}

extension HashTableBuffer.Bag: Sequence {
    @inlinable
    var underestimatedCount: Int { count }
    
    func makeIterator() -> AnyIterator<Element> {
        unowned(unsafe) var current: HashTableBuffer.Bag? = self
        
        return AnyIterator {
            defer { current = current?.next }
            
            return current?.element
        }
    }
    
}

extension HashTableBuffer.Bag: Equatable where Value: Equatable {
    static func == (lhs: HashTableBuffer<Key, Value>.Bag, rhs: HashTableBuffer<Key, Value>.Bag) -> Bool {
        guard lhs !== rhs else { return true }
        
        guard
            lhs.count == rhs.count,
            lhs.key == rhs.key,
            lhs.value == rhs.value
        else { return false }
        
        switch (lhs.next, rhs.next) {
        case (nil, nil): return true
        case (.some(let lN), .some(let rN)):
            return lN == rN
        default:
            return false
        }
    }
    
}

extension HashTableBuffer.Bag: Hashable where Value: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(count)
        hasher.combine(key)
        hasher.combine(value)
        next?.hash(into: &hasher)
    }
    
}
