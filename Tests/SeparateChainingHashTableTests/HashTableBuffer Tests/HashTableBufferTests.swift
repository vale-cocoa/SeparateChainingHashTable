//
//  HashTableBufferTests.swift
//  SeparateChainingHashTableTests
//
//  Created by Valeriano Della Longa on 2021/02/19.
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

final class HashTableBufferTests: XCTestCase {
    let minCapacity = HashTableBuffer<String, Int>.minTableCapacity
    
    var sut: HashTableBuffer<String, Int>!
    
    var sutContainedElements: Array<(key: String, value: Int)> {
        sut!.map { $0 }
    }
    
    var sutContainedKeys: Set<String> { Set(sut!.map { $0.key }) }
    
    var sutContainedValues: Array<Int> { sut!.map { $0.value } }
    
    var notContainedKey: String {
        var key: String!
        var lenght = 1
        repeat {
            key = randomKey(ofLenght: lenght)
            lenght += 1
        } while sutContainedKeys.contains(key)
        
        return key
    }
    
    override func setUp() {
        super.setUp()
        
        sut = HashTableBuffer(minimumCapacity: minCapacity)
    }
    
    override func tearDown() {
        sut = nil
        
        super.tearDown()
    }
    
    
    
    // MARK: - WHEN
    func whenIsNotEmpty(capacity: Int = 10) {
        assert(capacity >= minCapacity)
        sut = HashTableBuffer<String, Int>(minimumCapacity: capacity)
        for _ in 0..<Int.random(in: 1...capacity) {
            sut.setValue(randomValue(), forKey: randomKey())
        }
    }
    
    // MARK: - Tests
    func testInitMinimumCapacity() {
        for capacity in minCapacity...10 {
            sut = HashTableBuffer(minimumCapacity: capacity)
            XCTAssertNotNil(sut)
            XCTAssertEqual(sut.capacity, capacity)
            XCTAssertEqual(sut.count, 0)
            XCTAssertNotNil(sut.table)
            for idx in 0..<capacity {
                XCTAssertNil(sut.table[idx])
            }
        }
    }
    
    func testFirstTableElement() {
        // when is empty, then returns capacity value
        sut = HashTableBuffer(minimumCapacity: Int.random(in: minCapacity..<100))
        XCTAssertEqual(sut.firstTableElement, sut.capacity)
        
        // when is not empty then returns the index to first
        // non-nil table's element
        whenIsNotEmpty()
        assertFirstTableElementIsCorrectIndex(on: sut)
    }
    
    func testIsEmpty() {
        sut = HashTableBuffer(minimumCapacity: Int.random(in: minCapacity...10))
        XCTAssertTrue(sut.isEmpty)
        
        whenIsNotEmpty()
        XCTAssertGreaterThan(sut.count, 0)
        XCTAssertFalse(sut.isEmpty)
    }
    
    func testTableIsTooTight() {
        sut = HashTableBuffer(minimumCapacity: 4)
        XCTAssertFalse(sut.tableIsTooTight)
        for i in 0..<6 {
            sut.setValue(randomValue(), forKey: randomKey(ofLenght: i + 1))
            if sut.count < sut.capacity {
                XCTAssertFalse(sut.tableIsTooTight)
            } else {
                XCTAssertTrue(sut.tableIsTooTight)
            }
        }
    }
    
    func testTableIsTooSparse() {
        XCTAssertTrue(sut.capacity == minCapacity)
        XCTAssertFalse(sut.tableIsTooSparse)
        
        sut = HashTableBuffer(minimumCapacity: 4)
        XCTAssertTrue(sut.tableIsTooSparse)
        for i in 0..<6 {
            sut.setValue(randomValue(), forKey: randomKey(ofLenght: i + 1))
            if sut.count <= sut.capacity / 4 {
                XCTAssertTrue(sut.tableIsTooSparse)
            } else {
                XCTAssertFalse(sut.tableIsTooSparse)
            }
        }
    }
    
    func testCopyWith() {
        // when isEmpty == true
        sut = HashTableBuffer(minimumCapacity: Int.random(in: minCapacity...10))
        var clone = sut.copy() as? HashTableBuffer<String, Int>
        XCTAssertNotNil(clone)
        XCTAssertFalse(sut === clone, "not copied just referenced")
        XCTAssertEqual(sut.capacity, clone?.capacity)
        XCTAssertEqual(sut.count, clone?.count)
        XCTAssertNotEqual(sut.table, clone?.table, "not done deep copy of table")
        if clone != nil {
            assertFirstTableElementIsCorrectIndex(on: clone!)
        }
        
        // when isEmpty == false
        whenIsNotEmpty()
        clone = sut.copy() as? HashTableBuffer<String, Int>
        XCTAssertNotNil(clone)
        XCTAssertFalse(sut === clone, "not copied just referenced")
        XCTAssertEqual(sut.capacity, clone?.capacity)
        XCTAssertEqual(sut.count, clone?.count)
        XCTAssertNotEqual(sut.table, clone?.table, "not done deep copy of table")
        if clone != nil, sut.capacity == clone?.capacity {
            for idx in 0..<sut.capacity {
                switch (sut.table[idx], clone!.table[idx]) {
                case (nil, nil): continue
                case (.some(let sutBag), .some(let clonedBag)):
                    XCTAssertFalse(sutBag === clonedBag, "not done a deep copy")
                    XCTAssertEqual(sutBag, clonedBag)
                default: XCTFail("Table was not copied properly")
                }
            }
            assertFirstTableElementIsCorrectIndex(on: clone!)
        }
    }
    
    func testHashIndex() {
        let capacity = Int.random(in: minCapacity..<100)
        sut = HashTableBuffer(minimumCapacity: capacity)
        // returns a value in range of 0..<capacity
        for i in 0..<100 {
            let k = randomKey(ofLenght: i + 1)
            let hIndex = sut.hashIndex(forKey: k)
            XCTAssertTrue(0..<sut.capacity ~= hIndex, "returned an out of bound index")
            // This will also test the static method
            XCTAssertEqual(HashTableBuffer<String, Int>.hashIndex(forKey: k, inBufferOfCapacity: sut.capacity), hIndex)
        }
        
    }
    
    func testGetValueForKey() {
        // when no element with key, then returns nil
        whenIsNotEmpty()
        XCTAssertNil(sut.getValue(forKey: notContainedKey))
        
        // when element with key, then returns element's value
        for k in sutContainedKeys {
            let result = sut.getValue(forKey: k)
            XCTAssertNotNil(result)
            XCTAssertEqual(sutContainedElements.first(where: { $0.key == k })?.value, result)
        }
    }
    
    func testUpdateValueForKey() {
        whenIsNotEmpty()
        
        // k is in buffer, then returns old value stored for k
        // and updates element with k to new value
        for k in sutContainedKeys {
            let expectedValue = sut.getValue(forKey: k)!
            let newValue = expectedValue * 10
            let prevCount = sut.count
            XCTAssertEqual(sut.updateValue(newValue, forKey: k), expectedValue)
            XCTAssertEqual(sut.getValue(forKey: k), newValue)
            XCTAssertEqual(sut.count, prevCount)
            assertFirstTableElementIsCorrectIndex(on: sut)
        }
        
        // when there's no element with k,
        // then adds new element with k and value and increases count by 1
        // and finally returns nil
        let k = notContainedKey
        let newValue = randomValue()
        let prevCount = sut.count
        XCTAssertNil(sut.updateValue(newValue, forKey: k))
        XCTAssertEqual(sut.getValue(forKey: k), newValue)
        XCTAssertEqual(sut.count, prevCount + 1)
        assertFirstTableElementIsCorrectIndex(on: sut)
    }
    
    func testSetValueForKeyUniquingKeysWith_whenKeyIsntDuplicate_thenCombineNeverExecutes() {
        var hasExecuted: Bool = false
        let combine: (Int, Int) throws -> Int = { _, _ in
            hasExecuted = true
            throw(err)
        }
        let keysAndValues = givenKeysAndValuesWithoutDuplicateKeys()
        
        for element in keysAndValues {
            XCTAssertNoThrow(try sut.setValue(element.value, forKey: element.key, uniquingKeysWith: combine))
            XCTAssertFalse(hasExecuted)
        }
        
        XCTAssertNoThrow(try sut.setValue(randomValue(), forKey: notContainedKey, uniquingKeysWith: combine))
        XCTAssertFalse(hasExecuted)
    }
    
    func testSetValueForKeyUniquingKeysWith_whenKeyIsDuplicate_thenCombineExecutes() {
        var hasExecuted: Bool = false
        let combine: (Int, Int) throws -> Int = { _, _ in
            hasExecuted = true
            throw(err)
        }
        
        whenIsNotEmpty()
        
        for k in sutContainedKeys {
            hasExecuted = false
            XCTAssertThrowsError(try sut.setValue(randomValue(), forKey: k, uniquingKeysWith: combine))
            XCTAssertTrue(hasExecuted)
        }
    }
    
    func testSetValueForKeyUniquingKeysWith_whenCombineThrows_thenRethrows() {
        let combine: (Int, Int) throws -> Int = { _, _ in
            throw(err)
        }
        whenIsNotEmpty()
        for k in sutContainedKeys {
            do {
                try sut.setValue(randomValue(), forKey: k, uniquingKeysWith: combine)
            } catch {
                XCTAssertEqual(error as NSError, err)
                continue
            }
            XCTFail("has not rethrown")
        }
    }
    
    func testSetValueForKeyUniquingKeysWith_whenCombineExecutesAndDoesntThrow_thenSetValueToCombineResultForDuplicateKey() {
        var hasExecuted: Bool = false
        let combine: (Int, Int) throws -> Int = { prev, new in
            hasExecuted = true
            
            return prev * new
        }
        whenIsNotEmpty()
        let newElements = sutContainedKeys.map { (key: $0, value: randomValue()) }
        let expectedResult = try! Dictionary(sutContainedElements + newElements, uniquingKeysWith: combine)
        for newElement in newElements {
            hasExecuted = false
            let prevCount = sut.count
            XCTAssertNoThrow(try sut.setValue(newElement.value, forKey: newElement.key, uniquingKeysWith: combine))
            XCTAssertTrue(hasExecuted)
            XCTAssertEqual(sut.getValue(forKey: newElement.key), expectedResult[newElement.key])
            XCTAssertEqual(sut.count, prevCount)
            assertFirstTableElementIsCorrectIndex(on: sut)
        }
    }
    
    func testSetValueForKeyUniquingKeysWith_whenCombineDoesntExecute_thenAddsNewElementForKeyAndValue() {
        var hasExecuted: Bool = false
        let combine: (Int, Int) throws -> Int = { prev, new in
            hasExecuted = true
            
            return prev * new
        }
        whenIsNotEmpty()
        
        for _ in 0..<10 {
            let newValue = randomValue()
            let newKey = notContainedKey
            let prevCount = sut.count
            hasExecuted = false
            XCTAssertNoThrow(try sut.setValue(newValue, forKey: newKey, uniquingKeysWith: combine))
            XCTAssertEqual(sut.count, prevCount + 1)
            XCTAssertEqual(sut.getValue(forKey: newKey), newValue)
            XCTAssertFalse(hasExecuted)
            assertFirstTableElementIsCorrectIndex(on: sut)
        }
    }
    
    func testSetValueForKey() {
        // when no element with key, then adds new element
        let keysAndValues = givenKeysAndValuesWithoutDuplicateKeys()
        for newElement in keysAndValues {
            let prevCount = sut.count
            XCTAssertNil(sut.getValue(forKey: newElement.key))
            sut.setValue(newElement.value, forKey: newElement.key)
            XCTAssertEqual(sut.getValue(forKey: newElement.key), newElement.value)
            XCTAssertEqual(sut.count, prevCount + 1)
            assertFirstTableElementIsCorrectIndex(on: sut)
        }
        
        // when element with key exists, then update its value
        for oldElement in keysAndValues {
            let newValue = oldElement.value * 1000
            let prevCount = sut.count
            XCTAssertEqual(sut.getValue(forKey: oldElement.key), oldElement.value)
            sut.setValue(newValue, forKey: oldElement.key)
            XCTAssertEqual(sut.getValue(forKey: oldElement.key), newValue)
            XCTAssertEqual(sut.count, prevCount)
            assertFirstTableElementIsCorrectIndex(on: sut)
        }
    }
    
    func testRemoveElementWithKey() {
        whenIsNotEmpty()
        // when there's no element with key, then nothing changes
        let clone = sut.copy() as! HashTableBuffer<String, Int>
        var result = sut.removeElement(withKey: notContainedKey)
        XCTAssertNil(result)
        XCTAssertEqual(sut, clone)
        assertFirstTableElementIsCorrectIndex(on: sut)
        
        // when there's element with key, then element is removed
        for k in sutContainedKeys {
            XCTAssertNotNil(sut.getValue(forKey: k))
            let prevCount = sut.count
            let expectedResult = sut.getValue(forKey: k)!
            result = sut.removeElement(withKey: k)
            XCTAssertEqual(result, expectedResult)
            XCTAssertNil(sut.getValue(forKey: k))
            XCTAssertEqual(sut.count, prevCount - 1)
            assertFirstTableElementIsCorrectIndex(on: sut)
        }
        XCTAssertTrue(sut.isEmpty)
        assertFirstTableElementIsCorrectIndex(on: sut)
    }
    
    func testMergeKeysAndValuesUniquingKeysWith_whenNoDuplicateKeys_thenCombineNeverExecutes() {
        whenIsNotEmpty()
        var hasExecuted = false
        let combine: (Int, Int) throws -> Int = { _, _ in
            hasExecuted = true
            throw err
        }
        let keysAndValues = givenKeysAndValuesWithoutDuplicateKeys().filter { sut.getValue(forKey: $0.key) == nil }
        
        XCTAssertNoThrow(try sut.merge(keysAndValues, uniquingKeysWith: combine))
        XCTAssertFalse(hasExecuted)
    }
    
    func testMergeKeysAndValuesUniquingKeysWith_whenDuplicateKeys_thenCombineExecutes() {
        whenIsNotEmpty()
        var hasExecuted = false
        let combine: (Int, Int) throws -> Int = { _, _ in
            hasExecuted = true
            throw err
        }
        let keysAndValues = sut!.map { $0 }.shuffled()
        
        XCTAssertThrowsError(try sut.merge(keysAndValues, uniquingKeysWith: combine))
        XCTAssertTrue(hasExecuted)
    }
    
    func testMergeKeysAndValuesUniquingKeysWith_whenCombineDoesntThrow_thenMergesAccordingly() {
        whenIsNotEmpty()
        let combine: (Int, Int) throws -> Int = { $0 + $1 }
        
        // when keysAndValues is empty, then nothing changes
        let prev = (sut.copy() as! HashTableBuffer<String, Int>)
        XCTAssertNoThrow(try sut.merge([], uniquingKeysWith: combine))
        XCTAssertEqual(sut, prev)
        assertFirstTableElementIsCorrectIndex(on: sut)
        
        // when keysAndValues doesn't contain duplicate keys,
        // then adds all elements
        var keysAndValues = givenKeysAndValuesWithoutDuplicateKeys()
            .filter { sut.getValue(forKey: $0.key) == nil }
        var expectedResult = Dictionary(uniqueKeysWithValues: Array(sut))
        
        try! expectedResult.merge(keysAndValues, uniquingKeysWith: combine)
        XCTAssertNoThrow(try sut.merge(keysAndValues, uniquingKeysWith: combine))
        XCTAssertEqual(sut.count, expectedResult.count)
        for element in expectedResult {
            XCTAssertEqual(sut.getValue(forKey: element.key), element.value)
        }
        XCTAssertFalse(sut.tableIsTooTight)
        assertFirstTableElementIsCorrectIndex(on: sut)
        
        // when keysAndValues contains some elements with
        // duplicate keys, then merges accordingly using combine
        keysAndValues = givenKeysAndValuesWithDuplicateKeys()
        expectedResult = Dictionary(uniqueKeysWithValues: Array(sut))
        try! expectedResult.merge(keysAndValues, uniquingKeysWith: combine)
        
        XCTAssertNoThrow(try sut.merge(keysAndValues, uniquingKeysWith: combine))
        XCTAssertEqual(sut.count, expectedResult.count)
        for element in expectedResult {
            XCTAssertEqual(sut.getValue(forKey: element.key), element.value)
        }
        XCTAssertFalse(sut.tableIsTooTight)
        assertFirstTableElementIsCorrectIndex(on: sut)
        
        // repeating this test with keysAndValues not implementing
        // withContiguousBufferWhenAvailable(_:) and
        // having its underEstimatedCount less than its real
        // elements count or 0
        var seq = Seq<(String, Int)>(keysAndValues)
        XCTAssertEqual(seq.underestimatedCount, 0)
        for _ in 0..<100 {
            seq.elements.append((notContainedKey, randomValue()))
        }
        expectedResult = Dictionary(uniqueKeysWithValues: Array(sut))
        try! expectedResult.merge(Array(seq), uniquingKeysWith: combine)
        
        XCTAssertNoThrow(try sut.merge(seq, uniquingKeysWith: combine))
        XCTAssertEqual(sut.count, expectedResult.count)
        for element in expectedResult {
            XCTAssertEqual(sut.getValue(forKey: element.key), element.value)
        }
        XCTAssertFalse(sut.tableIsTooTight)
        assertFirstTableElementIsCorrectIndex(on: sut)
        
        for _ in 0..<300 {
            seq.elements.append((notContainedKey, randomValue()))
        }
        seq.ucIsZero = false
        XCTAssertGreaterThan(seq.underestimatedCount, 0)
        XCTAssertLessThan(seq.underestimatedCount, seq.elements.count)
        expectedResult = Dictionary(uniqueKeysWithValues: Array(sut))
        try! expectedResult.merge(Array(seq), uniquingKeysWith: combine)
        
        XCTAssertNoThrow(try sut.merge(seq, uniquingKeysWith: combine))
        XCTAssertEqual(sut.count, expectedResult.count)
        for element in expectedResult {
            XCTAssertEqual(sut.getValue(forKey: element.key), element.value)
        }
        XCTAssertFalse(sut.tableIsTooTight)
        assertFirstTableElementIsCorrectIndex(on: sut)
    }
    
    func testMergeOtherUniquingKeysWith_whenOtherIsEmpty_thenNothingChanges() {
        let combine: (Int, Int) throws -> Int = { _, _ in throw err }
        whenIsNotEmpty()
        let expectedResult = (sut.copy() as! HashTableBuffer<String, Int>)
        let other = HashTableBuffer<String, Int>(minimumCapacity: minCapacity)
        XCTAssertNoThrow(try sut.merge(other, uniquingKeysWith: combine))
        XCTAssertEqual(sut, expectedResult)
        assertFirstTableElementIsCorrectIndex(on: sut)
    }
    
    func testMergeOtherUniquingKeysWith_whenOtherIsNotEmptyAndNoDuplicateKeys_thenCombineNeverExecutes() {
        var hasExecuted = false
        let combine: (Int, Int) throws -> Int = { _, _ in
            hasExecuted = true
            throw err
        }
        
        whenIsNotEmpty()
        let other = HashTableBuffer<String, Int>(minimumCapacity: 10)
        for element in givenKeysAndValuesWithoutDuplicateKeys() where sut.getValue(forKey: element.key) == nil {
            other.setValue(element.value, forKey: element.key)
        }
        var expectedResult = Dictionary(uniqueKeysWithValues: Array(sut))
        try! expectedResult.merge(Array(other), uniquingKeysWith: combine)
        
        hasExecuted = false
        XCTAssertNoThrow(try sut.merge(other, uniquingKeysWith: combine))
        XCTAssertFalse(hasExecuted)
        XCTAssertEqual(sut.count, expectedResult.count)
        for element in sut {
            XCTAssertEqual(element.value, expectedResult[element.key])
        }
        assertFirstTableElementIsCorrectIndex(on: sut)
    }
    
    func testMergeOtherUniquingKeysWith_whenCombineThrows_thenRethrows() {
        let combine: (Int, Int) throws -> Int = { _, _ in throw err }
        whenIsNotEmpty()
        let other = (sut.copy() as! HashTableBuffer<String, Int>)
        do {
            try sut.merge(other, uniquingKeysWith: combine)
        } catch {
            XCTAssertEqual(error as NSError, err)
            return
        }
        XCTFail("has not rethrown")
    }
    
    func testMergeOtherUniquingKeysWith_whenOtherContainsDuplicateKeysAndCombineDoesntThrow_thenMergesUsingCombine() {
        var hasExecuted = false
        let combine: (Int, Int) throws -> Int = {
            hasExecuted = true
            
            return $0 + $1
        }
        whenIsNotEmpty()
        let other = HashTableBuffer<String, Int>(minimumCapacity: sut.capacity)
        for element in sut {
            other.setValue(element.value * 10, forKey: element.key)
        }
        for _ in 0..<50 {
            other.setValue(randomValue(), forKey: notContainedKey)
        }
        var expectedResult = Dictionary(uniqueKeysWithValues: Array(sut))
        try! expectedResult.merge(Array(other), uniquingKeysWith: combine)
        
        hasExecuted = false
        do {
            try sut.merge(other, uniquingKeysWith: combine)
        } catch {
            XCTFail("has thrown error")
            
            return
        }
        XCTAssertTrue(hasExecuted)
        XCTAssertEqual(sut.count, expectedResult.count)
        for element in sut {
            XCTAssertEqual(element.value, expectedResult[element.key])
        }
        XCTAssertFalse(sut.tableIsTooTight)
        assertFirstTableElementIsCorrectIndex(on: sut)
    }
    
    func testMapValues_whenIsEmpty_thenTranformNeverExecutes() {
        var hasExectued = false
        let transform: (Int) throws -> String = { _ in
            hasExectued = true
            throw err
        }
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNoThrow(try sut.mapValues(transform))
        XCTAssertFalse(hasExectued)
    }
    
    func testMapValues_whenIsNotEmpty_thenTransformExecutes() {
        var hasExectued = false
        let transform: (Int) throws -> String = { _ in
            hasExectued = true
            throw err
        }
        
        whenIsNotEmpty()
        XCTAssertThrowsError(try sut.mapValues(transform))
        XCTAssertTrue(hasExectued)
    }
    
    func testMapValues_whenTransformThrows_thenRethrows() {
        let transform: (Int) throws -> String = { _ in throw err }
        whenIsNotEmpty()
        do {
            let _ = try sut.mapValues(transform)
        } catch {
            XCTAssertEqual(error as NSError, err)
            
            return
        }
        XCTFail("did not rethrow")
    }
    
    func testMapValues_whenTransformDoesntThrow_thenReturnsHashTableWithMappedValues() {
        let transform: (Int) throws -> String = { "\($0)" }
        whenIsNotEmpty()
        let expectedResult = try! Dictionary(uniqueKeysWithValues: Array(sut)).mapValues(transform)
        var result: HashTableBuffer<String, String>!
        do {
            result = try sut.mapValues(transform)
        } catch {
            XCTFail("has thown error")
            
            return
        }
        XCTAssertEqual(result.count, expectedResult.count)
        for element in result {
            XCTAssertEqual(element.value, expectedResult[element.key])
        }
    }
    
    func testCompactMapValues_whenIsEmpty_thenTransformNeverExecutes() {
        var hasExecuted = false
        let transform: (Int) throws -> String? = { _ in
            hasExecuted = true
            throw err
        }
        
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNoThrow(try sut.compactMapValues(transform))
        XCTAssertFalse(hasExecuted)
    }
    
    func testCompactMapValues_whenIsNotEmpty_thenTransoformExecutes() {
        var hasExecuted = false
        let transform: (Int) throws -> String? = { _ in
            hasExecuted = true
            throw err
        }
        
        whenIsNotEmpty()
        XCTAssertThrowsError(try sut.compactMapValues(transform))
        XCTAssertTrue(hasExecuted)
    }
    
    func testCompactMapValues_whenTransformThrows_thenRethrows() {
        let transform: (Int) throws -> String? = { _ in throw err }
        
        whenIsNotEmpty()
        do {
            let _ = try sut.compactMapValues(transform)
        } catch {
            XCTAssertEqual(error as NSError, err)
            
            return
        }
        XCTFail("did not rethrow")
    }
    
    func testCompactMapValues_whenTransformDoesntThrow_thenReturnsHashTableWithCompactMappedValues() {
        let transform: (Int) throws -> String? = { $0 % 2 == 0 ? "\($0)" : nil }
        whenIsNotEmpty()
        let expectedResult = try! Dictionary(uniqueKeysWithValues: Array(sut))
            .compactMapValues(transform)
        var result: HashTableBuffer<String, String>!
        do {
            result = try sut.compactMapValues(transform)
        } catch {
            XCTFail("did throw error")
            
            return
        }
        XCTAssertEqual(result.count, expectedResult.count)
        for element in result {
            XCTAssertEqual(element.value, expectedResult[element.key])
        }
    }
    
    func testFilter_whenIsEmpty_thenIsIncludedNeverExecutes() {
        var hasExecuted = false
        let predicate: (HashTableBuffer<String, Int>.Element) throws -> Bool = { _ in
            hasExecuted = true
            throw err
        }
        
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNoThrow(try sut.filter(predicate))
        XCTAssertFalse(hasExecuted)
    }
    
    func testFilter_whenIsNotEmpty_thenIsIncludedExecutes() {
        var hasExecuted = false
        let predicate: (HashTableBuffer<String, Int>.Element) throws -> Bool = { _ in
            hasExecuted = true
            throw err
        }
        
        whenIsNotEmpty()
        XCTAssertThrowsError(try sut.filter(predicate))
        XCTAssertTrue(hasExecuted)
    }
    
    func testFilter_whenIsIncludedThrows_thenRethrows() {
        let predicate: (HashTableBuffer<String, Int>.Element) throws -> Bool = { _ in
            throw err
        }
        
        whenIsNotEmpty()
        do {
            let _ = try sut.filter(predicate)
        } catch {
            XCTAssertEqual(error as NSError, err)
            return
        }
        XCTFail("didn't rethrow")
    }
    
    func testFilter_whenIsIncludedDoesntThrow_thenReturnsHashTableFilteredByIsIncluded() {
        let predicate: (HashTableBuffer<String, Int>.Element) throws -> Bool = { $0.value % 2 == 0 }
        whenIsNotEmpty()
        let expectedResult = try! Dictionary(uniqueKeysWithValues: Array(sut))
            .filter(predicate)
        var result: HashTableBuffer<String, Int>!
        do {
            result = try sut.filter(predicate)
        } catch {
            XCTFail("did throw")
            
            return
        }
        XCTAssertEqual(result.count, expectedResult.count)
        for element in result {
            XCTAssertEqual(element.value, expectedResult[element.key])
        }
        assertFirstTableElementIsCorrectIndex(on: result)
    }
    
    func testCloneNewCapacity() {
        whenIsNotEmpty()
        // when newCapacity is equal to capacity,
        // then returns copy
        var clone = sut.clone(newCapacity: sut.capacity)
        XCTAssertEqual(sut, clone)
        assertFirstTableElementIsCorrectIndex(on: clone)
        
        // when newCapacity is different, then returns a copy
        // resized to newCapacity with all elements
        let newCapacity = 7
        XCTAssertNotEqual(sut.capacity, newCapacity)
        clone = sut.clone(newCapacity: newCapacity)
        XCTAssertEqual(clone.capacity, newCapacity)
        XCTAssertEqual(clone.count, sut.count)
        let sortedSutElements = sut!.map { $0 }.sorted(by: { $0.key < $1.key })
        let sortedCloneElements = clone.map { $0 }.sorted(by: { $0.key < $1.key })
        XCTAssertTrue(sortedCloneElements.elementsEqual(sortedSutElements, by: { $0.key == $1.key && $0.value == $1.value }))
        assertFirstTableElementIsCorrectIndex(on: clone)
    }
    
    func testResizeTo_whenNewCapacityIsEqualToCapacity_thenNothingHappens() {
        whenIsNotEmpty()
        let expectedResult = sut.copy() as! HashTableBuffer<String, Int>
        let prevTable = sut.table
        
        sut.resizeTo(newCapacity: sut.capacity)
        XCTAssertEqual(sut.table, prevTable)
        XCTAssertEqual(sut, expectedResult)
        assertFirstTableElementIsCorrectIndex(on: sut)
    }
    
    func testResizeTo_whenNewCapacityIsDifferentFromCapacity_thenResizesTableToNewCapacity() {
        whenIsNotEmpty()
        let expectedElements = Dictionary(uniqueKeysWithValues: Array(sut))
        var prevCapacity = sut.capacity
        let smallerCapacity = prevCapacity - 1
        if smallerCapacity > minCapacity {
            sut.resizeTo(newCapacity: smallerCapacity)
            XCTAssertEqual(sut.capacity, smallerCapacity)
            XCTAssertEqual(sut.count, expectedElements.count)
            for element in sut {
                XCTAssertEqual(element.value, expectedElements[element.key])
            }
        }
        assertFirstTableElementIsCorrectIndex(on: sut)
        
        let largerCapacity = prevCapacity + 1
        prevCapacity = sut.capacity
        sut.resizeTo(newCapacity: largerCapacity)
        XCTAssertEqual(sut.capacity, largerCapacity)
        XCTAssertEqual(sut.count, expectedElements.count)
        for element in sut {
            XCTAssertEqual(element.value, expectedElements[element.key])
        }
        assertFirstTableElementIsCorrectIndex(on: sut)
    }
    
    func testUnderestimatedCount() {
        // returns count
        XCTAssertEqual(sut.underestimatedCount, sut.count)
        for _ in 0..<10 {
            sut.setValue(randomValue(), forKey: randomKey())
            XCTAssertEqual(sut.underestimatedCount, sut.count)
        }
    }
    
    func testMakeIterator() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNotNil(sut.makeIterator())
        
        whenIsNotEmpty()
        XCTAssertNotNil(sut.makeIterator())
    }
    
    func testIterator() {
        XCTAssertTrue(sut.isEmpty)
        var iter = sut.makeIterator()
        XCTAssertNil(iter.next())
        
        let v = randomValue()
        let k = randomKey()
        sut.setValue(v, forKey: k)
        iter = sut.makeIterator()
        let el = iter.next()
        XCTAssertNotNil(el)
        XCTAssertEqual(el?.key, k)
        XCTAssertEqual(el?.value, v)
        XCTAssertNil(iter.next())
        XCTAssertEqual(sut.getValue(forKey: k), v)
        
        whenIsNotEmpty()
        let prevCount = sut.count
        var iteratedElements: [(key: String, value: Int)] = []
        iter = sut.makeIterator()
        while let n = iter.next() {
            iteratedElements.append(n)
        }
        XCTAssertEqual(iteratedElements.count, prevCount)
        XCTAssertEqual(sut.count, prevCount)
        for e in iteratedElements {
            XCTAssertEqual(sut.getValue(forKey: e.key), e.value)
        }
    }
    
    func testEquatable() {
        whenIsNotEmpty()
        // when is same instance, then returns true
        var rhs = sut
        XCTAssertEqual(sut, rhs)
        
        // when is a copy, then returns true
        rhs = (sut.copy() as! HashTableBuffer<String, Int>)
        XCTAssertEqual(sut, rhs)
        
        // when capacity is different, then returns false
        rhs = sut.clone(newCapacity: sut.capacity + 2)
        XCTAssertNotEqual(sut, rhs)
        
        // when count is different, then returns false
        rhs = (sut.copy() as! HashTableBuffer<String, Int>)
        rhs?.setValue(randomValue(), forKey: notContainedKey)
        XCTAssertEqual(sut.capacity, rhs?.capacity)
        XCTAssertNotEqual(sut.count, rhs?.count)
        XCTAssertNotEqual(sut, rhs)
        
        // when bags in tables at same index are different,
        // then returns false
        rhs = (sut.copy() as! HashTableBuffer<String, Int>)
        let containedKey = sutContainedKeys.randomElement()!
        rhs?.setValue(1000, forKey: containedKey)
        XCTAssertEqual(sut.capacity, rhs?.capacity)
        XCTAssertEqual(sut.count, rhs?.count)
        XCTAssertNotEqual(sut.getValue(forKey: containedKey), rhs?.getValue(forKey: containedKey))
        XCTAssertNotEqual(sut, rhs)
    }
    
    func testHashable() {
        whenIsNotEmpty()
        var lH = Hasher()
        var rH = Hasher()
        
        // when same instance, then same hash values
        var r = sut
        lH.combine(sut)
        rH.combine(r)
        XCTAssertEqual(lH.finalize(), rH.finalize())
        
        // when is a copy, then same hash values
        lH = Hasher()
        rH = Hasher()
        r = (sut.copy() as! HashTableBuffer<String,Int>)
        lH.combine(sut)
        rH.combine(r)
        XCTAssertEqual(lH.finalize(), rH.finalize())
        
        // when capacity is different, then different hash values
        lH = Hasher()
        rH = Hasher()
        r = sut.clone(newCapacity: sut.capacity + 1)
        lH.combine(sut)
        rH.combine(r)
        XCTAssertNotEqual(lH.finalize(), rH.finalize())
        
        // when count is different, then different hash values
        lH = Hasher()
        rH = Hasher()
        r = (sut.copy() as! HashTableBuffer<String,Int>)
        r?.setValue(randomValue(), forKey: notContainedKey)
        lH.combine(sut)
        rH.combine(r)
        XCTAssertNotEqual(lH.finalize(), rH.finalize())
        
        // when count and capacity are same, but at least one
        // elment is different, then different hash values
        lH = Hasher()
        rH = Hasher()
        r = (sut.copy() as! HashTableBuffer<String,Int>)
        r?.setValue(1000, forKey: sutContainedKeys.randomElement()!)
        lH.combine(sut)
        rH.combine(r)
        XCTAssertNotEqual(lH.finalize(), rH.finalize())
    }
    
    // MARK: - bad hashing indexing tests
    func testHashing_whenHashValueIsAlwaysTheSame() {
        let htb = HashTableBuffer<VeryBadHashingKey, Int>(minimumCapacity: 10)
        var indexes = Set<Int>()
        for i in 0..<10 {
            let k = randomKey(ofLenght: i + 1)
            let vbhk = VeryBadHashingKey(k: k)
            indexes.insert(htb.hashIndex(forKey: vbhk))
        }
        XCTAssertEqual(indexes.count, 1)
    }
    
    func testHashing_whenHashValueIsBad() {
        let capacity = 10
        let htb = HashTableBuffer<BadHashingKey, Int>(minimumCapacity: capacity)
        for i in 0..<(capacity * 2) {
            let k = randomKey(ofLenght: i + 1)
            let bhk = BadHashingKey(k: k)
            htb.setValue(randomValue(), forKey: bhk)
        }
        var countOfNotNilBags = 0
        for idx in 0..<capacity where htb.table[idx] != nil {
            countOfNotNilBags += 1
        }
        XCTAssertLessThan(countOfNotNilBags, capacity)
    }
    
    func testHashing_whenHashValueIsSomeWhatBad() {
        let capacity = 10
        let htb = HashTableBuffer<SomeWhatBadHashingKey, Int>(minimumCapacity: capacity)
        for i in 0..<(capacity * 2) {
            let k = randomKey(ofLenght: i + 1)
            let sbhk = SomeWhatBadHashingKey(k: k)
            htb.setValue(randomValue(), forKey: sbhk)
        }
        var countOfNotNilBags = 0
        for idx in 0..<capacity where htb.table[idx] != nil {
            countOfNotNilBags += 1
        }
        XCTAssertGreaterThan(countOfNotNilBags, capacity / 2)
    }
    
}
