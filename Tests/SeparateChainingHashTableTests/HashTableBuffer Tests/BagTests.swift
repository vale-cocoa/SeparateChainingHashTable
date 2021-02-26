//
//  BagTests.swift
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

final class BagTests: XCTestCase {
    typealias Bag = HashTableBuffer<String, Int>.Bag
    
    var sut: Bag!
    
    var sutContainedKeys: [String] {
        sut.map { $0.key }
    }
    
    var randomKeyNotContainedInSut: String {
        var lenght = 1
        var k = randomKey(ofLenght: lenght)
        while let _ = sut.getValue(forKey: k) {
            k = randomKey(ofLenght: lenght)
            lenght += 1
        }
        
        return k
    }
    
    override func setUp() {
        super.setUp()
        
        sutBasicSetup()
    }
    
    override func tearDown() {
        sut = nil
        
        super.tearDown()
    }
    
    // MARK: - GIVEN
    func givenRandomKeyContainedInSut() -> String {
        let i = Int.random(in: 0..<sut.count)
        var current = sut!
        for _ in 0..<i {
            current = current.next!
        }
        
        return current.key
    }
    
    // MARK: - WHEN
    func sutBasicSetup() {
        sut = Bag(key: randomKey(), value: randomValue())
    }
    
    func whenIsASequentialList() {
        sutBasicSetup()
        var usedKeys = Set<String>()
        usedKeys.insert(sut.key)
        let totalCount = Int.random(in: 3...13)
        var current = sut
        for i in 1..<totalCount {
            var newKey: String!
            repeat {
                newKey = randomKey()
            } while usedKeys.insert(newKey).inserted == false
            let n = Bag(key: newKey, value: randomValue())
            current?.next = n
            current?.count += totalCount - i
            current = n
        }
    }
    
    // MARK: - Tests
    func testInitKeyValue() {
        let k = randomKey()
        let v = randomValue()
        
        sut = Bag.init(key: k, value: v)
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.key, k)
        XCTAssertEqual(sut.value, v)
        XCTAssertEqual(sut.count, 1)
        XCTAssertNil(sut.next)
    }
    
    func testInitElement() {
        let element = (randomKey(), randomValue())
        
        sut = Bag(element)
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.key, element.0)
        XCTAssertEqual(sut.value, element.1)
        XCTAssertEqual(sut.count, 1)
        XCTAssertNil(sut.next)
    }
    
    // MARK: - test properties
    func testKey() {
        let newKey = randomKey(ofLenght: 3)
        XCTAssertNotEqual(sut.key, newKey)
        sut.key = newKey
        XCTAssertEqual(sut.key, newKey)
    }
    
    func testValue() {
        let newValue = Int.random(in: 301...400)
        XCTAssertNotEqual(sut.value, newValue)
        sut.value = newValue
        XCTAssertEqual(sut.value, newValue)
    }
    
    func testCount() {
        let newCount = Int.random(in: 2...300)
        XCTAssertNotEqual(sut.count, newCount)
        sut.count = newCount
        XCTAssertEqual(sut.count, newCount)
    }
    
    func testNext() {
        var nextNode: Bag? = Bag(key: randomKey(ofLenght: 3), value: randomValue())
        XCTAssertNil(sut.next)
        sut.next = nextNode
        XCTAssertNotNil(sut.next)
        XCTAssertTrue(sut.next === nextNode)
        
        // next is a strong reference
        nextNode = nil
        weak var exNext = sut.next
        XCTAssertNotNil(exNext)
        
        // also doens't leak memory when set to nil
        XCTAssertTrue(isKnownUniquelyReferenced(&sut.next))
        sut.next = nil
        XCTAssertNil(sut.next)
        XCTAssertNil(exNext)
    }
    
    func testElement() {
        var k = sut.key
        var v = sut.value
        XCTAssertEqual(sut.element.0, k)
        XCTAssertEqual(sut.element.1, v)
        
        k = randomKey(ofLenght: 3)
        v = randomValue()
        sut.key = k
        sut.value = v
        XCTAssertEqual(sut.element.0, k)
        XCTAssertEqual(sut.element.1, v)
    }
    
    // MARK: - test NSCopying
    func testCopyWith_whenKeyAndValueAreNSCopying() {
        let nodeKey = CKey(randomKey())
        let nodeValue = CValue(randomValue())
        let node = HashTableBuffer<CKey, CValue>.Bag(key: nodeKey, value: nodeValue)
        // when next is nil
        var result = node.copy() as? HashTableBuffer<CKey, CValue>.Bag
        XCTAssertNotNil(result)
        XCTAssertFalse(result === node, "copy returned same instance")
        XCTAssertFalse(result?.key === nodeKey, "copy was shallow for key")
        XCTAssertFalse(result?.value === nodeValue, "copy was shallow for value")
        XCTAssertEqual(result?.key, nodeKey)
        XCTAssertEqual(result?.value, nodeValue)
        XCTAssertEqual(result?.count, node.count)
        XCTAssertNil(result?.next)
        
        // when next is node
        let nextNodeKey = CKey(randomKey())
        let nextNodeValue = CValue(randomValue())
        let nextNode = HashTableBuffer<CKey, CValue>.Bag(key: nextNodeKey, value: nextNodeValue)
        node.next = nextNode
        node.count = 2
        
        result = node.copy() as? HashTableBuffer<CKey, CValue>.Bag
        XCTAssertNotNil(result?.next)
        XCTAssertEqual(result?.count, node.count)
        XCTAssertFalse(result?.next === nextNode, "copy was shallow for next")
        XCTAssertFalse(result?.key === nextNodeKey, "copy was shallow for next.key")
        XCTAssertFalse(result?.next?.value === nextNodeValue, "copy was shallow for next.value")
        XCTAssertEqual(result?.next?.key, nextNodeKey)
        XCTAssertEqual(result?.next?.value, nextNodeValue)
        XCTAssertEqual(result?.next?.count, nextNode.count)
        XCTAssertNil(result?.next?.next)
    }
    
    func testCopyWith_whenKeyAndValueAreValueTypes() {
        let nodeKey = SKey(k: randomKey())
        let nodeValue = SValue(v: randomValue())
        let node = HashTableBuffer<SKey, SValue>.Bag(key: nodeKey, value: nodeValue)
        // when next is nil
        var result = node.copy() as? HashTableBuffer<SKey, SValue>.Bag
        XCTAssertNotNil(result)
        XCTAssertFalse(result === node, "copy returned same instance")
        XCTAssertEqual(result?.key, nodeKey)
        XCTAssertEqual(result?.value, nodeValue)
        XCTAssertEqual(result?.count, node.count)
        XCTAssertNil(result?.next)
        
        // when next is node
        let nextNodeKey = SKey(k: randomKey())
        let nextNodeValue = SValue(v: randomValue())
        let nextNode = HashTableBuffer<SKey, SValue>.Bag(key: nextNodeKey, value: nextNodeValue)
        node.next = nextNode
        node.count = 2
        
        result = node.copy() as? HashTableBuffer<SKey, SValue>.Bag
        XCTAssertNotNil(result?.next)
        XCTAssertEqual(result?.count, node.count)
        XCTAssertFalse(result?.next === nextNode, "copy was shallow for next")
        XCTAssertEqual(result?.next?.key, nextNodeKey)
        XCTAssertEqual(result?.next?.value, nextNodeValue)
        XCTAssertEqual(result?.next?.count, nextNode.count)
        XCTAssertNil(result?.next?.next)
    }
    
    func testClone() {
        // when next is nil
        XCTAssertNotNil(sut)
        XCTAssertNil(sut.next)
        var result = sut.clone()
        assertEqualButDifferentReference(lhs: result, rhs: sut)
        
        // when next is not nil
        let nextNode = Bag(key: randomKey(), value: randomValue())
        sut.next = nextNode
        sut.count = 2
        result = sut.clone()
        assertEqualButDifferentReference(lhs: result, rhs: sut)
    }
    
    func testGetValueForKey() {
        // when next is nil…
        XCTAssertNil(sut.next)
        
        // …when k == node.key, then returns node.value
        var k = sut.key
        var expectedResult = sut.value
        var result = sut.getValue(forKey: k)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, expectedResult)
        
        // …when k != node.key, then returns nil
        k = randomKey(ofLenght: 6)
        result = sut.getValue(forKey: k)
        XCTAssertNil(result)
        
        // when next is not nil…
        let nextNode = Bag(key: randomKey(ofLenght: 3), value: randomValue())
        sut.next = nextNode
        sut.count = 2
        
        // when k != node.key,
        //then returns result of node.next.getValue(forKey: k)
        k = nextNode.key
        expectedResult = nextNode.getValue(forKey: k)!
        XCTAssertNotEqual(k, sut.key)
        
        result = sut.getValue(forKey: k)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, expectedResult)
        
        k = randomKey(ofLenght: 6)
        XCTAssertNotEqual(k, sut.key)
        XCTAssertNotEqual(k, nextNode.key)
        XCTAssertNil(nextNode.getValue(forKey: k))
        XCTAssertNil(sut.getValue(forKey: k))
    }
    
    // MARK: - updateValue(_:forKey:) tests
    func testUpdateValueForKey() {
        whenIsASequentialList()
        
        // key is contained, then updates value to new one
        // and returns old one
        for k in sutContainedKeys {
            let expectedResult = sut.getValue(forKey: k)!
            let newValue = expectedResult * 10
            let prevCount = sut.count
            let result = sut.updateValue(newValue, forKey: k)
            XCTAssertEqual(expectedResult, result)
            XCTAssertEqual(sut.count, prevCount)
            XCTAssertEqual(sut.getValue(forKey: k), newValue)
            assertCountIsCorrentOnEveryNode(bag: sut)
        }
        
        // key is not contained, then adds new node with key and element
        // and updates count correctly and finally returns nil
        let k = randomKeyNotContainedInSut
        let newValue = randomValue()
        let prevCount = sut.count
        XCTAssertNil(sut.updateValue(newValue, forKey: k))
        XCTAssertEqual(sut.getValue(forKey: k), newValue)
        XCTAssertEqual(sut.count, prevCount + 1)
        assertCountIsCorrentOnEveryNode(bag: sut)
    }
    
    // MARK: - setValue(_:forKey:uniquingKeysWith:) tests
    func testSetValueForKeyUniquingKeysWith_whenKIsNotInNode_thenCombineNeverGetsCalled() {
        whenIsASequentialList()
        let k = randomKey(ofLenght: 2)
        XCTAssertNil(sut.getValue(forKey: k))
        var hasExecuted: Bool = false
        let combine: (Int, Int) throws -> Int = { _, _ in
            hasExecuted = true
            throw(err)
        }
        XCTAssertNoThrow(try sut.setValue(randomValue(), forKey: k, uniquingKeysWith: combine))
        XCTAssertFalse(hasExecuted)
    }
    
    func testSetValueForKeyUniquingKeysWith_whenKIsInNode_thenCombineGetsCalled() {
        whenIsASequentialList()
        let k = givenRandomKeyContainedInSut()
        var hasExecuted: Bool = false
        let combine: (Int, Int) throws -> Int = { _, _ in
            hasExecuted = true
            throw(err)
        }
        
        XCTAssertNotNil(sut.getValue(forKey: k))
        XCTAssertThrowsError(try sut.setValue(randomValue(), forKey: k, uniquingKeysWith: combine))
        XCTAssertTrue(hasExecuted)
    }
    
    func testSetValueForKeyUniquingKeysWith_whenKIsNotInNodeAndCombineDoesntThrow_thenAddsNewNodeForNewElementAndUpdatesCountCorrectly() {
        whenIsASequentialList()
        let k = randomKey(ofLenght: 2)
        XCTAssertNil(sut.getValue(forKey: k))
        let combine: (Int, Int) throws -> Int = { _, new in return new }
        let prevCount = sut.count
        XCTAssertNoThrow(try sut.setValue(1000, forKey: k, uniquingKeysWith: combine))
        XCTAssertEqual(sut.getValue(forKey: k), 1000)
        XCTAssertEqual(sut.count, prevCount + 1)
        assertCountIsCorrentOnEveryNode(bag: sut, message: "count was not updated correctly on every node")
    }
    
    func testSetValueForKeyUniquingKeysWith_whenKIsInNodeAndCombineDoesntThrow_thenUpdatesValueForKToResultOfCombineAndCountStaysTheSame() {
        whenIsASequentialList()
        let k = givenRandomKeyContainedInSut()
        let prevValue = (sut.getValue(forKey: k))!
        let newValue = randomValue()
        let combine: (Int, Int) throws -> Int = { prev, new in return prev + new }
        let resultValue = try! combine(prevValue, newValue)
        let prevCount = sut.count
        XCTAssertNoThrow(try sut.setValue(newValue, forKey: k, uniquingKeysWith: combine))
        XCTAssertEqual(sut.getValue(forKey: k), resultValue)
        XCTAssertEqual(sut.count, prevCount)
        assertCountIsCorrentOnEveryNode(bag: sut, message: "count has changed on some node and is not right")
    }
    
    func testSetValueForKeyUniquingKeysWith_whenCombineThrows_thenRethrowsSameErrorThrownByCombine() {
        whenIsASequentialList()
        let combine: (Int, Int) throws -> Int = { _, _ in throw(err) }
        let k = givenRandomKeyContainedInSut()
        do {
            try sut.setValue(randomValue(), forKey: k, uniquingKeysWith: combine)
        } catch  {
            XCTAssertEqual((error as NSError), err, "has rethrown a different error")
            
            return
        }
        XCTFail("has not rethrowed at all")
    }
    
    // MARK: - setValue(_:forKey:) tests
    func testSetValueForKey_whenKIsNotInNode_thenAddsNewNodeForElementAndUpdatesCount() {
        whenIsASequentialList()
        let k = randomKey(ofLenght: 2)
        let newValue = randomValue()
        let prevCount = sut.count
        XCTAssertNil(sut.getValue(forKey: k))
        sut.setValue(newValue, forKey: k)
        XCTAssertEqual(sut.getValue(forKey: k), newValue)
        XCTAssertEqual(sut.count, prevCount + 1)
        assertCountIsCorrentOnEveryNode(bag: sut, message: "count was not updated correctly on every node")
    }
    
    func testSetValueForKey_whenKIsInNode_thenUpdatesNodeElementToNewValue() {
        whenIsASequentialList()
        let k = givenRandomKeyContainedInSut()
        let prevValue = sut.getValue(forKey: k)
        let newValue = Int.random(in: 1000...1999)
        let prevCount = sut.count
        sut.setValue(newValue, forKey: k)
        let result = sut.getValue(forKey: k)
        XCTAssertNotEqual(result, prevValue)
        XCTAssertEqual(result, newValue)
        XCTAssertEqual(sut.count, prevCount)
        assertCountIsCorrentOnEveryNode(bag: sut, message: "count has changed on some node and was also wrongly set")
    }
    
    // MARK: - removingValue(forKey:) tests
    func testRemovingValueForKey_whenNodeDoesntContainK_thenReturnsNodeUnchangedAndNilAsValue() {
        // node.next == nil
        XCTAssertNil(sut.next)
        let k = randomKey(ofLenght: 2)
        XCTAssertNil(sut.getValue(forKey: k))
        var expectedResult = sut.clone()
        var result = sut.removingValue(forKey: k)
        sut = result.afterRemoval
        XCTAssertNil(result.removedValue)
        XCTAssertEqual(sut.count, expectedResult.count)
        XCTAssertEqual(sut.key, expectedResult.key)
        XCTAssertEqual(sut.value, expectedResult.value)
        XCTAssertNil(sut.next)
        assertCountIsCorrentOnEveryNode(bag: sut, message: "count has changed on some node and was also wrongly set")
        
        // node.next != nil
        whenIsASequentialList()
        XCTAssertNil(sut.getValue(forKey: k))
        expectedResult = sut.clone()
        result = sut.removingValue(forKey: k)
        sut = result.afterRemoval
        XCTAssertNil(result.removedValue)
        var cSut = sut
        var cER: Bag? = expectedResult
        while cER != nil {
            XCTAssertEqual(cSut?.count, cER!.count)
            XCTAssertEqual(cSut?.key, cER!.key)
            XCTAssertEqual(cSut?.value, cER!.value)
            cER = cER!.next
            cSut = cSut?.next
        }
        XCTAssertNil(cSut, "different number of nodes")
    }
    
    func testRemovingValueForKey_whenKIsInNode_thenRemovesNodeWithKAndUpdatesCountCorrectlyAndReturnsRemovedValue() {
        // node.next == nil
        XCTAssertNil(sut.next)
        var expectedValue = sut.value
        var result = sut.removingValue(forKey: sut.key)
        sut = result.afterRemoval
        XCTAssertNil(sut)
        XCTAssertEqual(result.removedValue, expectedValue)
        XCTAssertEqual((sut?.count ?? 0), 0)
        
        // node.next != nil
        whenIsASequentialList()
        for _ in 0..<sut.count {
            let k = givenRandomKeyContainedInSut()
            expectedValue = sut.getValue(forKey: k)!
            let prevCount = sut.count
            result = sut.removingValue(forKey: k)
            sut = result.afterRemoval
            XCTAssertEqual(result.removedValue, expectedValue)
            XCTAssertNil(sut?.getValue(forKey: k))
            XCTAssertEqual(sut?.count ?? 0, prevCount - 1)
            if sut != nil {
                assertCountIsCorrentOnEveryNode(bag: sut, message: "count has been updated wrongly on a node in the list")
            }
        }
    }
    
    func testMapValue_whenTransformThrows_thenRethrows() {
        let transform: (Int) throws -> String = { _ in throw err }
        whenIsASequentialList()
        
        XCTAssertThrowsError(try sut.mapValue(transform))
    }
    
    func testMapValue_whenTransformDoesntThrow_thenReturnsMappedBag() {
        let transform: (Int) throws -> String = { "\($0)" }
        whenIsASequentialList()
        let expectedResult = try! sut!
            .map { (key: $0.key, value: try transform($0.value)) }
        var mappedBag: HashTableBuffer<String, String>.Bag? = nil
        XCTAssertNoThrow(mappedBag = try sut.mapValue(transform))
        XCTAssertEqual(mappedBag?.count, sut.count)
        if mappedBag != nil {
            XCTAssertTrue(mappedBag!.elementsEqual(expectedResult, by: { $0.key == $1.key && $0.value == $1.value }))
            assertCountIsCorrentOnEveryNode(bag: mappedBag!)
        }
        
    }
    
    func testCompactMapValue_whenTransformThrows_thenRethrows() {
        let transform: (Int) throws -> String = { _ in throw err }
        whenIsASequentialList()
        XCTAssertThrowsError(try sut.compactMapValue(transform))
    }
    
    func testCompactMapValue_whenDoesntThrows_thenReturnsCompactMappedBag() {
        whenIsASequentialList()
        // when transform returns all mapped values
        var transform: (Int) throws -> String? = { $0 < 1000 ? "\($0)" : nil }
        var expectedResult: [(key: String, value: String)] = try! sut!.compactMap {
            guard
                let v = try transform($0.value)
            else { return nil }
            
            return (key: $0.key, value: v)
        }
        var mappedBag: HashTableBuffer<String, String>.Bag? = nil
        XCTAssertNoThrow(mappedBag = try sut.compactMapValue(transform))
        XCTAssertEqual(mappedBag?.count, sut.count)
        // then returns a bag with all elements mapped on values
        if mappedBag != nil {
            XCTAssertTrue(mappedBag!.elementsEqual(expectedResult, by: { $0.key == $1.key && $0.value == $1.value }))
            assertCountIsCorrentOnEveryNode(bag: mappedBag!)
        } else {
            XCTFail("returned nil instead")
        }
        
        // when transform returns only some mapped values
        let sortedSutValues = sut.map({ $0.value }).sorted()
        let midValue = sortedSutValues[sortedSutValues.count / 2]
        transform = {
            guard
                $0 >= midValue
            else { return nil }
            
            return "\($0)"
        }
        expectedResult = try! sut!.compactMap {
            guard
                let v = try transform($0.value)
            else { return nil }
            
            return (key: $0.key, value: v)
        }
        mappedBag = nil
        XCTAssertNoThrow(mappedBag = try sut.compactMapValue(transform))
        XCTAssertEqual(mappedBag?.count, expectedResult.count)
        // then returns a bag with the elelents which had their values
        // mapped to the transformed value
        if mappedBag != nil  {
            XCTAssertTrue(mappedBag!.elementsEqual(expectedResult, by: { $0.key == $1.key && $0.value == $1.value }))
            assertCountIsCorrentOnEveryNode(bag: mappedBag!)
        } else {
            XCTFail("returned nil instead")
        }
        
        // when transform always returns nil
        transform = { _ in return nil }
        mappedBag = nil
        XCTAssertNoThrow(mappedBag = try sut.compactMapValue(transform))
        // then returns nil
        XCTAssertNil(mappedBag)
    }
    
    func testFilter_whenIsIncludedThrows_thenRethrows() {
        let isIncluded: (Bag.Element) throws -> Bool = { _ in
            throw err
        }
        whenIsASequentialList()
        XCTAssertThrowsError(try sut.filter(isIncluded))
    }
    
    func testFilter_whenIsIncludedDoesntThrow_thenDoesntThrowAndReturnsFilteredBag() {
        // when isIncluded returns always true
        var isIncluded: (Bag.Element) throws -> Bool = { _ in return true }
        var filteredBag: Bag? = nil
        XCTAssertNoThrow(filteredBag = try sut.filter(isIncluded))
        // then returns same bag
        XCTAssertEqual(filteredBag, sut)
        
        // when isIncluded returns false for some elements
        let midValue = sut
            .map { $0.value }
            .sorted()[sut.count / 2]
        isIncluded = { return $0.value >= midValue }
        let expectedResult = (try! sut!.filter(isIncluded))!
        filteredBag = nil
        XCTAssertNoThrow(filteredBag = try sut.filter(isIncluded))
        // then returns a different bag with included elements
        if filteredBag != nil {
            XCTAssertTrue(filteredBag!.elementsEqual(expectedResult, by: { $0.key == $1.key && $0.value == $1.value }))
            assertCountIsCorrentOnEveryNode(bag: filteredBag!)
        } else {
            XCTFail("returned nil instead")
        }
        
        // when isIncluded returns false for every element
        isIncluded = { _ in return false }
        filteredBag = nil
        XCTAssertNoThrow(filteredBag = try sut.filter(isIncluded))
        // then returns nil
        XCTAssertNil(filteredBag)
    }
    
    // MARK: - Sequence conformance tests
    func testUnderEstimatedCount_returnsCount() {
        XCTAssertEqual(sut.underestimatedCount, sut.count)
        
        whenIsASequentialList()
        XCTAssertEqual(sut.underestimatedCount, sut.count)
        for _ in 1..<sut.count {
            let k = givenRandomKeyContainedInSut()
            sut = sut.removingValue(forKey: k).afterRemoval
            XCTAssertEqual(sut.underestimatedCount, sut.count)
        }
        for _ in 0..<10 {
            sut.setValue(randomValue(), forKey: randomKey())
            XCTAssertEqual(sut.underestimatedCount, sut.count)
        }
    }
    
    func testMakeIterator() {
        var iterator = sut.makeIterator()
        XCTAssertNotNil(iterator)
        
        whenIsASequentialList()
        iterator = sut.makeIterator()
        XCTAssertNotNil(iterator)
    }
    
    func testIteratorNext() {
        // next == nil
        XCTAssertNil(sut.next)
        var iter = sut.makeIterator()
        var expectedElement = iter.next()
        XCTAssertNotNil(expectedElement)
        XCTAssertEqual(expectedElement?.0, sut.key)
        XCTAssertEqual(expectedElement?.1, sut.value)
        expectedElement = iter.next()
        XCTAssertNil(expectedElement)
        
        // next != nil
        whenIsASequentialList()
        iter = sut.makeIterator()
        var current: Bag? = sut
        for _ in 0..<sut.count {
            expectedElement = iter.next()
            XCTAssertNotNil(expectedElement)
            XCTAssertEqual(current?.key, expectedElement?.0)
            XCTAssertEqual(current?.value, expectedElement?.1)
            current = current?.next
        }
        XCTAssertNil(current)
        XCTAssertNil(iter.next())
    }
    
    // MARK: - Equatable conformance tests
    func testEqual_whenAreSameInstance_thenReturnsTrue() {
        let rhs = sut
        XCTAssertEqual(rhs, sut)
    }
    
    func testEqual_whenRHSIsCloneOfLHS_thenReturnsTrue() {
        whenIsASequentialList()
        let rhs = sut.clone()
        XCTAssertEqual(sut, rhs)
    }
    
    func testEqual_whenStoredPropertiesAreNotEqual_thenReturnsFalse() {
        whenIsASequentialList()
        var rhs = sut.clone()
        rhs.count += 10
        XCTAssertNotEqual(sut, rhs)
        
        rhs = sut.clone()
        rhs.key += "23"
        XCTAssertNotEqual(sut, rhs)
        
        rhs = sut.clone()
        rhs.value += 1000
        XCTAssertNotEqual(sut, rhs)
        
        rhs = sut.clone()
        rhs.next = nil
        XCTAssertNotEqual(sut, rhs)
        XCTAssertNotEqual(rhs, sut)
        
        rhs = sut.clone()
        rhs.next?.key += "23"
        XCTAssertNotEqual(sut, rhs)
        XCTAssertNotEqual(rhs, sut)
    }
    
    // MARK: - Hashable conformance tests
    func testHashInto() {
        var lHasher = Hasher()
        var rHasher = Hasher()
        
        // same instances, then same hash value:
        whenIsASequentialList()
        var r = sut
        
        lHasher.combine(sut)
        rHasher.combine(r)
        XCTAssertEqual(lHasher.finalize(), rHasher.finalize())
        
        // different instances, then same hash value:
        lHasher = Hasher()
        rHasher = Hasher()
        r = sut.clone()
        lHasher.combine(sut)
        rHasher.combine(r)
        XCTAssertEqual(lHasher.finalize(), rHasher.finalize())
        
        // different, then different hash value
        lHasher = Hasher()
        rHasher = Hasher()
        r = sut.clone()
        r?.key += "23"
        lHasher.combine(sut)
        rHasher.combine(r)
        XCTAssertNotEqual(lHasher.finalize(), rHasher.finalize())
        
        // equal elements but in different positions,
        // then different hash value
        lHasher = Hasher()
        rHasher = Hasher()
        r = sut.clone()
        let s = r!.element
        r!.key = r!.next!.key
        r!.value = r!.next!.value
        r!.next!.key = s.key
        r!.next!.value = s.value
        lHasher.combine(sut)
        rHasher.combine(r)
        XCTAssertNotEqual(lHasher.finalize(), rHasher.finalize())
    }
    
}
