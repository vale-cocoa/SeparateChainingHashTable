//
//  Node.swift
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

extension SeparateChainingHashTable {
    final class Node: NSCopying {
        typealias Element = (Key, Value)
        
        var key: Key
        
        var value: Value
        
        var next: Node? = nil
        
        var count: Int = 1
        
        var element: Element { (key, value) }
        
        init(key: Key, value: Value) {
            self.key = key
            self.value = value
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
            
            let clone = Node(key: kClone, value: vClone)
            clone.count = count
            clone.next = next?.copy(with: zone) as? Node
            
            return clone
        }
        
        func clone() -> Node {
            copy() as! Node
        }
        
        @discardableResult
        func getValue(forKey k: Key) -> Value? {
            guard key != k else { return value }
            
            return next?.getValue(forKey: k)
        }
        
        func setValue(_ v: Value, forKey k: Key, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows {
            guard key != k else {
                let newValue = try combine(value, v)
                value = newValue
                
                return
            }
            
            guard next != nil else {
                next = Node(key: k, value: v)
                count += 1
                
                return
            }
            
            try next!.setValue(v, forKey: k, uniquingKeysWith: combine)
            updateCount()
        }
        
        func setValue(_ v: Value, forKey k: Key) {
            setValue(v, forKey: k, uniquingKeysWith: { _, new in new })
        }
        
        func removingValue(forKey k: Key) -> Node? {
            guard k != key else {
                let n = next
                next = nil
                
                return n
            }
            
            next = next?.removingValue(forKey: k)
            updateCount()
            
            return self
        }
        
        @inline(__always)
        private func updateCount() {
            count = 1 + (next?.count ?? 0)
        }
        
    }
    
}

extension SeparateChainingHashTable.Node: Sequence {
    var underestimatedCount: Int {
        count
    }
    
    func makeIterator() -> AnyIterator<Element> {
        AnyIterator(_Iterator(self))
    }
    
    private struct _Iterator: IteratorProtocol {
        unowned(unsafe) var currentNode: SeparateChainingHashTable.Node?
        
        init(_ node: SeparateChainingHashTable.Node) {
            withExtendedLifetime(node, { currentNode = $0 })
        }
        
        mutating func next() -> Element? {
            defer {
                if currentNode?.next != nil {
                    withExtendedLifetime(currentNode!.next!, {  currentNode = $0 })
                } else {
                    currentNode = nil
                }
            }
            
            return currentNode?.element
        }
    }
    
}

