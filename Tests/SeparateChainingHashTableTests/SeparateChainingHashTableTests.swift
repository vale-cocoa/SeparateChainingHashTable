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
    typealias HashTable = SeparateChainingHashTable<String, Int>
    
    var sut: HashTable!
    
    var containedKeys: Set<String> {
        let keys = sut.buffer?.map({ $0.key }) ?? []
        
        return Set(keys)
    }
    
    var notContainedKey: String {
        var l = 1
        var key = randomKey()
        while containedKeys.contains(key) {
            key = randomKey(ofLenght: l)
            l += 1
        }
        
        return key
    }
    
    override func setUp() {
        super.setUp()
        
        sut = HashTable()
    }
    
    override func tearDown() {
        sut = nil
        
        super.tearDown()
    }
    
    // MARK: - WHEN
    func whenIsNotEmpty() {
        sut = HashTable(uniqueKeysWithValues: givenKeysAndValuesWithoutDuplicateKeys())
    }
    
    // MARK: - Tests
    func testInit() {
        sut = HashTable()
        XCTAssertNotNil(sut)
        XCTAssertNil(sut.buffer)
    }
    
    func testInitMinimumCapacity() {
        // when k is 0, then buffers is nil
        sut = HashTable(minimumCapacity: 0)
        XCTAssertNotNil(sut)
        XCTAssertNil(sut.buffer)
        XCTAssertNotNil(sut.id)
        
        // when k is greater than zero, then buffer is not nil and
        // its capacity is greater than zero and equal to Swift.max(k, bufferMinimumCapacity)
        let k = Int.random(in: 1...10)
        let expectedCapacity = Swift.max(k, HashTableBuffer<String, Int>.minTableCapacity)
        sut = HashTable(minimumCapacity: k)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.buffer)
        XCTAssertEqual(sut.buffer?.capacity, expectedCapacity)
        XCTAssertNotNil(sut.id)
    }
    
    func testInitUniqueKeysWithValues() {
        let keysAndValues = givenKeysAndValuesWithoutDuplicateKeys()
        sut = HashTable(uniqueKeysWithValues: keysAndValues)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.buffer)
        XCTAssertEqual(sut.buffer?.count, keysAndValues.count)
        for expectedElement in keysAndValues {
            XCTAssertEqual(sut.buffer?.getValue(forKey: expectedElement.key), expectedElement.value)
        }
        
        sut = nil
        // when keysAndValues is another instance of SeparateChainingHashTable, then
        // it sets buffer to other.buffer
        let other = HashTable(uniqueKeysWithValues: keysAndValues)
        sut = HashTable(uniqueKeysWithValues: other)
        XCTAssertTrue(sut.buffer === other.buffer, "set buffer to wrong instance")
    }
    
    func testInitUniquingKeysWith_whenKeysAndValuesIsAnotherHashTableInstance_thenSetsBufferToOthersBuffer() {
        let other = HashTable(uniqueKeysWithValues: givenKeysAndValuesWithoutDuplicateKeys())
        XCTAssertNoThrow(sut = try HashTable(other, uniquingKeysWith: {_, _ in throw err }))
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.buffer === other.buffer)
    }
    
    func testInitUniquingKeysWith_whenKeysAndValuesDoesntContainDuplicateKeys_thenCombineNeverExecutes() {
        var hasExecuted = false
        let combine: (Int, Int) throws -> Int = {_, _ in
            hasExecuted = true
            throw err
        }
        XCTAssertNoThrow(sut = try HashTable(givenKeysAndValuesWithoutDuplicateKeys(), uniquingKeysWith: combine))
        XCTAssertFalse(hasExecuted)
    }
    
    func testInitUniquingKeysWith_whenKeysAndValuesContainsDuplicateKeys_thenCombinesExecutes() {
        var hasExecuted = false
        let combine: (Int, Int) throws -> Int = {_, _ in
            hasExecuted = true
            throw err
        }
        XCTAssertThrowsError(sut = try HashTable(givenKeysAndValuesWithDuplicateKeys(), uniquingKeysWith: combine))
        XCTAssertTrue(hasExecuted)
    }
    
    func testInitUniquingKeysWith_whenCombineThrows_thenRethrows() {
        let combine: (Int, Int) throws -> Int = {_, _ in throw err }
        do {
            sut = try HashTable(givenKeysAndValuesWithDuplicateKeys(), uniquingKeysWith: combine)
        } catch {
            XCTAssertEqual(error as NSError, err)
            
            return
        }
        XCTFail("didn't rethrow")
    }
    
    func testInitUniquingKeysWith_whenDupicateKeysAndCombineDoesntThrow_thenInitializesUsingCombineToMakeUniqueValuesForDuplicateKeys() {
        let combine: (Int, Int) throws -> Int = { $0 + $1 }
        // keysAndValues implements withContiguousStorageIfAvailable
        let keysAndValues = givenKeysAndValuesWithDuplicateKeys()
        let expectedResult = try! Dictionary(keysAndValues, uniquingKeysWith: combine)
        XCTAssertNoThrow(sut = try HashTable(keysAndValues, uniquingKeysWith: combine))
        XCTAssertNotNil(sut)
        if sut.count == expectedResult.count {
            for expectedElement in expectedResult {
                XCTAssertEqual(sut.buffer?.getValue(forKey: expectedElement.key), expectedElement.value)
            }
        } else {
            XCTFail("count should be equal to: \(expectedResult.count)")
        }
        
        // keysAndValues is a sequence which doesn't
        // implements withContiguousStorageIfAvailable
        // and returns 0 for underestimatedCount
        var seq = Seq(keysAndValues)
        seq.ucIsZero = true
        XCTAssertNoThrow(sut = try HashTable(seq, uniquingKeysWith: combine))
        XCTAssertNotNil(sut)
        if sut.count == expectedResult.count {
            for expectedElement in expectedResult {
                XCTAssertEqual(sut.buffer?.getValue(forKey: expectedElement.key), expectedElement.value)
            }
            XCTAssertFalse(sut.buffer!.tableIsTooTight)
        } else {
            XCTFail("count should be equal to: \(expectedResult.count)")
        }
        
        // keysAndValues is a sequence which doesn't
        // implements withContiguousStorageIfAvailable
        // and returns a value for underestimatedCount a value which is equal to
        // half of its elements count
        seq.ucIsZero = false
        XCTAssertNoThrow(sut = try HashTable(seq, uniquingKeysWith: combine))
        XCTAssertNotNil(sut)
        if sut.count == expectedResult.count {
            for expectedElement in expectedResult {
                XCTAssertEqual(sut.buffer?.getValue(forKey: expectedElement.key), expectedElement.value)
            }
            XCTAssertFalse(sut.buffer!.tableIsTooTight)
        } else {
            XCTFail("count should be equal to: \(expectedResult.count)")
        }
    }
    
    func testInitGroupingBy_whenValuesIsEmpty_thenKeyForValueNeverExecutes() {
        typealias GrouppedHT = SeparateChainingHashTable<String, Array<Int>>
        var hasExecuted = false
        let keyForValue: (Int) throws -> String = { _ in
            hasExecuted = true
            throw err
        }
        XCTAssertNoThrow(try GrouppedHT(grouping: [], by: keyForValue))
        XCTAssertFalse(hasExecuted)
    }
    
    func testInitGroupingBy_whenValuesIsNotEmpty_thenKeyForValueExecutes() {
        typealias GrouppedHT = SeparateChainingHashTable<String, Array<Int>>
        var hasExecuted = false
        let keyForValue: (Int) throws -> String = { _ in
            hasExecuted = true
            throw err
        }
        XCTAssertThrowsError(try GrouppedHT(grouping: 0..<100, by: keyForValue))
        XCTAssertTrue(hasExecuted)
    }
    
    func testInitGroupingBy_whenKeyForValueThrows_thenRethrows() {
        typealias GrouppedHT = SeparateChainingHashTable<String, Array<Int>>
        let keyForValue: (Int) throws -> String = { _ in throw err }
        do {
            let _ = try GrouppedHT(grouping: 0..<100, by: keyForValue)
        } catch {
            XCTAssertEqual(error as NSError, err)
            
            return
        }
        XCTFail("didn't rethrow")
    }
    
    func testInitGroupingBy_whenValuesIsNotEmptyAndKeyForValueDoesntThrow_thenInitializesAccordingly() {
        typealias GrouppedHT = SeparateChainingHashTable<String, Array<Int>>
        let keyForValue: (Int) throws -> String = { v in
            switch v {
            case 0..<10: return "A"
            case 10..<100: return "B"
            case 100..<300: return "C"
            case 300...: return "D"
            default: throw err
            }
        }
        
        let values = 0..<300
        let expectedResult = try! Dictionary(grouping: values, by: keyForValue)
        // values implements withContiguousStorageIfAvailable
        var result: GrouppedHT!
        XCTAssertNoThrow(result = try GrouppedHT(grouping: Array(values), by: keyForValue))
        if let r = result {
            XCTAssertEqual(r.count, expectedResult.count)
            for (key, value) in expectedResult {
                XCTAssertEqual(r.buffer?.getValue(forKey: key), value)
            }
            XCTAssertFalse(r.buffer!.tableIsTooTight)
        } else {
            XCTFail("didn't initialize")
        }
        
        // values is a sequence which doesn't
        // implements withContiguousStorageIfAvailable
        // and returns 0 for underestimatedCount
        var seq = Seq(Array(values))
        seq.ucIsZero = true
        XCTAssertNoThrow(result = try GrouppedHT(grouping: seq, by: keyForValue))
        if let r = result {
            XCTAssertEqual(r.count, expectedResult.count)
            for (key, value) in expectedResult {
                XCTAssertEqual(r.buffer?.getValue(forKey: key), value)
            }
            XCTAssertFalse(r.buffer!.tableIsTooTight)
        } else {
            XCTFail("didn't initialize")
        }
        
        // values is a sequence which doesn't
        // implements withContiguousStorageIfAvailable
        // and returns a value for underestimatedCount a value which is equal to
        // half of its elements count
        seq.ucIsZero = false
        XCTAssertNoThrow(result = try GrouppedHT(grouping: seq, by: keyForValue))
        if let r = result {
            XCTAssertEqual(r.count, expectedResult.count)
            for (key, value) in expectedResult {
                XCTAssertEqual(r.buffer?.getValue(forKey: key), value)
            }
            XCTAssertFalse(r.buffer!.tableIsTooTight)
        } else {
            XCTFail("didn't initialize")
        }
    }
    
    func testCapacity() {
        // when buffer is nil returns 0
        XCTAssertNil(sut.buffer)
        XCTAssertEqual(sut.capacity, 0)
        
        // when buffer is not nil, then returns buffer.capacity
        sut = HashTable(minimumCapacity: Int.random(in: 1...10))
        XCTAssertEqual(sut.capacity, sut.buffer?.capacity)
    }
    
    func testCount() {
        // when buffer is nil, then returns 0
        XCTAssertNil(sut.buffer)
        XCTAssertEqual(sut.count, 0)
        
        // when buffer is not nil, then returns buffer.count
        sut = HashTable(minimumCapacity: Int.random(in: 1...10))
        XCTAssertEqual(sut.count, sut.buffer?.count)
        for _ in 0..<sut.capacity {
            sut.buffer?.setValue(randomValue(), forKey: randomKey())
            XCTAssertEqual(sut.count, sut.buffer?.count)
        }
    }
    
    func testIsEmpty() {
        // when buffer is nil, then returns true
        XCTAssertNil(sut.buffer)
        XCTAssertTrue(sut.isEmpty)
        
        // when buffer is not nil, then returns buffer.isEmpty
        sut = HashTable(minimumCapacity: Int.random(in: 1...10))
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.isEmpty, sut.buffer?.isEmpty)
        
        let k = randomKey()
        sut.buffer?.setValue(randomValue(), forKey: k)
        XCTAssertFalse(sut.isEmpty)
        XCTAssertEqual(sut.isEmpty, sut.buffer?.isEmpty)
        
        sut.buffer?.removeElement(withKey: k)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.isEmpty, sut.buffer?.isEmpty)
    }
    
    func testSubscriptKey_getter() {
        // when is empty, always returns nil
        XCTAssertTrue(sut.isEmpty)
        for l in 1..<10 {
            let k = randomKey(ofLenght: l)
            XCTAssertNil(sut[k])
        }
        
        // when is not empty, and no element in buffer has key, then returns nil
        whenIsNotEmpty()
        let k = notContainedKey
        XCTAssertNil(sut.buffer?.getValue(forKey: k))
        XCTAssertNil(sut[k])
        
        // when is not empty, and there is element in buffer with key, then returns its value
        for k in containedKeys {
            let expectedResult = sut.buffer?.getValue(forKey: k)
            XCTAssertEqual(sut[k], expectedResult)
        }
    }
    
    func testSubscriptKey_setterWhenNewValueIsNotNil() {
        // when buffer is nil, then creates new buffer and
        // adds element with key and newValue
        var newKey = randomKey()
        var newValue = randomValue()
        XCTAssertNil(sut.buffer)
        
        sut[newKey] = newValue
        XCTAssertNotNil(sut.buffer)
        XCTAssertEqual(sut.buffer?.getValue(forKey: newKey), newValue)
        
        // when there is no element in buffer with key,
        // then adds new element with key and newValue
        newKey = notContainedKey
        newValue = randomValue()
        sut[newKey] = newValue
        XCTAssertEqual(sut.buffer?.getValue(forKey: newKey), newValue)
        
        // when there is element in buffer with key, then updates element with key
        // to newValue
        for k in containedKeys {
            newValue = sut.buffer!.getValue(forKey: k)! * 100
            sut[k] = newValue
            XCTAssertEqual(sut.buffer?.getValue(forKey: k), newValue)
        }
    }
    
    func testSubscriptKey_setterWhenNewValueIsNil() {
        // when buffer is nil, then buffer stays equal to nil
        XCTAssertNil(sut.buffer)
        sut[randomKey()] = nil
        XCTAssertNil(sut.buffer)
        
        // when buffer is not nil and buffer doesn't contain element with key,
        // then no element gets removed
        whenIsNotEmpty()
        for _ in 0..<10 {
            weak var prevBuffer = sut.buffer
            sut[notContainedKey] = nil
            XCTAssertTrue(sut.buffer === prevBuffer, "buffer has changed")
        }
        
        // when buffer is not nil and contains element with key,
        // then element with key gets removed
        for k in containedKeys {
            sut[k] = nil
            XCTAssertNil(sut.buffer?.getValue(forKey: k))
        }
        
    }
    
    func testSubscriptKey_setter_copyOnWrite() {
        // when buffer is nil
        XCTAssertNil(sut.buffer)
        weak var prevID = sut.id
        var copy = sut
        sut[randomKey()] = randomValue()
        XCTAssertFalse(sut.id === prevID, "has not updated id")
        XCTAssertTrue(copy?.id === prevID, "copy has changed its id")
        
        // when buffer is not nil
        sut = HashTable(minimumCapacity: Int.random(in: 1...10))
        weak var prevBuffer = sut.buffer
        prevID = sut.id
        copy = sut
        
        sut[randomKey()] = randomValue()
        XCTAssertFalse(sut.id === prevID, "has not updated id")
        XCTAssertTrue(copy?.id === prevID, "copy has changed its id")
        XCTAssertFalse(sut.buffer === prevBuffer, "has not copied buffer")
        XCTAssertTrue(copy?.buffer === prevBuffer, "copy has changed its buffer")
        
        // when buffer is not empty
        whenIsNotEmpty()
        prevBuffer = sut.buffer
        prevID = sut.id
        copy = sut
        
        sut[notContainedKey] = randomValue()
        XCTAssertFalse(sut.id === prevID, "has not updated id")
        XCTAssertTrue(copy?.id === prevID, "copy has changed its id")
        XCTAssertFalse(sut.buffer === prevBuffer, "has not copied buffer")
        XCTAssertTrue(copy?.buffer === prevBuffer, "copy has changed its buffer")
        
        for k in containedKeys {
            prevBuffer = sut.buffer
            prevID = sut.id
            copy = sut
            
            sut[k] = randomValue()
            XCTAssertFalse(sut.id === prevID, "has not updated id")
            XCTAssertTrue(copy?.id === prevID, "copy has changed its id")
            XCTAssertFalse(sut.buffer === prevBuffer, "has not copied buffer")
            XCTAssertTrue(copy?.buffer === prevBuffer, "copy has changed its buffer")
            
            prevBuffer = sut.buffer
            prevID = sut.id
            copy = sut
            
            sut[k] = nil
            XCTAssertFalse(sut.id === prevID, "has not updated id")
            XCTAssertTrue(copy?.id === prevID, "copy has changed its id")
            XCTAssertFalse(sut.buffer === prevBuffer, "has not copied buffer")
            XCTAssertTrue(copy?.buffer === prevBuffer, "copy has changed its buffer")
        }
    }
    
    func testSubscriptKeyDefaultValue_getter() {
        // when is empty, then always returns defaultValue:
        let defaultValue = Int.random(in: 100...1000)
        for _ in 0..<10 {
            sut = HashTable()
            XCTAssertEqual(sut[notContainedKey, default: defaultValue], defaultValue)
        }
        
        // when is not empty, then returns deafultValue only when
        // there is no value for key
        whenIsNotEmpty()
        for k in containedKeys {
            XCTAssertNotEqual(sut[k, default: defaultValue], defaultValue)
        }
        for _ in 0..<10 {
            XCTAssertEqual(sut[notContainedKey, default: defaultValue], defaultValue)
        }
    }
    
    func testSubscriptKeyDefaultValue_setter() {
        let defaultValue = Int.random(in: 600...1000)
        // when is empty, then uses default value
        for _ in 0..<10 {
            sut = HashTable()
            let k = notContainedKey
            sut[k, default: defaultValue] += 30
            XCTAssertEqual(sut[k], defaultValue + 30)
        }
        
        // when is not empty, then uses stored value for key
        //if present otherwise default value
        whenIsNotEmpty()
        for k in containedKeys {
            let prev = sut[k]!
            XCTAssertNotEqual(prev, defaultValue)
            sut[k, default: defaultValue] += 30
            XCTAssertEqual(sut[k], prev + 30)
        }
        
        let k = notContainedKey
        sut[k, default: defaultValue] += 30
        XCTAssertEqual(sut[k], defaultValue + 30)
    }
    
    func testSubscriptKeyDefaultValue_setter_copyOnWrite() {
        XCTFail("test not yet implemented")
    }
    
    // Main functionalities already tested by subscript_setter tests and in
    // HashTableBufferTests
    func testUpdateValueForKey_copyOnWrite() {
        // when buffer is nil
        XCTAssertNil(sut.buffer)
        weak var prevID = sut.id
        var copy = sut
        
        sut.updateValue(randomValue(), forKey: randomKey())
        XCTAssertFalse(sut.id === prevID, "has not updated id")
        XCTAssertNotNil(sut.buffer)
        XCTAssertNil(copy?.buffer)
        XCTAssertTrue(copy?.id === prevID, "copy has changed its id")
        
        // when buffer is not nil
        whenIsNotEmpty()
        weak var prevBuffer = sut.buffer
        prevID = sut.id
        copy = sut
        
        for _ in 0..<10 {
            prevBuffer = sut.buffer
            prevID = sut.id
            copy = sut
            
            sut.updateValue(randomValue(), forKey: notContainedKey)
            XCTAssertFalse(sut.buffer === prevBuffer, "has not copied its buffer")
            XCTAssertTrue(copy?.buffer === prevBuffer, "copy has changed its buffer")
            XCTAssertFalse(sut.id === prevID, "has not updated id")
            XCTAssertTrue(copy?.id === prevID, "copy has changed its id")
        }
        
        for k in containedKeys {
            prevID = sut.id
            prevBuffer = sut.buffer
            copy = sut
            
            sut.updateValue(randomValue(), forKey: k)
            XCTAssertFalse(sut.buffer === prevBuffer, "has not copied its buffer")
            XCTAssertTrue(copy?.buffer === prevBuffer, "copy has changed its buffer")
            XCTAssertFalse(sut.id === prevID, "has not updated id")
            XCTAssertTrue(copy?.id === prevID, "copy has changed its id")
        }
    }
    
    // Main functionalities already tested by subscript_setter tests and in
    // HashTableBufferTests
    func testRemoveValueForKey_copyOnWrite() {
        // when buffer is nil
        XCTAssertNil(sut.buffer)
        weak var prevID = sut.id
        var copy = sut
        
        sut.removeValue(forKey: randomKey())
        XCTAssertNil(sut.buffer)
        XCTAssertFalse(sut.id === prevID, "has not updated id")
        XCTAssertTrue(copy?.id === prevID, "copy has changed its id")
        XCTAssertNil(copy?.buffer)
        
        // when buffer is not nil and isEmpty == true
        sut = HashTable(minimumCapacity: Int.random(in: 1...10))
        prevID = sut.id
        weak var prevBuffer = sut.buffer
        copy = sut
        
        sut.removeValue(forKey: randomKey())
        XCTAssertFalse(sut.id === prevID, "has not updated id")
        XCTAssertFalse(sut.buffer === prevBuffer, "has not copied its buffer")
        XCTAssertTrue(copy?.id === prevID, "copy has changed its id")
        XCTAssertTrue(copy?.buffer === prevBuffer, "copy has changed its buffer")
        XCTAssertFalse(sut.buffer?.tableIsTooSparse ?? false)
        
        // when is not empty and buffer doesn't contain an element with key
        whenIsNotEmpty()
        prevID = sut.id
        prevBuffer = sut.buffer
        copy = sut
        
        sut.removeValue(forKey: notContainedKey)
        XCTAssertFalse(sut.id === prevID, "has not updated id")
        XCTAssertFalse(sut.buffer === prevBuffer, "has not copied its buffer")
        XCTAssertTrue(copy?.id === prevID, "copy has changed its id")
        XCTAssertTrue(copy?.buffer === prevBuffer, "copy has changed its buffer")
        XCTAssertFalse(sut.buffer?.tableIsTooSparse ?? false)
        
        // when is not empty and buffer contains element with key
        for k in containedKeys {
            prevID = sut.id
            prevBuffer = sut.buffer
            copy = sut
            
            sut.removeValue(forKey: k)
            XCTAssertFalse(sut.id === prevID, "has not updated id")
            XCTAssertFalse(sut.buffer === prevBuffer, "has not copied its buffer")
            XCTAssertTrue(copy?.id === prevID, "copy has changed its id")
            XCTAssertTrue(copy?.buffer === prevBuffer, "copy has changed its buffer")
        }
        XCTAssertFalse(sut.buffer?.tableIsTooSparse ?? false)
    }
    
    func testRemoveAllKeepingCapacity_whenKeepCapacityIsTrue_thenKeepsCapacityAfterHavingRemovedAllElements() {
        // when buffer is nil
        XCTAssertNil(sut.buffer)
        weak var prevID = sut.id
        
        sut.removeAll(keepingCapacity: true)
        XCTAssertFalse(sut.id === prevID, "has not updated id")
        XCTAssertNil(sut.buffer)
        
        // when buffer is not nil
        sut = HashTable(minimumCapacity: Int.random(in: 1...10))
        prevID = sut.id
        var prevCapacity = sut.capacity
        weak var prevBuffer = sut.buffer
        
        sut.removeAll(keepingCapacity: true)
        XCTAssertFalse(sut.id === prevID, "has not updated id")
        XCTAssertEqual(sut.capacity, prevCapacity)
        XCTAssertFalse(sut.buffer === prevBuffer, "has not changed its buffer")
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(prevBuffer)
        
        // when is not empty
        whenIsNotEmpty()
        prevID = sut.id
        prevCapacity = sut.capacity
        prevBuffer = sut.buffer
        
        sut.removeAll(keepingCapacity: true)
        XCTAssertFalse(sut.id === prevID, "has not updated id")
        XCTAssertEqual(sut.capacity, prevCapacity)
        XCTAssertFalse(sut.buffer === prevBuffer, "has not changed its buffer")
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(prevBuffer)
    }
    
    func testRemoveAllKeepingCapacity_whenKeepCapacityIsFalse_thenSetsBufferToNil() {
        // when buffer is nil
        XCTAssertNil(sut.buffer)
        weak var prevID = sut.id
        
        sut.removeAll(keepingCapacity: false)
        XCTAssertFalse(sut.id === prevID, "has not updated id")
        XCTAssertNil(sut.buffer)
        
        // when buffer is not nil
        sut = HashTable(minimumCapacity: Int.random(in: 1...10))
        prevID = sut.id
        weak var prevBuffer = sut.buffer
        
        sut.removeAll(keepingCapacity: false)
        XCTAssertFalse(sut.id === prevID, "has not updated id")
        XCTAssertEqual(sut.capacity, 0)
        XCTAssertNil(sut.buffer)
        XCTAssertNil(prevBuffer)
        
        // when is not empty
        whenIsNotEmpty()
        prevID = sut.id
        prevBuffer = sut.buffer
        
        sut.removeAll(keepingCapacity: false)
        XCTAssertFalse(sut.id === prevID, "has not updated id")
        XCTAssertEqual(sut.capacity, 0)
        XCTAssertNil(sut.buffer)
        XCTAssertNil(prevBuffer)
    }
    
    func testRemoveAllKeepingCapacity_copyOnWrite() {
        sut = HashTable(minimumCapacity: Int.random(in: 1...10))
        weak var prevBuffer = sut.buffer
        var copy = sut
        
        sut.removeAll(keepingCapacity: true)
        XCTAssertFalse(sut.buffer === prevBuffer, "has not copied buffer")
        XCTAssertTrue(copy?.buffer === prevBuffer, "copy has changed its buffer")
        
        whenIsNotEmpty()
        prevBuffer = sut.buffer
        copy = sut
        
        sut.removeAll(keepingCapacity: true)
        XCTAssertFalse(sut.buffer === prevBuffer, "has not copied buffer")
        XCTAssertTrue(copy?.buffer === prevBuffer, "copy has changed its buffer")
    }
    
    func testReserveCapacity() {
        // when buffer is nil and minimumCapacity is in range 0...minimumBufferCapacity,
        // then initializes a new buffer with minimumBufferCapacity as capacity
        for mc in 0...minBufferCapacity {
            sut = HashTable()
            weak var prevID = sut.id
            
            sut.reserveCapacity(mc)
            XCTAssertEqual(sut.capacity, minBufferCapacity)
            XCTAssertFalse(sut.id === prevID, "has not updated id")
        }
        
        // when buffer is nil and minimumCapacity is greater than minimumBufferCapacity,
        // then initializes a new buffer with minimumCapacity as capacity
        for mc in (minBufferCapacity + 1)..<(minBufferCapacity + 10) {
            sut = HashTable()
            weak var prevID = sut.id
            
            sut.reserveCapacity(mc)
            XCTAssertEqual(sut.capacity, mc)
            XCTAssertFalse(sut.id === prevID, "has not updated id")
        }
        
        // when buffer is not nil, isEmpty == true, then eventually resizes buffer so that
        // its capacity will be greater than or equal to minimumCapacity
        for mc in 0..<(minBufferCapacity + 10) {
            sut = HashTable(minimumCapacity: minBufferCapacity)
            weak var prevID = sut.id
            
            sut.reserveCapacity(mc)
            XCTAssertFalse(sut.id === prevID, "has not updated id")
            XCTAssertGreaterThanOrEqual(sut.capacity, mc)
        }
        
        // when buffer is not empty, then eventually resizes buffer so that its free capacity
        // will be greater than or equal to minimumCapacity
        for mc in 0..<30 {
            whenIsNotEmpty()
            weak var prevID = sut.id
            
            sut.reserveCapacity(mc)
            XCTAssertFalse(sut.id === prevID, "has not updated id")
            XCTAssertGreaterThanOrEqual(sut.capacity - sut.count, mc)
        }
    }
    
    func testMergeKeysAndValuesUniquingKeysWith_copyOnWrite() {
        // Main merging functionalities already tested in HashTableBufferTests
        
        whenIsNotEmpty()
        weak var prevID = sut.id
        weak var prevBuffer = sut.buffer
        let copy = sut
        let other = givenKeysAndValuesWithDuplicateKeys()
        
        sut.merge(other, uniquingKeysWith: +)
        XCTAssertFalse(sut.id === prevID, "has not updated id")
        XCTAssertFalse(sut.buffer === prevBuffer, "has not copied buffer")
        XCTAssertTrue(copy?.id === prevID, "copy has changed its id")
        XCTAssertTrue(copy?.buffer === prevBuffer, "copy has changed its buffer")
    }
    
    func testMergeOtherUniquingKeysWith() {
        // Main merging functionalities already tested in HashTableBufferTests
        
        // other isEmpty == false
        whenIsNotEmpty()
        weak var prevID = sut.id
        weak var prevBuffer = sut.buffer
        var copy = sut
        var other = HashTable(uniqueKeysWithValues: givenKeysAndValuesWithoutDuplicateKeys())
        
        sut.merge(other, uniquingKeysWith: +)
        XCTAssertFalse(sut.id === prevID, "has not updated id")
        XCTAssertFalse(sut.buffer === prevBuffer, "has not copied buffer")
        XCTAssertTrue(copy?.id === prevID, "copy has changed its id")
        XCTAssertTrue(copy?.buffer === prevBuffer, "copy has changed its buffer")
        
        // other isEmpty == true
        whenIsNotEmpty()
        prevID = sut.id
        prevBuffer = sut.buffer
        copy = sut
        other = HashTable()
        
        sut.merge(other, uniquingKeysWith: +)
        XCTAssertFalse(sut.id === prevID, "has not updated id")
        XCTAssertFalse(sut.buffer === prevBuffer, "has not copied buffer")
        XCTAssertTrue(copy?.id === prevID, "copy has changed its id")
        XCTAssertTrue(copy?.buffer === prevBuffer, "copy has changed its buffer")
    }
    
    func testMergingOtherUniquingKeysWith_whenEitherIsEmpty_thenReturnsOtherOne() {
        // throwing and rethrowing is already tested in HashTableBufferTests
        
        // when self.isEmpty == true, then returns other
        sut = HashTable(minimumCapacity: 10)
        var other = HashTable(uniqueKeysWithValues: givenKeysAndValuesWithoutDuplicateKeys())
        
        var result = sut.merging(other, uniquingKeysWith: +)
        XCTAssertTrue(result.buffer === other.buffer, "has not returned the very same other")
        XCTAssertTrue(result.id === other.id, "has not returned the very same other")
        
        // when self.isEmpty == false and other.isEmpty == true, then returns self
        whenIsNotEmpty()
        other = HashTable(minimumCapacity: 10)
        
        result = sut.merging(other, uniquingKeysWith: +)
        XCTAssertTrue(result.buffer === sut.buffer, "has not returned the very same self")
        XCTAssertTrue(result.id === sut.id, "has not returned the very same self")
    }
    
    func testMergingOtherUniquingKeysWith_whenBothAreNotEmpty_thenReturnsMerged() {
        whenIsNotEmpty()
        let other = HashTable(uniqueKeysWithValues: givenKeysAndValuesWithoutDuplicateKeys())
        
        let expectedResultBuffer = (sut.buffer!.copy() as! HashTableBuffer<String, Int>)
        expectedResultBuffer.merge(other.buffer!, uniquingKeysWith: +)
        
        let result = sut.merging(other, uniquingKeysWith: +)
        XCTAssertEqual(result.buffer, expectedResultBuffer)
    }
    
    func testMergingSequenceUniquingKeysWith_whenIsEmpty_thenReturnsInstanceInitializedWithKeysAndValuesUniquingKeysWithCombine() {
        sut = HashTable(minimumCapacity: 10)
        let kv = givenKeysAndValuesWithDuplicateKeys()
        let expectedResult = HashTable(kv, uniquingKeysWith: +)
        let result = sut.merging(kv, uniquingKeysWith: +)
        
        XCTAssertEqual(result.buffer, expectedResult.buffer)
    }
    
    func testMergingSequenceUniquingKeysWith_whenIsNotEmpty_thenReturnsMerged() {
        whenIsNotEmpty()
        let kv = givenKeysAndValuesWithDuplicateKeys()
        let expectedResult = (sut.buffer!.copy() as! HashTableBuffer<String, Int>)
        expectedResult.merge(kv, uniquingKeysWith: +)
        let result = sut.merging(kv, uniquingKeysWith: +)
        
        XCTAssertEqual(result.buffer, expectedResult)
    }
    
    func testMapValues() {
        // Main functionalities already tested in HashTableBufferTests
        let transform: (Int) -> String = { "\($0)" }
        whenIsNotEmpty()
        let expectedResult = sut.buffer?.mapValues(transform)
        
        let result = sut.mapValues(transform)
        XCTAssertEqual(result.buffer, expectedResult)
    }
    
    func testCompactMapValues() {
        // Main functionalities already tested in HashTableBufferTests
        let transform: (Int) -> String? = { $0 % 2 == 0 ? "\($0)" : nil }
        whenIsNotEmpty()
        let expectedResult = sut.buffer?.compactMapValues(transform)
        
        let result = sut.compactMapValues(transform)
        XCTAssertEqual(result.buffer, expectedResult)
    }
    
    func testFilter() {
        // Main functionalities already tested in HashTableBufferTests
        let isIncluded: (HashTable.Element) -> Bool = { $0.value % 2 == 0  }
        whenIsNotEmpty()
        var expectedResult = sut.buffer?.copy() as? HashTableBuffer<String, Int>
        expectedResult = expectedResult?.filter(isIncluded)
        
        let result = sut.filter(isIncluded)
        XCTAssertEqual(result.buffer, expectedResult)
    }
    
    func testRemoveAt() {
        whenIsNotEmpty()
        weak var prevID = sut.id
        let key = containedKeys.randomElement()!
        let expectedResultValue = sut[key]
        let idx = HashTable.Index(asIndexOfKey: key, for: sut)
        
        let result = sut.remove(at: idx)
        XCTAssertEqual(result.key, key)
        XCTAssertEqual(result.value, expectedResultValue)
        XCTAssertNil(sut[key])
        XCTAssertFalse(sut.id === prevID, "has not updated ID")
    }
    
    func testRemoveAt_copyOnWrite() {
        whenIsNotEmpty()
        let key = containedKeys.randomElement()!
        let idx = HashTable.Index(asIndexOfKey: key, for: sut)
        weak var prevID = sut.id
        weak var prevBuffer = sut.buffer
        let copy = sut
        
        sut.remove(at: idx)
        XCTAssertFalse(sut.id === prevID, "has not updated id")
        XCTAssertFalse(sut.buffer === prevBuffer, "has not updated buffer")
        XCTAssertTrue(copy?.id === prevID, "copy has changed id")
        XCTAssertTrue(copy?.buffer === prevBuffer, "copy has changed buffer")
    }
    
    
    // MARK: - Sequence conformance
    func testUnderestimatedCount_returnsCountValue() {
        XCTAssertEqual(sut.underestimatedCount, sut.count)
        
        whenIsNotEmpty()
        XCTAssertEqual(sut.underestimatedCount, sut.count)
        while !sut.isEmpty {
            sut.remove(at: sut.startIndex)
            XCTAssertEqual(sut.underestimatedCount, sut.count)
        }
        XCTAssertEqual(sut.underestimatedCount, sut.count)
    }
    
    func testMakeIterator() {
        XCTAssertNil(sut.buffer)
        var iter = sut.makeIterator()
        XCTAssertNil(iter.next())
        
        whenIsNotEmpty()
        iter = sut.makeIterator()
        let buffIter = sut.buffer!.makeIterator()
        while let sElement = iter.next() {
            let bElement = buffIter.next()
            XCTAssertEqual(sElement.key, bElement?.key)
            XCTAssertEqual(sElement.value, bElement?.value)
        }
        XCTAssertNil(buffIter.next())
    }
    
    // MARK: - ExpressibleByDictionaryLiteral conformance
    func testInitDictionaryLiteral() {
        sut = [
            "A" : 1,
            "B" : 2,
            "C" : 3,
            "D" : 4,
        ]
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.count, 4)
        XCTAssertEqual(sut["A"], 1)
        XCTAssertEqual(sut["B"], 2)
        XCTAssertEqual(sut["C"], 3)
        XCTAssertEqual(sut["D"], 4)
    }
    
    // MARK: - Equatable conformance
    func testAreEqual() {
        // when lhs and rhs have same buffer, then returns true
        let lhs = HashTable(uniqueKeysWithValues: givenKeysAndValuesWithoutDuplicateKeys())
        var rhs = HashTable(uniqueKeysWithValues: lhs.map { $0 } )
        XCTAssertFalse(lhs.buffer === rhs.buffer)
        XCTAssertEqual(lhs.buffer, rhs.buffer)
        XCTAssertEqual(lhs, rhs)
        
        rhs.makeUniqueReserving(minimumCapacity: rhs.capacity * 3)
        XCTAssertNotEqual(lhs.buffer, rhs.buffer)
        XCTAssertNotEqual(lhs, rhs)
    }
    
    // MARK: - Hashable conformance
    func testHashable() {
        var lHasher = Hasher()
        var rHasher = Hasher()
        
        // when lhs and rhs have same buffer,
        // then same value when combinining into hasher
        let lhs = HashTable(uniqueKeysWithValues: givenKeysAndValuesWithoutDuplicateKeys())
        var rhs = HashTable(uniqueKeysWithValues: lhs.map { $0 } )
        XCTAssertFalse(lhs.buffer === rhs.buffer)
        XCTAssertEqual(lhs.buffer, rhs.buffer)
        
        lHasher.combine(lhs)
        rHasher.combine(rhs)
        XCTAssertEqual(lHasher.finalize(), rHasher.finalize())
        
        lHasher = Hasher()
        rHasher = Hasher()
        // when lhs and rhs buffers are not equal,
        // then different value when combining into hasher
        rhs.makeUniqueReserving(minimumCapacity: rhs.capacity * 3)
        XCTAssertNotEqual(lhs.buffer, rhs.buffer)
        
        lHasher.combine(lhs)
        rHasher.combine(rhs)
        XCTAssertNotEqual(lHasher.finalize(), rHasher.finalize())
    }
}

