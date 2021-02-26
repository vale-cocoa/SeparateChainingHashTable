//
//  COWHelpersTests.swift
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

final class COWHelpersTests: XCTestCase {
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
        
        setupSut()
    }
    
    override func tearDown() {
        sut = nil
        
        super.tearDown()
    }
    
    func setupSut() {
        sut = HashTable(uniqueKeysWithValues: givenKeysAndValuesWithoutDuplicateKeys())
    }
    
    // MARK: - WHEN
    func whenBufferTableIsTooSparse() {
        setupSut()
        while sut.buffer?.tableIsTooSparse == false {
            sut.buffer?.resizeTo(newCapacity: sut.capacity * 2)
        }
    }
    
    func whenBufferTableIsNotTooSparse() {
        setupSut()
        while sut.buffer?.tableIsTooSparse == true && sut.capacity > minBufferCapacity {
            let c = Swift.max(sut.capacity / 2, minBufferCapacity)
            sut.buffer?.resizeTo(newCapacity: c)
        }
    }
    
    func whenBufferTableIsTooTight() {
        setupSut()
        while sut.buffer?.tableIsTooTight == false && sut.capacity > minBufferCapacity{
            let c = Swift.max(sut.capacity / 2, minBufferCapacity)
            sut.buffer?.resizeTo(newCapacity: c)
        }
    }
    
    func whenBufferTableIsNotTooTight() {
        setupSut()
        while sut.buffer?.tableIsTooTight == true {
            sut.buffer?.resizeTo(newCapacity: sut.capacity * 2)
        }
    }
    
    // MARK: - Tests
    func testMakeUnique_whenBufferIsNil_thenInstanciatesNewBufferOfMinCapacity() {
        sut = HashTable()
        weak var prevID = sut.id
        
        sut.makeUnique()
        XCTAssertNotNil(sut.buffer)
        XCTAssertEqual(sut.capacity, minBufferCapacity)
        XCTAssertFalse(sut.id === prevID, "has not changed id reference")
        XCTAssertNil(prevID, "has not deallocated previous id reference")
    }
    
    func testMakeUnique_whenBufferIsNotNil_thenCopiesBufferWhenNotUniquivelyReferenced() {
        // sut.buffer is uniquively referenced
        weak var prevID = sut.id
        weak var prevBuffer = sut.buffer
        
        sut.makeUnique()
        XCTAssertFalse(sut.id === prevID, "has not changed id reference")
        XCTAssertNil(prevID, "has not deallocated previous id reference")
        XCTAssertTrue(sut.buffer === prevBuffer, "has copied buffer when not supposed to")
        
        // sut.buffer has more strong references
        let otherStrongReferenceToBuffer = sut.buffer
        prevID = sut.id
        prevBuffer = sut.buffer
        
        sut.makeUnique()
        XCTAssertFalse(sut.id === prevID, "has not changed id reference")
        XCTAssertNil(prevID, "has not deallocated previous id reference")
        XCTAssertFalse(sut.buffer === prevBuffer, "has not copied buffer when supposed to")
        XCTAssertEqual(sut.buffer, prevBuffer, "has not copied elements")
        XCTAssertTrue(otherStrongReferenceToBuffer === prevBuffer)
    }
    
    func testMakeUniqueReservingMinimumCapacity_whenFreeCapacityIsGreaterThanOrEqaultToMinimumCapacity_thenCopyBufferIfIsNotUniquelyReferenced() {
        let freeCapacity = sut.capacity - sut.count
        var minimumCapacity = freeCapacity
        
        while minimumCapacity >= 0 {
            weak var prevID = sut.id
            weak var prevBuffer = sut.buffer
            
            sut.makeUniqueReserving(minimumCapacity: minimumCapacity)
            XCTAssertTrue(sut.buffer === prevBuffer, "has copied buffer when not supposed to")
            XCTAssertFalse(sut.id === prevID, "has not changed id reference")
            minimumCapacity -= 1
        }
        
        minimumCapacity = freeCapacity
        while minimumCapacity >= 0 {
            weak var prevID = sut.id
            let otherStrongReferenceToBuffer = sut.buffer
            
            sut.makeUniqueReserving(minimumCapacity: minimumCapacity)
            XCTAssertFalse(sut.buffer === otherStrongReferenceToBuffer, "has not copied buffer when supposed to")
            XCTAssertEqual(sut.buffer, otherStrongReferenceToBuffer)
            XCTAssertFalse(sut.id === prevID, "has not changed id reference")
            minimumCapacity -= 1
        }
    }
    
    func testMakeUniqueReservingMinimumCapacity_whenFreeCapacityIsLessThanMinimumCapacity_thenCopiesBufferToABiggerOneWithFreeCapacityGreaterThanOrEqualToMinCapacity() {
        let freeCapacity = sut.capacity - sut.count
        
        var minimumCapacity = freeCapacity + 1
        while minimumCapacity < freeCapacity + 20 {
            weak var prevID = sut.id
            let prevBuffer = sut.buffer
            
            sut.makeUniqueReserving(minimumCapacity: minimumCapacity)
            XCTAssertFalse(sut.id === prevID, "has not changed id reference")
            XCTAssertFalse(sut.buffer === prevBuffer, "has not copied buffer")
            XCTAssertGreaterThanOrEqual(sut.capacity, minimumCapacity)
            if sut.buffer?.count == prevBuffer?.count {
                for k in containedKeys {
                    XCTAssertEqual(sut.buffer?.getValue(forKey: k), prevBuffer?.getValue(forKey: k))
                }
            } else { XCTFail("has not done right the copy of the elements") }
            minimumCapacity += 1
        }
    }
    
    func testMakeUniqueReservingMinimumCapacity_whenBufferIsNil_thenClonesToNewBufferWithCapacityGreaterThanOrEqualToMinimumCapacity() {
        for mc in 0..<20 {
            sut = HashTable()
            weak var prevID = sut.id
            
            sut.makeUniqueReserving(minimumCapacity: mc)
            XCTAssertFalse(sut.id === prevID, "has not changed id reference")
            XCTAssertNotNil(sut.buffer)
            XCTAssertGreaterThanOrEqual(sut.capacity, minBufferCapacity)
            XCTAssertGreaterThanOrEqual(sut.capacity, mc)
            XCTAssertTrue(sut.isEmpty)
        }
    }
    
    func testMakeUniqueEventuallyReducingCapacity_whenBufferTableIsTooSparse_thenCopiesBufferToASmallerOne() {
        whenBufferTableIsTooSparse()
        
        while sut.buffer!.tableIsTooSparse == true {
            weak var prevID = sut.id
            let prevBuffer = sut.buffer
            let prevCapacity = sut.capacity
            
            sut.makeUniqueEventuallyReducingCapacity()
            XCTAssertFalse(sut.id === prevID, "has not changed id reference")
            XCTAssertFalse(sut.buffer === prevBuffer, "has not copied buffer")
            XCTAssertLessThan(sut.capacity, prevCapacity)
            if sut.buffer?.count == prevBuffer?.count {
                for k in containedKeys {
                    XCTAssertEqual(sut.buffer?.getValue(forKey: k), prevBuffer?.getValue(forKey: k))
                }
            } else  { XCTFail("has not done right the copy of the elements") }
        }
    }
    
    func testMakeUniqueEventuallyReducingCapacity_whenBufferTableIsTooSparseAndBufferIsEmpty_thenSetsBufferToNil() {
        sut = HashTable(minimumCapacity: minBufferCapacity + Int.random(in: 1...10))
        weak var prevID = sut.id
        
        sut.makeUniqueEventuallyReducingCapacity()
        XCTAssertFalse(sut.id === prevID, "has not changed id reference")
        XCTAssertNil(sut.buffer)
    }
    
    func testMakeUniqueEventuallyReducingCapacity_whenBufferTableIsNotTooSparse_thenClonesBufferIfNotUniquelyReferenced() {
        whenBufferTableIsNotTooSparse()
        
        weak var prevID = sut.id
        weak var prevBuffer = sut.buffer
        
        sut.makeUniqueEventuallyReducingCapacity()
        XCTAssertFalse(sut.id === prevID, "has not changed id reference")
        XCTAssertTrue(sut.buffer === prevBuffer, "has copied buffer when not supposed to")
        
        let otherBufferStringReference = sut.buffer
        prevID = sut.id
        prevBuffer = sut.buffer
        
        sut.makeUniqueEventuallyReducingCapacity()
        XCTAssertFalse(sut.id === prevID, "has not changed id reference")
        XCTAssertFalse(sut.buffer === prevBuffer, "has not copied buffer")
        XCTAssertEqual(sut.buffer, otherBufferStringReference)
        XCTAssertTrue(otherBufferStringReference === prevBuffer, "has changed also the other reference")
    }
    
    func testMakeUniqueEventuallyIncreasingCapacity_whenBufferIsNil_thenInstanciatesBufferOfMinCapacity() {
        sut = HashTable()
        weak var prevID = sut.id
        
        sut.makeUniqueEventuallyIncreasingCapacity()
        XCTAssertFalse(sut.id === prevID, "has not changed id reference")
        XCTAssertNotNil(sut.buffer)
        XCTAssertEqual(sut.capacity, minBufferCapacity)
    }
    
    func testMakeUniqueEventuallyIncreasingCapacity_whenBufferTableIsTooTight_thenCopiesBufferToLargerOneWithDoubleCapacity() {
        whenBufferTableIsTooTight()
        
        while sut.buffer?.tableIsTooTight == true {
            weak var prevID = sut.id
            let prevBuffer = sut.buffer
            let prevCapacity = sut.capacity
            
            sut.makeUniqueEventuallyIncreasingCapacity()
            XCTAssertFalse(sut.id === prevID, "has not changed id reference")
            XCTAssertFalse(sut.buffer === prevBuffer, "has not copied buffer")
            XCTAssertEqual(sut.capacity, prevCapacity * 2)
            if sut.buffer?.count == prevBuffer?.count {
                for k in containedKeys {
                    XCTAssertEqual(sut.buffer?.getValue(forKey: k), prevBuffer?.getValue(forKey: k))
                }
            } else {
                XCTFail("has not properly copied elements")
            }
        }
    }
    
    func testMakeUniqueEventuallyIncreasingCapacity_whenBufferTableIsNotTooTight_thenClonesBufferIsIsNotUniquelyReferenced() {
        whenBufferTableIsNotTooTight()
        weak var prevID = sut.id
        weak var prevBuffer = sut.buffer
        
        sut.makeUniqueEventuallyIncreasingCapacity()
        XCTAssertFalse(sut.id === prevID, "has not changed id reference")
        XCTAssertTrue(sut.buffer === prevBuffer, "has copied buffer when not supposed to")
        
        let otherBufferStringReference = sut.buffer
        prevID = sut.id
        prevBuffer = sut.buffer
        
        sut.makeUniqueEventuallyIncreasingCapacity()
        XCTAssertFalse(sut.id === prevID, "has not changed id reference")
        XCTAssertFalse(sut.buffer === prevBuffer, "has not copied buffer")
        XCTAssertEqual(sut.buffer, otherBufferStringReference)
        XCTAssertTrue(otherBufferStringReference === prevBuffer, "has changed also the other reference")
    }
    
}
