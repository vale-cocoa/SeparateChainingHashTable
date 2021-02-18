//
//  TestsHelpers.swift
//  SeparateChainingHashTableTests
//
//  Created by Valeriano Della Longa on 2021/02/16.
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

import XCTest
@testable import SeparateChainingHashTable

// MARK: - Global constants and functions
let uppercaseLetters = "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z"
    .components(separatedBy: " ")

let lowerCaseLetters = "a b c d e f g h i j k l m n o p q r s t u v w x y z"
    .components(separatedBy: " ")

let allCasesLetters = uppercaseLetters + lowerCaseLetters

func randomKey(ofLenght l: Int = 1) -> String {
    assert(l > 0)
    var result = ""
    for _ in 1...l {
        result += allCasesLetters.randomElement()!
    }
    
    return result
}

func randomValue() -> Int {
    Int.random(in: 1...300)
}

let err = NSError(domain: "com.vdl.error", code: 1, userInfo: nil)

// MARK: - Elements for testing NSCopying
final class CKey: NSCopying, Equatable, Hashable {
    var k: String
    init(_ k: String) { self.k = k }
    
    static func ==(lhs: CKey, rhs: CKey) -> Bool {
        lhs.k == rhs.k
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(k)
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let kClone = (k as NSString).copy(with: zone) as! NSString
        
        return CKey(kClone as String)
    }
    
}

final class CValue: NSCopying, Equatable {
    var v: Int
    
    init(_ v: Int) { self.v = v }
    
    static func ==(lhs: CValue, rhs: CValue) -> Bool {
        return lhs.v == rhs.v
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let vClone = (v as NSNumber).copy(with: zone) as! NSNumber
        
        return CValue(vClone.intValue)
    }
    
}

struct SKey: Equatable, Hashable {
    var k: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(k)
    }
    
}

struct SValue: Equatable {
    var v: Int
    
}

// MARK: - Key types with bad hashing
struct VeryBadHashingKey: Equatable, Hashable {
    var k: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine("a")
    }
    
}

struct BadHashingKey: Equatable, Hashable {
    var k: String
    
    func hash(into hasher: inout Hasher) {
        let r = Int.random(in: 0...11)
        if r % 2 == 0 {
            hasher.combine(k)
        } else {
            hasher.combine("a")
        }
    }
    
}

struct SomeWhatBadHashingKey: Equatable, Hashable {
    var k: String
    
    func hash(into hasher: inout Hasher) {
        let r = Int.random(in: 0...29)
        if r < 7 {
            hasher.combine("a")
        } else {
            hasher.combine(k)
        }
    }
    
}

// MARK: - asserts
func assertCountIsCorrentOnEveryNode<Key: Hashable, Value>(node: SeparateChainingHashTable<Key, Value>.Node, message: String? = nil, file: StaticString = #file, line: UInt = #line) {
    var thisCount = 1
    var current = node
    while let n = current.next {
        thisCount += 1
        current = n
    }
    guard
        thisCount == node.count
    else {
        XCTFail(message ?? "", file: file, line: line)
        
        return
    }
    if let n = node.next {
        assertCountIsCorrentOnEveryNode(node: n, message: message, file: file, line: line)
    }
}

func assertEqualButDifferentReference<Key: Hashable, Value: Equatable>(lhs: SeparateChainingHashTable<Key, Value>.Node?, rhs: SeparateChainingHashTable<Key, Value>.Node?, message: String? = nil, file: StaticString = #file, line: UInt = #line) {
    XCTAssertTrue(areEqualAndDifferentReference(lhs: lhs, rhs: rhs), message ?? "", file: file, line: line)
}

func assertAreEqual<Key: Hashable, Value: Equatable>(lhs: SeparateChainingHashTable<Key, Value>.Node?, rhs: SeparateChainingHashTable<Key, Value>.Node?, message: String? = nil, file: StaticString = #file, line: UInt = #line) {
    XCTAssertTrue(areEqual(lhs: lhs, rhs: rhs), message ?? "", file: file, line: line)
}

func assertEqualButDifferentReference<Key: Hashable, Value: Equatable>(lhs: SeparateChainingHashTable<Key, Value>?, rhs: SeparateChainingHashTable<Key, Value>?, message: String? = nil, file: StaticString = #file, line: UInt = #line) {
    XCTAssertTrue(areEqualAndDifferentReference(lhs: lhs, rhs: rhs), message ?? "", file: file, line: line)
}

func assertAreEqual<Key: Hashable, Value: Equatable>(lhs: SeparateChainingHashTable<Key, Value>?, rhs: SeparateChainingHashTable<Key, Value>?, message: String? = nil, file: StaticString = #file, line: UInt = #line) {
    XCTAssertTrue(areEqual(lhs: lhs, rhs: rhs), message ?? "", file: file, line: line)
}

// MARK: - equality helpers
func areEqual<Key: Hashable, Value: Equatable>(lhs: SeparateChainingHashTable<Key, Value>.Node?, rhs: SeparateChainingHashTable<Key, Value>.Node?) -> Bool {
    guard lhs !== rhs else { return true }
    
    guard
        let l = lhs,
        let r = rhs else { return lhs == nil && rhs == nil }
    
    guard
        l.count == r.count,
        l.key == r.key,
        l.value == r.value
    else { return false }
    
    return areEqual(lhs: l.next, rhs: r.next)
}

func areEqualAndDifferentReference<Key: Hashable, Value: Equatable>(lhs: SeparateChainingHashTable<Key, Value>.Node?, rhs: SeparateChainingHashTable<Key, Value>.Node?) -> Bool {
    guard
        let l = lhs,
        let r = rhs else { return lhs == nil && rhs == nil }
    
    guard l !== r else { return false }
    
    guard
        l.count == r.count,
        l.key == r.key,
        l.value == r.value
    else { return false }
    
    return areEqual(lhs: l.next, rhs: r.next)
}


func areEqual<Key: Hashable, Value: Equatable>(lhs: SeparateChainingHashTable<Key, Value>?, rhs: SeparateChainingHashTable<Key, Value>?) -> Bool {
    guard lhs !== rhs else { return true }
    
    guard
        let l = lhs, let r = rhs
    else { return lhs == nil && rhs == nil }
    
    guard
        l.count == r.count,
        l.capacity == r.capacity,
        l.hashTableCapacity == r.hashTableCapacity
    else { return false }
    
    guard l.hashTable != r.hashTable else { return true }
    
    for idx in 0..<l.hashTableCapacity where !areEqual(lhs: l.hashTable[idx], rhs: r.hashTable[idx]) {
        
        return false
    }
    
    return true
}

func areEqualAndDifferentReference<Key: Hashable, Value: Equatable>(lhs: SeparateChainingHashTable<Key, Value>?, rhs: SeparateChainingHashTable<Key, Value>?) -> Bool {
    guard
        let l = lhs, let r = rhs
    else { return lhs == nil && rhs == nil }
    
    guard l !== r else { return false }
    
    guard
        l.count == r.count,
        l.capacity == r.capacity,
        l.hashTableCapacity == r.hashTableCapacity
    else { return false }
    
    guard l.hashTable != r.hashTable else { return false }
    
    for idx in 0..<l.hashTableCapacity where !areEqualAndDifferentReference(lhs: l.hashTable[idx], rhs: r.hashTable[idx]) {
        
        return false
    }
    
    return true
}

func containsSameElements<Key: Hashable, Value: Equatable, S: Sequence>(_ ht: SeparateChainingHashTable<Key, Value>, of seq: S) -> Bool where S.Element == (Key, Value) {
    var otherElements = Array(seq)
    guard ht.count == otherElements.count else { return false }
    
    var yeldElements = 0
    for element in ht {
        guard !otherElements.isEmpty else { return false }
        
        yeldElements += 1
        otherElements.removeAll(where: {
            $0.0 == element.0 && $0.1 == element.1
        })
    }
    
    return otherElements.isEmpty && ht.count == yeldElements
}
