//
//  CollectionConformanceTests.swift
//  SeparateChainingHashTableTests
//
//  Created by Valeriano Della Longa on 2021/02/26.
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

final class CollectionConformanceTests: XCTestCase {
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
    
    // MARK: - TESTS
    func testStartIndex() {
        // when isEmpty == true, then returns start index which is equal to end index
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.startIndex, HashTable.Index(asStartIndexOf: sut))
        XCTAssertEqual(sut.startIndex, HashTable.Index(asEndIndexOf: sut))
        
        // when isEmpty == false, then returns start index which is less than end index
        whenIsNotEmpty()
        XCTAssertEqual(sut.startIndex, HashTable.Index(asStartIndexOf: sut))
        XCTAssertLessThan(sut.startIndex, HashTable.Index(asEndIndexOf: sut))
    }
    
    func testEndIndex() {
        // when isEmpty == true, then returns end index which is equal to start index
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.endIndex, HashTable.Index(asEndIndexOf: sut))
        XCTAssertEqual(sut.endIndex, HashTable.Index(asStartIndexOf: sut))
        
        // when isEmpty == false, then returns end index which is greater than start index
        whenIsNotEmpty()
        XCTAssertEqual(sut.endIndex, HashTable.Index(asEndIndexOf: sut))
        XCTAssertGreaterThan(sut.endIndex, HashTable.Index(asStartIndexOf: sut))
    }
    
    func testFormIndexAfter() {
        whenIsNotEmpty()
        
        // when index is not endIndex, then forms index pointing to next element
        var i = sut.startIndex
        while i < sut.endIndex {
            var other = i
            other.moveToNextElement()
            sut.formIndex(after: &i)
            XCTAssertEqual(i, other)
        }
        
        // when index is endIndex, then stays equal to endIndex
        i = sut.endIndex
        sut.formIndex(after: &i)
        XCTAssertEqual(i, sut.endIndex)
    }
    
    func testIndexAfter() {
        whenIsNotEmpty()
        
        // when index is not endIndex, then returns index pointing to next element
        var i = sut.startIndex
        while i < sut.endIndex {
            let n = sut.index(after: i)
            i.moveToNextElement()
            XCTAssertEqual(n, i)
        }
        
        // when index is endIndex then returns endIndex
        XCTAssertEqual(sut.index(after: sut.endIndex), sut.endIndex)
    }
    
    // This test will also test internal method formIndex(_:offsetBy:)
    func testIndexOffsetBy() {
        XCTFail("test not yet implemented")
    }
    
    func testFormIndexOffsetByLimitedBy() {
        XCTFail("test not yet implemented")
    }
    
    func testIndexOffsetByLimitedBy() {
        XCTFail("test not yet implemented")
    }
    
    func testSubscriptPosition() {
        whenIsNotEmpty()
        let sutIter = sut.makeIterator()
        var i = sut.startIndex
        while let expectedResult = sutIter.next() {
            let result = sut[i]
            XCTAssertEqual(result.key, expectedResult.key)
            XCTAssertEqual(result.value, expectedResult.value)
            sut.formIndex(after: &i)
        }
        XCTAssertEqual(i, sut.endIndex)
    }
    
    func testIndexForKey() {
        // when is empty, then always returns nil
        for _ in 0..<10 {
            XCTAssertNil(sut.index(forKey: notContainedKey))
        }
        
        // when is not empty and key is contained,
        // then returns correct index for key
        whenIsNotEmpty()
        for k in containedKeys {
            let idx = sut.index(forKey: k)
            XCTAssertNotNil(idx)
            if let idx = idx {
                let element = sut[idx]
                XCTAssertEqual(element.key, k)
                XCTAssertEqual(element.value, sut[k])
            }
        }
        // otherwise when key is not contained, then returns nil
        for _ in 0..<10 {
            XCTAssertNil(sut[notContainedKey])
        }
    }
    
}
