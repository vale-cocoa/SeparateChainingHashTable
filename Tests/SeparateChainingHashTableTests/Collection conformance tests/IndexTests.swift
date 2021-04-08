//
//  IndexTests.swift
//  SeparateChainingHashTableTests
//
//  Created by Valeriano Della Longa on 2021/02/25.
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

final class IndexTests: XCTestCase {
    typealias _Index = SeparateChainingHashTable<String, Int>.Index
    
    var sut: _Index!
    
    override func setUp() {
        super.setUp()
        
        sut = _Index(asStartIndexOf: SeparateChainingHashTable<String, Int>(minimumCapacity: 0))
    }
    
    override func tearDown() {
        sut = nil
        
        super.tearDown()
    }
    
    func givenEmptyHashTable(bufferCapacity: Int = 0) -> SeparateChainingHashTable<String, Int> {
        SeparateChainingHashTable<String, Int>(minimumCapacity: bufferCapacity)
    }
    
    func givenNotEmptyHashTable() -> SeparateChainingHashTable<String, Int> {
        SeparateChainingHashTable(uniqueKeysWithValues: givenKeysAndValuesWithoutDuplicateKeys())
    }
    
    // MARK: - Tests
    func testInitAsStartIndexOf() {
        // when hash table is empty and its buffer is nil
        var ht = givenEmptyHashTable()
        sut = _Index(asStartIndexOf: ht)
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.id === ht.id, "wrong id reference")
        XCTAssertEqual(sut.currentTableIndex, ht.capacity)
        XCTAssertEqual(sut.currentBagOffset, 0)
        XCTAssertNil(sut.currentBag(on: ht.buffer))
        XCTAssertNil(ht.buffer)
        
        // when hash table is empty and its buffer is not nil
        ht = givenEmptyHashTable(bufferCapacity: Int.random(in: 1...10))
        sut = _Index(asStartIndexOf: ht)
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.id === ht.id, "wrong id reference")
        XCTAssertEqual(sut.currentTableIndex, ht.capacity)
        XCTAssertEqual(sut.currentBagOffset, 0)
        XCTAssertNil(sut.currentBag(on: ht.buffer))
        
        // when hash table is not empty
        ht = givenNotEmptyHashTable()
        var expectedCurrentTableIndex = 0
        var expectedCurrentBag: HashTableBuffer<String, Int>.Bag? = nil
        while expectedCurrentTableIndex < ht.buffer!.capacity {
            expectedCurrentBag = ht.buffer?.table[expectedCurrentTableIndex]
            guard expectedCurrentBag == nil else { break }
            
            expectedCurrentTableIndex += 1
        }
        
        sut = _Index(asStartIndexOf: ht)
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.id === ht.id, "wrong id reference")
        XCTAssertEqual(sut.currentTableIndex, expectedCurrentTableIndex)
        XCTAssertEqual(sut.currentBagOffset, 0)
        XCTAssertNotNil(sut.currentBag(on: ht.buffer))
    }
    
    func testInitAsEndIndexOf() {
        // when hash table is empty and its buffer is nil
        var ht = givenEmptyHashTable()
        
        sut = _Index(asEndIndexOf: ht)
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.id === ht.id, "wrong id reference")
        XCTAssertEqual(sut.currentTableIndex, ht.capacity)
        XCTAssertNil(sut.currentBag(on: ht.buffer))
        XCTAssertEqual(sut.currentBagOffset, 0)
        
        // when hash table is empty and its buffer is not nil
        ht = givenEmptyHashTable(bufferCapacity: Int.random(in: 1...10))
        
        sut = _Index(asEndIndexOf: ht)
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.id === ht.id, "wrong id reference")
        XCTAssertEqual(sut.currentTableIndex, ht.capacity)
        XCTAssertEqual(sut.currentBagOffset, 0)
        XCTAssertNil(sut.currentBag(on: ht.buffer))
        
        // when hash table is not empty
        ht = givenNotEmptyHashTable()
        
        sut = _Index(asEndIndexOf: ht)
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.id === ht.id, "wrong id reference")
        XCTAssertEqual(sut.currentTableIndex, ht.capacity)
        XCTAssertEqual(sut.currentBagOffset, 0)
        XCTAssertNil(sut.currentBag(on: ht.buffer))
    }
    
    func testInitAsIndexForKeyOf_whenKeyIsNotInHashTable_thenReturnsNil() {
        // when hash table is empty and its buffer is nil
        var ht = givenEmptyHashTable()
        
        XCTAssertNil(_Index(asIndexOfKey: randomKey(), for: ht))
        
        // when hash table is empty and its buffer is not nil
        ht = givenEmptyHashTable(bufferCapacity: Int.random(in: 1...10))
        XCTAssertNil(_Index(asIndexOfKey: randomKey(), for: ht))
        
        // when hash table is not empty
        ht = givenNotEmptyHashTable()
        var notContainedKey: String!
        var l = 1
        repeat {
            notContainedKey = randomKey(ofLenght: l)
            l += 1
        } while ht.getValue(forKey: notContainedKey) != nil
        
        XCTAssertNil(_Index(asIndexOfKey: notContainedKey, for: ht))
    }
    
    func testInitAsIndexForKeyOf_whenKeyIsInHashTable_thenReturnsIndexPointingToTheHashTableElementForKey() {
        let ht = givenNotEmptyHashTable()
        for (key, value) in ht {
            sut = _Index(asIndexOfKey: key, for: ht)
            XCTAssertTrue(sut.id === ht.id, "wrong id reference")
            XCTAssertEqual(sut.currentBag(on: ht.buffer)?.key, key)
            XCTAssertEqual(sut.currentBag(on: ht.buffer)?.value, value)
        }
    }
    
    func testInitAsIndexForKeyOf_whenReturnsIndexPointingToHashTableElementForKey_thenIndexIsCorrectlyPositioned() {
        let ht = givenEmptyHashTable()
        let end = _Index(asEndIndexOf: ht)
        for k in ht.keys {
            sut = _Index(asIndexOfKey: k, for: ht)
            var correctlyPositionedIndex = _Index(asStartIndexOf: ht)
            while correctlyPositionedIndex.currentBag(on: ht.buffer)?.key != k && correctlyPositionedIndex < end {
                correctlyPositionedIndex.moveToNextElement(on: ht.buffer)
            }
            XCTAssertEqual(sut.currentTableIndex, correctlyPositionedIndex.currentTableIndex)
        }
    }
    
    func testCurrentBagOf() {
        // when buffer is nil
        var ht = givenEmptyHashTable()
        sut = _Index(asStartIndexOf: ht)
        XCTAssertNil(sut.currentBag(on: ht.buffer))
        
        // when buffer is not nil and is empty
        ht = givenEmptyHashTable(bufferCapacity: Int.random(in: 1...10))
        sut = _Index(asStartIndexOf: ht)
        XCTAssertNil(sut.currentBag(on: ht.buffer))
        
        // when buffer is not empty
        ht = givenNotEmptyHashTable()
        sut = _Index(asStartIndexOf: ht)
        for (key, value) in ht {
            let currentBag = sut.currentBag(on: ht.buffer)
            XCTAssertEqual(currentBag?.key, key)
            XCTAssertEqual(currentBag?.value, value)
            // make index point to next element
            if currentBag?.next != nil {
                sut.currentBagOffset += 1
            } else {
                sut.currentBagOffset = 0
                sut.currentTableIndex += 1
                Lookup: while sut.currentTableIndex < ht.capacity {
                    if ht.buffer?.table[sut.currentTableIndex] != nil {
                        break Lookup
                    }
                    sut.currentTableIndex += 1
                }
            }
        }
    }
    
    func testMoveToNextElement_whenBufferIsNil_thenNothingHappens() {
        let prevId = sut.id
        let prevCurrentTableIndex = sut.currentTableIndex
        let prevCurrentBag = sut.currentBag(on: nil)
        
        sut.moveToNextElement(on: nil)
        XCTAssertTrue(sut.id === prevId, "id reference has changed")
        XCTAssertEqual(sut.currentTableIndex, prevCurrentTableIndex)
        XCTAssertTrue(sut.currentBag(on: nil) === prevCurrentBag, "currentBag reference has changed")
    }
    
    func testMoveToNextElement_whenBufferIsNotNilAndIsEndIndex_thenNothingHappens() {
        let ht = givenNotEmptyHashTable()
        sut = _Index(asEndIndexOf: ht)
        let prevId = sut.id
        let prevCurrentTableIndex = sut.currentTableIndex
        let prevCurrentBag = sut.currentBag(on: ht.buffer)
        
        sut.moveToNextElement(on: ht.buffer)
        XCTAssertTrue(sut.id === prevId, "id reference has changed")
        XCTAssertEqual(sut.currentTableIndex, prevCurrentTableIndex)
        XCTAssertTrue(sut.currentBag(on: ht.buffer) === prevCurrentBag, "currentBag reference has changed")
    }
    
    func testMoveToNextElement_whenIsInRangeIndex_thenMovesToNextElement() {
        let ht = givenNotEmptyHashTable()
        sut = _Index(asStartIndexOf: ht)
        for (key, value) in ht {
            XCTAssertEqual(key, sut.currentBag(on: ht.buffer)?.key)
            XCTAssertEqual(value, sut.currentBag(on: ht.buffer)?.value)
            sut.moveToNextElement(on: ht.buffer)
        }
        XCTAssertNil(sut.currentBag(on: ht.buffer))
        XCTAssertEqual(sut.currentTableIndex, ht.capacity)
    }
    
    func testIsValidFor() {
        // when id and buffer are same of hash table, then returns true,
        // otherwise returns false
        let ht = givenNotEmptyHashTable()
        let otherHT = givenNotEmptyHashTable()
        sut = _Index(asStartIndexOf: ht)
        repeat {
            XCTAssertEqual(sut.isValidFor(ht), sut.id === ht.id)
            XCTAssertTrue(sut.isValidFor(ht))
            
            XCTAssertEqual(sut.isValidFor(otherHT), sut.id === otherHT.id)
            XCTAssertFalse(sut.isValidFor(otherHT))
            
            sut.moveToNextElement(on: ht.buffer)
        } while sut.currentBag(on: ht.buffer) != nil
    }
    
    func testAreValid() {
        // lhs.id and lhs.buffer are equal to rhs.id and rhs.buffer, then returns true
        let ht = givenNotEmptyHashTable()
        
        var lhs = _Index(asStartIndexOf: ht)
        var rhs = _Index(asStartIndexOf: ht)
        rhs.moveToNextElement(on: ht.buffer)
        repeat {
            XCTAssertTrue(_Index.areValid(lhs: lhs, rhs: rhs))
            lhs.moveToNextElement(on: ht.buffer)
            rhs.moveToNextElement(on: ht.buffer)
        } while rhs.currentBag(on: ht.buffer) != nil
        
        // when lhs.id or lhs.buffer are not equal to rhs.id and rhs.buffer,
        // then returns false
        let other = givenEmptyHashTable()
        lhs = _Index(asStartIndexOf: ht)
        rhs = _Index(asStartIndexOf: other)
        repeat {
            XCTAssertFalse(_Index.areValid(lhs: lhs, rhs: rhs))
            lhs.moveToNextElement(on: ht.buffer)
            rhs.moveToNextElement(on: other.buffer)
        } while lhs.currentBag(on: ht.buffer) != nil && rhs.currentBag(on: other.buffer) != nil
    }
    
    // MARK: - test Comparable conformance
    func testEqual() {
        // when curentTableIndex are equal and currentBagOffset are equal then returns true,
        // otherwise returns false
        let ht = givenNotEmptyHashTable()
        var lhs = _Index(asStartIndexOf: ht)
        var rhs = _Index(asStartIndexOf: ht)
        repeat {
            XCTAssertEqual(lhs, rhs)
            lhs.moveToNextElement(on: ht.buffer)
            XCTAssertNotEqual(lhs, rhs)
            rhs.moveToNextElement(on: ht.buffer)
        } while lhs.currentBag(on: ht.buffer) != nil && rhs.currentBag(on: ht.buffer) != nil
    }
    
    func testLessThan() {
        let ht = givenNotEmptyHashTable()
        let htKeys = ht.map { $0.key }
        var lhs = _Index(asStartIndexOf: ht)
        var rhs = _Index(asStartIndexOf: ht)
        while lhs.currentBag(on: ht.buffer) != nil && rhs.currentBag(on: ht.buffer) != nil {
            rhs.moveToNextElement(on: ht.buffer)
            
            XCTAssertLessThan(lhs, rhs)
            XCTAssertGreaterThan(rhs, lhs)
            let lhsKeyPosition = lhs.currentBag(on: ht.buffer)?.key != nil ? htKeys.firstIndex(of: lhs.currentBag(on: ht.buffer)!.key)! : htKeys.count
            let rhsKeyPosition = rhs.currentBag(on: ht.buffer)?.key != nil ? htKeys.firstIndex(of: rhs.currentBag(on: ht.buffer)!.key)! : htKeys.count
            XCTAssertLessThan(lhsKeyPosition, rhsKeyPosition)
            
            lhs.moveToNextElement(on: ht.buffer)
            XCTAssertEqual(lhs, rhs)
            XCTAssertFalse(lhs < rhs)
            XCTAssertFalse(rhs < lhs)
            XCTAssertFalse(rhs > lhs)
            XCTAssertFalse(lhs > rhs)
        }
    }
    
}
