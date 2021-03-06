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

let minBufferCapacity = HashTableBuffer<String, Int>.minTableCapacity

// MARK: - GIVEN
func givenKeysAndValuesWithoutDuplicateKeys() -> [(key: String, value: Int)] {
    var keysAndValues = Array<(String, Int)>()
    var insertedKeys = Set<String>()
    for _ in 0..<Int.random(in: 1..<20) {
        var newKey = randomKey()
        while insertedKeys.insert(newKey).inserted == false {
            newKey = randomKey()
        }
        keysAndValues.append((newKey, randomValue()))
    }
    
    return keysAndValues
}

func givenKeysAndValuesWithDuplicateKeys() -> [(key: String, value: Int)] {
    var result = givenKeysAndValuesWithoutDuplicateKeys()
    let keys = result.map { $0.0 }
    keys.forEach { result.append(($0, randomValue())) }
    
    return result
}

// MARK: - Types for testing NSCopying
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

// MARK: - Sequence of Key-Value pairs for tests
struct Seq<Element>: Sequence {
    var elements: [Element]
    
    var ucIsZero = true
    
    
    init(_ elements: [Element]) {
        self.elements = elements
    }
    
    var underestimatedCount: Int {
        ucIsZero ? 0 : elements.count / 2
    }
    
    func makeIterator() -> AnyIterator<Element> {
        AnyIterator(elements.makeIterator())
    }
    
}

// MARK: - Other helpers
extension HashTableBuffer {
    var maxBagCount: Int {
        guard !isEmpty else { return 0 }
        
        return UnsafeBufferPointer(start: table, count: capacity)
            .compactMap { $0?.count }
            .max()!
    }
    
    var hashDistribuitionRatio: Double {
        guard !isEmpty else { return 1.0 }
        
        return Double(count) / Double(maxBagCount)
    }
    
}

// MARK: - Asserts
func assertCountIsCorrentOnEveryNode<Key: Hashable, Value>(bag: HashTableBuffer<Key, Value>.Bag, message: String? = nil, file: StaticString = #file, line: UInt = #line) {
    var thisCount = 1
    var current = bag
    while let n = current.next {
        thisCount += 1
        current = n
    }
    guard
        thisCount == bag.count
    else {
        XCTFail(message ?? "", file: file, line: line)
        
        return
    }
    if let n = bag.next {
        assertCountIsCorrentOnEveryNode(bag: n, message: message, file: file, line: line)
    }
}

func assertEqualButDifferentReference<Key: Hashable, Value: Equatable>(lhs: HashTableBuffer<Key, Value>.Bag?, rhs: HashTableBuffer<Key, Value>.Bag?, message: String? = nil, file: StaticString = #file, line: UInt = #line) {
    XCTAssertTrue(areEqualAndDifferentReference(lhs: lhs, rhs: rhs), message ?? "", file: file, line: line)
}

func assertFirstTableElementIsCorrectIndex<Key: Hashable, Value>(on buffer: HashTableBuffer<Key, Value>, message: String? = nil, file: StaticString = #file, line: UInt = #line) {
    var fIdx = buffer.capacity
    for idx in 0..<buffer.capacity where buffer.table[idx] != nil {
        fIdx = idx
        break
    }
    
    XCTAssertEqual(buffer.firstTableElement, fIdx, "\(message ?? "")", file: file, line: line)
}

// MARK: - equality helpers
func areEqual<Key: Hashable, Value: Equatable>(lhs: HashTableBuffer<Key, Value>.Bag?, rhs: HashTableBuffer<Key, Value>.Bag?) -> Bool {
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

func areEqualAndDifferentReference<Key: Hashable, Value: Equatable>(lhs: HashTableBuffer<Key, Value>.Bag?, rhs: HashTableBuffer<Key, Value>.Bag?) -> Bool {
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

