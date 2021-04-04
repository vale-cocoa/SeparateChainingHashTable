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
            other.moveToNextElement(on: sut.buffer)
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
            i.moveToNextElement(on: sut.buffer)
            XCTAssertEqual(n, i)
        }
        
        // when index is endIndex then returns endIndex
        XCTAssertEqual(sut.index(after: sut.endIndex), sut.endIndex)
    }
    
    // This test will also test internal method formIndex(_:offsetBy:)
    func testIndexOffsetBy() {
        // when is empty, then returns endIndex
        XCTAssertTrue(sut.isEmpty)
        var start = sut.startIndex
        var end = sut.endIndex
        for distance in 0..<100 {
            XCTAssertEqual(sut.index(start, offsetBy: distance), end)
        }
        
        // when is not empty
        whenIsNotEmpty()
        start = sut.startIndex
        end = sut.endIndex
        var i = start
        let elements = sut!.map { $0 }
        for offset in 0..<sut.count {
            // adding distance would not go beyond than last element,
            // then returns index in bounds
            // pointing to correct element
            var distance = 0
            while (offset + distance) < sut.count {
                let offsetted = sut.index(i, offsetBy: distance)
                if offsetted >= start && offsetted < end {
                    let elementAtDistance = elements[distance + offset]
                    let elementAtIndex = sut[offsetted]
                    XCTAssertEqual(elementAtIndex.key, elementAtDistance.key)
                    XCTAssertEqual(elementAtIndex.value, elementAtDistance.value)
                } else {
                    XCTFail("returned an index out bounds")
                }
                
                distance += 1
            }
            
            // otherwise when adding distance would go beyond
            // last element, then returns endIndex
            for distance in sut.count - offset..<(sut.count - offset + Int.random(in: 0...10)) {
                XCTAssertGreaterThanOrEqual(distance + offset, sut.count)
                let offsetted = sut.index(i, offsetBy: distance)
                XCTAssertEqual(offsetted, end)
            }
            
            sut.formIndex(after: &i)
        }
    }
    
    func testIndexOffsetByLimitedBy() {
        // when is empty and distance is 0, then returns endIndex
        XCTAssertTrue(sut.isEmpty)
        var i = sut.startIndex
        var end = sut.endIndex
        XCTAssertEqual(sut.index(i, offsetBy: 0, limitedBy: end), end)
        
        // when is empty and distance is greater than 0,
        // then returns nil
        for distance in 1..<10 {
            XCTAssertNil(sut.index(i, offsetBy: distance, limitedBy: end))
        }
        
        // when is not empty
        whenIsNotEmpty()
        i = sut.startIndex
        end = sut.endIndex
        for offset in 0..<sut.count {
            var distance = 0
            while distance <= (sut.count - offset) {
                // and when offsetting doesn't go beyond limit, then
                // returns index offsetted
                var limit = i
                sut.formIndex(&limit, offsetBy: distance)
                for d in 0...distance {
                    var expectedResult = i
                    sut.formIndex(&expectedResult, offsetBy: d)
                    XCTAssertEqual(sut.index(i, offsetBy: d, limitedBy: limit), expectedResult)
                }
                // otherwise when offsetting goes beyond limit,
                // then returns nil
                for d in (distance + 1)...(distance + 10) {
                    XCTAssertNil(sut.index(i, offsetBy: d, limitedBy: limit))
                }
                distance += 1
            }
            sut.formIndex(after: &i)
        }
        
    }
    
    func testSubscriptPosition() {
        whenIsNotEmpty()
        var sutIter = sut.makeIterator()
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
            XCTAssertNil(sut.index(forKey: notContainedKey))
        }
    }
    
}
