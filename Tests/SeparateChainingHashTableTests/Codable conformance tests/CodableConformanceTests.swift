//
//  CodableConformanceTests.swift
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

final class CodableConformanceTests: XCTestCase {
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
    
    // MARK: - GIVEN
    var malformedJSONDataWithKeysAndValuesCountsNotMtching: Data {
        let kv = [
            "keys" : [ "A", "B", "C", "D", "E",],
            "values": [1, 2, 3, 4, 5, 6, 7]
        ] as [String : Any]
        
        return try! JSONSerialization.data(withJSONObject: kv, options: .prettyPrinted)
    }
    
    var malformedJSONDataWithDuplicateKeys: Data {
        let keys = givenKeysAndValuesWithDuplicateKeys().map { $0.key }
        let values = keys.map { _ in randomValue() }
        
        var kv = Dictionary<String, Any>()
        kv["keys"] = keys
        kv["values"] = values
        
        return try! JSONSerialization.data(withJSONObject: kv, options: .prettyPrinted)
    }
    
    // MARK: - WHEN
    func whenIsNotEmpty() {
        sut = HashTable(uniqueKeysWithValues: givenKeysAndValuesWithoutDuplicateKeys())
    }
    
    // MARK: - Tests
    func testEncode() {
        let encoder = JSONEncoder()
        
        XCTAssertNoThrow(try encoder.encode(sut))
        
        whenIsNotEmpty()
        XCTAssertNoThrow(try encoder.encode(sut))
    }
    
    func testEncodeThenDecode() {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        var data = try! encoder.encode(sut)
        var decoded: HashTable!
        do {
            try decoded = decoder.decode(HashTable.self, from: data)
        } catch {
            XCTFail("has thrown error")
            
            return
        }
        XCTAssertTrue(decoded.isEmpty)
        
        whenIsNotEmpty()
        data = try! encoder.encode(sut)
        do {
            try decoded = decoder.decode(HashTable.self, from: data)
        } catch {
            XCTFail("has thrown error")
            
            return
        }
        XCTAssertEqual(decoded, sut)
    }
    
    func testDecode_whenDataHasDifferentCountForKeysAndValue_thenThrowsError() {
        let data = malformedJSONDataWithKeysAndValuesCountsNotMtching
        
        do {
            try sut = JSONDecoder().decode(HashTable.self, from: data)
        } catch HashTable.Error.keysAndValuesCountsNotMatching {
            return
        } catch {
            XCTFail("thrown different error")
        }
        XCTFail("not thrown error")
    }
    
    func testDecode_whenDataHasDuplicateKeys_thenThrowsError() {
        let data = malformedJSONDataWithDuplicateKeys
        
        do {
            try sut = JSONDecoder().decode(HashTable.self, from: data)
        } catch HashTable.Error.duplicateKeys {
            return
        } catch {
            XCTFail("thrown different error")
        }
        XCTFail("not thrown error")
    }
    
}
