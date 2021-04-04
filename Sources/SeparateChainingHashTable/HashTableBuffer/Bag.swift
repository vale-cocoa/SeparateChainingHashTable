//
//  Bag.swift
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

import Foundation

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
    struct Iterator: IteratorProtocol {
        private let iter: AnyIterator<Element>
        
        fileprivate init(_ bag: HashTableBuffer.Bag) {
            unowned(unsafe) var currentBag: HashTableBuffer.Bag? = bag
            
            self.iter = AnyIterator {
                defer { currentBag = currentBag?.next }
                
                return currentBag?.element
            }
        }
        
        mutating func next() -> Element? {
            iter.next()
        }
        
    }
    
    @inlinable
    var underestimatedCount: Int { count }
    
    func makeIterator() -> Iterator { withExtendedLifetime(self, { Iterator($0) }) }
    
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
