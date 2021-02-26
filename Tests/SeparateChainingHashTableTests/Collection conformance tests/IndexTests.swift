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
        XCTAssertNil(sut.currentBag)
        XCTAssertNil(ht.buffer)
        
        // when hash table is empty and its buffer is not nil
        ht = givenEmptyHashTable(bufferCapacity: Int.random(in: 1...10))
        sut = _Index(asStartIndexOf: ht)
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.id === ht.id, "wrong id reference")
        XCTAssertTrue(sut.buffer === ht.buffer, "wrong buffer reference")
        XCTAssertEqual(sut.currentTableIndex, ht.capacity)
        XCTAssertNil(sut.currentBag)
        
        // when hash table is not empty
        ht = givenNotEmptyHashTable()
        var expectedCurrentTableIndex = 0
        var expectedCurrentBag: HashTableBuffer<String, Int>.Bag? = nil
        while expectedCurrentTableIndex < ht.buffer!.capacity && expectedCurrentBag == nil {
            expectedCurrentBag = ht.buffer?.table[expectedCurrentTableIndex]
            expectedCurrentTableIndex += 1
        }
        
        sut = _Index(asStartIndexOf: ht)
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.id === ht.id, "wrong id reference")
        XCTAssertTrue(sut.buffer === ht.buffer, "wrong buffer reference")
        XCTAssertEqual(sut.currentTableIndex, expectedCurrentTableIndex)
        XCTAssertNotNil(sut.currentBag)
        XCTAssertTrue(sut.currentBag === expectedCurrentBag)
    }
    
    func testInitAsEndIndexOf() {
        // when hash table is empty and its buffer is nil
        var ht = givenEmptyHashTable()
        
        sut = _Index(asEndIndexOf: ht)
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.id === ht.id, "wrong id reference")
        XCTAssertEqual(sut.currentTableIndex, ht.capacity)
        XCTAssertNil(sut.currentBag)
        XCTAssertNil(ht.buffer)
        
        // when hash table is empty and its buffer is not nil
        ht = givenEmptyHashTable(bufferCapacity: Int.random(in: 1...10))
        
        sut = _Index(asEndIndexOf: ht)
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.id === ht.id, "wrong id reference")
        XCTAssertTrue(sut.buffer === ht.buffer, "wrong buffer reference")
        XCTAssertEqual(sut.currentTableIndex, ht.capacity)
        XCTAssertNil(sut.currentBag)
        
        // when hash table is not empty
        ht = givenNotEmptyHashTable()
        
        sut = _Index(asEndIndexOf: ht)
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.id === ht.id, "wrong id reference")
        XCTAssertTrue(sut.buffer === ht.buffer, "wrong buffer reference")
        XCTAssertEqual(sut.currentTableIndex, ht.capacity)
        XCTAssertNil(sut.currentBag)
    }
    
    func testInitAsIndexForKeyOf_whenKeyIsNotInHashTable_thenReturnsHashTablesEndIndex() {
        // when hash table is empty and its buffer is nil
        var ht = givenEmptyHashTable()
        
        sut = _Index(asIndexOfKey: randomKey(), for: ht)
        XCTAssertTrue(sut.id === ht.id, "wrong id reference")
        XCTAssertNil(sut.buffer)
        XCTAssertEqual(sut.currentTableIndex, ht.capacity)
        XCTAssertNil(sut.currentBag)
        
        // when hash table is empty and its buffer is not nil
        ht = givenEmptyHashTable(bufferCapacity: Int.random(in: 1...10))
        sut = _Index(asIndexOfKey: randomKey(), for: ht)
        XCTAssertTrue(sut.id === ht.id, "wrong id reference")
        XCTAssertTrue(sut.buffer === ht.buffer, "wrong buffer reference")
        XCTAssertEqual(sut.currentTableIndex, ht.capacity)
        XCTAssertNil(sut.currentBag)
        
        // when hash table is not empty
        ht = givenNotEmptyHashTable()
        var notContainedKey: String!
        var l = 1
        repeat {
            notContainedKey = randomKey(ofLenght: l)
            l += 1
        }
        while ht.getValue(forKey: notContainedKey) != nil
        
        sut = _Index(asIndexOfKey: notContainedKey, for: ht)
        XCTAssertTrue(sut.id === ht.id, "wrong id reference")
        XCTAssertTrue(sut.buffer === ht.buffer, "wrong buffer reference")
        XCTAssertEqual(sut.currentTableIndex, ht.capacity)
        XCTAssertNil(sut.currentBag)
    }
    
    func testInitAsIndefForKeyOf_whenKeyIsInHashTable_thenReturnsIndexPointingToTheHashTableElementForKey() {
        let ht = givenNotEmptyHashTable()
        for (key, value) in ht {
            sut = _Index(asIndexOfKey: key, for: ht)
            XCTAssertTrue(sut.id === ht.id, "wrong id reference")
            XCTAssertTrue(sut.buffer === ht.buffer, "wrong buffer reference")
            XCTAssertEqual(sut.currentBag?.key, key)
            XCTAssertEqual(sut.currentBag?.value, value)
        }
    }
    
    func testMoveToNextElement_whenBufferIsNil_thenNothingHappens() {
        XCTAssertNil(sut.buffer)
        let prevId = sut.id
        let prevCurrentTableIndex = sut.currentTableIndex
        let prevCurrentBag = sut.currentBag
        
        sut.moveToNextElement()
        XCTAssertTrue(sut.id === prevId, "id reference has changed")
        XCTAssertNil(sut.buffer)
        XCTAssertEqual(sut.currentTableIndex, prevCurrentTableIndex)
        XCTAssertTrue(sut.currentBag === prevCurrentBag, "currentBag reference has changed")
    }
    
    func testMoveToNextElement_whenBufferIsNotNilAndIsEndIndex_thenNothingHappens() {
        let ht = givenNotEmptyHashTable()
        sut = _Index(asEndIndexOf: ht)
        let prevBuffer = sut.buffer
        let prevId = sut.id
        let prevCurrentTableIndex = sut.currentTableIndex
        let prevCurrentBag = sut.currentBag
        
        sut.moveToNextElement()
        XCTAssertTrue(sut.id === prevId, "id reference has changed")
        XCTAssertTrue(sut.buffer === prevBuffer, "buffer reference has changed")
        XCTAssertEqual(sut.currentTableIndex, prevCurrentTableIndex)
        XCTAssertTrue(sut.currentBag === prevCurrentBag, "currentBag reference has changed")
    }
    
    func testMoveToNextElement_whenIsInRangeIndex_thenMovesToNextElement() {
        let ht = givenNotEmptyHashTable()
        sut = _Index(asStartIndexOf: ht)
        for (key, value) in ht {
            XCTAssertEqual(key, sut.currentBag?.key)
            XCTAssertEqual(value, sut.currentBag?.value)
            sut.moveToNextElement()
        }
        XCTAssertNil(sut.currentBag)
        XCTAssertEqual(sut.currentTableIndex, ht.capacity)
    }
    
    func testIsValidFor() {
        // when id and buffer are same of hash table, then returns true,
        // otherwise returns false
        let ht = givenNotEmptyHashTable()
        let otherHT = givenNotEmptyHashTable()
        sut = _Index(asStartIndexOf: ht)
        repeat {
            XCTAssertEqual(sut.isValidFor(ht), sut.id === ht.id && sut.buffer === ht.buffer)
            XCTAssertTrue(sut.isValidFor(ht))
            
            XCTAssertEqual(sut.isValidFor(otherHT), sut.id === otherHT.id && sut.buffer === otherHT.buffer)
            XCTAssertFalse(sut.isValidFor(otherHT))
            
            sut.moveToNextElement()
        } while sut.currentBag != nil
    }
    
    func testAreValid() {
        // lhs.id and lhs.buffer are equal to rhs.id and rhs.buffer, then returns true
        let ht = givenNotEmptyHashTable()
        
        var lhs = _Index(asStartIndexOf: ht)
        var rhs = _Index(asStartIndexOf: ht)
        rhs.moveToNextElement()
        repeat {
            XCTAssertTrue(_Index.areValid(lhs: lhs, rhs: rhs))
            lhs.moveToNextElement()
            rhs.moveToNextElement()
        } while rhs.currentBag != nil
        
        // when lhs.id or lhs.buffer are not equal to rhs.id and rhs.buffer,
        // then returns false
        let other = givenEmptyHashTable()
        lhs = _Index(asStartIndexOf: ht)
        rhs = _Index(asStartIndexOf: other)
        repeat {
            XCTAssertFalse(_Index.areValid(lhs: lhs, rhs: rhs))
            lhs.moveToNextElement()
            rhs.moveToNextElement()
        } while lhs.currentBag != nil && rhs.currentBag != nil
    }
    
    // MARK: - test Comparable conformance
    func testEqual() {
        // when curentTableIndex are equal and currentBag are equal then returns true,
        // otherwise returns false
        let ht = givenNotEmptyHashTable()
        var lhs = _Index(asStartIndexOf: ht)
        var rhs = _Index(asStartIndexOf: ht)
        repeat {
            XCTAssertEqual(lhs, rhs)
            lhs.moveToNextElement()
            XCTAssertNotEqual(lhs, rhs)
            rhs.moveToNextElement()
        } while lhs.currentBag != nil && rhs.currentBag != nil
    }
    
    func testLessThan() {
        let ht = givenNotEmptyHashTable()
        let htKeys = ht.map { $0.key }
        var lhs = _Index(asStartIndexOf: ht)
        var rhs = _Index(asStartIndexOf: ht)
        while lhs.currentBag != nil && rhs.currentBag != nil {
            rhs.moveToNextElement()
            
            XCTAssertLessThan(lhs, rhs)
            XCTAssertGreaterThan(rhs, lhs)
            let lhsKeyPosition = lhs.currentBag?.key != nil ? htKeys.firstIndex(of: lhs.currentBag!.key)! : htKeys.count
            let rhsKeyPosition = rhs.currentBag?.key != nil ? htKeys.firstIndex(of: rhs.currentBag!.key)! : htKeys.count
            XCTAssertLessThan(lhsKeyPosition, rhsKeyPosition)
            
            lhs.moveToNextElement()
            XCTAssertEqual(lhs, rhs)
            XCTAssertFalse(lhs < rhs)
            XCTAssertFalse(rhs < lhs)
            XCTAssertFalse(rhs > lhs)
            XCTAssertFalse(lhs > rhs)
        }
        
    }
    
}
