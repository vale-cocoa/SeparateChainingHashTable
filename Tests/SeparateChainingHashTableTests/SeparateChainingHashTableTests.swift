//
//  SeparateChainingHashTableTests.swift
//  SeparateChainingHashTableTests
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

import XCTest
@testable import SeparateChainingHashTable

final class SeparateChainingHashTableTests: XCTestCase {
    typealias _Node<Key: Hashable, Value> = SeparateChainingHashTable<Key, Value>.Node
    var sut: SeparateChainingHashTable<String, Int>!
    
    override func setUp() {
        super.setUp()
        
        sut = SeparateChainingHashTable(minimumCapacity: 0)
    }
    
    override func tearDown() {
        sut = nil
        
        super.tearDown()
    }
    
    // MARK: GIVEN
    func givenRandomlyNotEmpty() -> SeparateChainingHashTable<String, Int> {
        let capacity = Int.random(in: 9..<33)
        let scht = SeparateChainingHashTable<String, Int>(minimumCapacity: capacity)
        for idx in 0..<capacity / 3 {
            let headNode: _Node = _Node(key: randomKey(), value: randomValue())
            for _ in 0..<Int.random(in: 0..<(capacity / 9)) {
                headNode.setValue(randomValue(), forKey: randomKey())
            }
            scht.hashTable[idx] = headNode
            scht.count += headNode.count
        }
        
        return scht
    }
    
    func givenKeysAndValuesWithoutDuplicateKeys() -> [(String, Int)] {
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
    
    func givenKeysAndValuesWithDuplicateKeys() -> [(String, Int)] {
        var result = givenKeysAndValuesWithoutDuplicateKeys()
        let keys = result.map { $0.0 }
        keys.forEach { result.append(($0, randomValue())) }
        
        return result
    }
    
    // MARK: - Tests
    func testInitCapacity() {
        for capacity in 0..<100 {
            sut = SeparateChainingHashTable(minimumCapacity: capacity)
            XCTAssertNotNil(sut)
            XCTAssertEqual(sut.capacity, capacity)
            XCTAssertEqual(sut.count, 0)
            XCTAssertNotNil(sut.hashTable)
            let expectedHTCapacity = capacity == 0 ? SeparateChainingHashTable<String, Int>.minHashTableCapacity : ((capacity * 3) / 2)
            XCTAssertEqual(sut.hashTableCapacity, expectedHTCapacity)
            for idx in 0..<sut.hashTableCapacity {
                XCTAssertNil(sut.hashTable[idx])
            }
        }
    }
    
    func testDeinit() {
        sut = nil
        XCTAssertNil(sut?.hashTable)
    }
    
    func testCopy() {
        sut = givenRandomlyNotEmpty()
        
        let clone = sut.copy() as? SeparateChainingHashTable<String, Int>
        assertEqualButDifferentReference(lhs: clone, rhs: sut)
    }
    
    func testInitOther() {
        let other = givenRandomlyNotEmpty()
        sut = SeparateChainingHashTable(other)
        assertEqualButDifferentReference(lhs: sut, rhs: other)
    }
    
    // MARK: - Computed properties tests
    func testAvailableFreeCapacity() {
        // returns capacity - count
        sut.capacity = Int.random(in: 0...Int.max)
        sut.count = Int.random(in: 0...sut.capacity)
        XCTAssertEqual(sut.availableFreeCapacity, sut.capacity - sut.count)
    }
    
    func testIsFull() {
        // when availableFreeCapacity > 0, then returns false
        sut.capacity = 10
        while sut.capacity > sut.count {
            XCTAssertGreaterThan(sut.availableFreeCapacity, 0)
            XCTAssertFalse(sut.isFull)
            sut.count += 1
        }
        
        // when sut.availableFreeCapacity == 0, then returns true
        XCTAssertEqual(sut.availableFreeCapacity, 0)
        XCTAssertTrue(sut.isFull)
    }
    
    func testIsEmpty() {
        // when count == 0, then returns true
        sut.count = 0
        XCTAssertTrue(sut.isEmpty)
        
        // when count > 0, then returns false
        sut.count = Int.random(in: 1...Int.max)
        XCTAssertFalse(sut.isEmpty)
    }
    
    // MARK: - Convenience initializers tests
    func testInitUniqueKeysWithValues() {
        // when sequence is empty, returns empty hash table
        var uniqueKeysAndValues = AnySequence(Array<(String, Int)>())
        sut = SeparateChainingHashTable(uniqueKeysWithValues: uniqueKeysAndValues)
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.isEmpty)
        
        // when sequence is not empty, then returns hash table containing
        // all elements in uniqueKeysAndValues
        var uniqueKeys = Set<String>()
        var elements = Array<(String, Int)>()
        for _ in 0..<(Int.random(in: 1...20)) {
            var newKey = randomKey()
            while !uniqueKeys.insert(newKey).inserted {
                newKey = randomKey()
            }
            elements.append((newKey, randomValue()))
        }
        uniqueKeysAndValues = AnySequence(elements)
        sut = SeparateChainingHashTable(uniqueKeysWithValues: uniqueKeysAndValues)
        XCTAssertNotNil(sut)
        XCTAssertTrue(containsSameElements(sut, of: uniqueKeysAndValues), "doesn't contain same elements")
    }
    
    func testInitUniquingKeysWith_whenKeysAndValuesDoesntContainDuplicateKeys_thenCombineNeverExecutes() {
        var hasExecuted: Bool = false
        let combine: (Int, Int) throws -> Int = { _, _ in
            hasExecuted = true
            throw(err)
        }
        let keysAndValues = givenKeysAndValuesWithoutDuplicateKeys()
        
        XCTAssertNoThrow(try sut = SeparateChainingHashTable(keysAndValues, uniquingKeysWith: combine))
        XCTAssertFalse(hasExecuted)
    }
    
    func testInitUniquingKeysWith_whenKeysAndValuesContainDuplicateKeys_thenCombineExecutes() {
        var hasExecuted: Bool = false
        let combine: (Int, Int) throws -> Int = { _, _ in
            hasExecuted = true
            throw(err)
        }
        let keysAndValues = givenKeysAndValuesWithDuplicateKeys()
        
        XCTAssertThrowsError(try sut = SeparateChainingHashTable(keysAndValues.shuffled(), uniquingKeysWith: combine))
        XCTAssertTrue(hasExecuted)
    }
    
    func testInitUniquingKeysWith_whenCombineThrows_thenRethrows() {
        let combine: (Int, Int) throws -> Int = { _, _ in
            throw(err)
        }
        let keysAndValues = givenKeysAndValuesWithDuplicateKeys()
        do {
            try sut = SeparateChainingHashTable(keysAndValues, uniquingKeysWith: combine)
        } catch {
            XCTAssertEqual(error as NSError, err, "rethrown a different error")
            
            return
        }
        XCTFail("has not rethrown")
    }
    
    func testInitUniquingKeysWith_whenCombineDoesntThrow() {
        let combine: (Int, Int) throws -> Int = { prev, new in
            prev * new
        }
        let keysAndValues = givenKeysAndValuesWithDuplicateKeys()
        var expectedResult: [(String, Int)] = []
        try! keysAndValues.forEach { newElement in
            guard
                let insertedIdx = expectedResult.firstIndex(where: { $0.0 == newElement.0 })
            else {
                expectedResult.append(newElement)
                
                return
            }
            
            let combinedValue = try combine(expectedResult[insertedIdx].1, newElement.1)
            expectedResult[insertedIdx] = (newElement.0, combinedValue)
        }
        
        XCTAssertNoThrow(try sut = SeparateChainingHashTable(keysAndValues, uniquingKeysWith: combine))
        XCTAssertTrue(containsSameElements(sut, of: expectedResult))
    }
    
    func testInitUniquingKeysWith_whenKeysAndValuesIsAnotherHashTable() {
        var hasExecuted: Bool = false
        let combine: (Int, Int) throws -> Int = { _, _ in
            hasExecuted = true
            throw(err)
        }
        let other = SeparateChainingHashTable<String, Int>(minimumCapacity: 10)
        for _ in 0..<10 {
            other.setValue(randomValue(), forKey: randomKey())
        }
        
        XCTAssertNoThrow(try sut = SeparateChainingHashTable(other, uniquingKeysWith: combine))
        XCTAssertFalse(hasExecuted)
        XCTAssertTrue(containsSameElements(sut, of: other))
    }
    
    // MARK: - init(grouping:by:) tests
    func testInitGroupingBy_whenKeyForValueThrows_thenRethrows() {
        let keyForValue: (Int) throws -> String = { _ in throw(err) }
        do {
            _ = try SeparateChainingHashTable(grouping: 1...10, by: keyForValue)
        } catch {
            XCTAssertEqual(error as NSError, err)
            
            return
        }
        XCTFail("has not rethrown")
    }
    
    func testInitGroupingBy_whenKeyForValueDoesntThrow() {
        let keyForValue: (Int) throws -> String = { v in
            guard 1...10 ~= v else { throw err }
            
            if 1...5 ~= v { return "1 to 5" }
            
            return "6 to 10"
        }
        var ht: SeparateChainingHashTable<String, [Int]>!
        do {
            ht = try SeparateChainingHashTable(grouping: 1...10, by: keyForValue)
        } catch {
            XCTFail("thrown error")
            
            return
        }
        let expectedResult = [
            ("1 to 5", Array(1...5)),
            ("6 to 10", Array(6...10))
        ]
        XCTAssertTrue(containsSameElements(ht, of: expectedResult))
    }
    
    // MARK: - Methods tests
    func testClone() {
        XCTFail("not yet implemented")
    }
}
