//
//  KeySubscripts.swift
//  SeparateChainingHashTable
//
//  Created by Valeriano Della Longa on 2021/04/05.
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

extension SeparateChainingHashTable {
    /// Accesses the value associated with the given key for reading and writing.
    ///
    /// This *key-based* subscript returns the value for the given key if the key
    /// is found in the hash table, or `nil` if the key is not found.
    /// The setter of this subscript might invalidate all indices of the hash table.
    ///
    /// The following example creates a new hash table and prints the value of a
    /// key found in the has table (`"Coral"`) and a key not found in the
    /// hash table (`"Cerise"`).
    ///
    ///     var hues: SepartateChainingHashTable<String, Int> = ["Heliotrope": 296, "Coral": 16, "Aquamarine": 156]
    ///     print(hues["Coral"])
    ///     // Prints "Optional(16)"
    ///     print(hues["Cerise"])
    ///     // Prints "nil"
    ///
    /// When you assign a value for a key and that key already exists, the
    /// hash table overwrites the existing value. If the hash table doesn't
    /// contain the key, the key and value are added as a new key-value pair.
    ///
    /// Here, the value for the key `"Coral"` is updated from `16` to `18` and a
    /// new key-value pair is added for the key `"Cerise"`.
    ///
    ///     hues["Coral"] = 18
    ///     print(hues["Coral"])
    ///     // Prints "Optional(18)"
    ///
    ///     hues["Cerise"] = 330
    ///     print(hues["Cerise"])
    ///     // Prints "Optional(330)"
    ///
    /// If you assign `nil` as the value for the given key, the hash table
    /// removes that key and its associated value.
    ///
    /// In the following example, the key-value pair for the key `"Aquamarine"`
    /// is removed from the hash table by assigning `nil` to the key-based
    /// subscript.
    ///
    ///     hues["Aquamarine"] = nil
    ///     print(hues)
    ///     // Prints "["Coral": 18, "Heliotrope": 296, "Cerise": 330]"
    ///
    /// - Parameter key: The key to find in the hash table.
    /// - Returns: The value associated with `key` if `key` is in the hash table;
    ///   otherwise, `nil`.
    public subscript(_ k: Key) -> Value? {
        get { getValue(forKey: k) }
        
        mutating set {
            guard let v = newValue else {
                removeValue(forKey: k)
                
                return
            }
            
            updateValue(v, forKey: k)
        }
    }
    
    /// Accesses the value with the given key. If the hash table doesn't contain
    /// the given key, accesses the provided default value as if the key and
    /// default value existed in the hash table.
    ///
    /// Use this subscript when you want either the value for a particular key
    /// or, when that key is not present in the hash table, a default value.
    /// The setter of this subscript might invalidate all indices of the hash table.
    /// This example uses the subscript with a message to use in case an HTTP response
    /// code isn't recognized:
    ///
    ///     var responseMessages: SeparateChainingHashTable<Int, String> = [
    ///         200: "OK",
    ///         403: "Access forbidden",
    ///         404: "File not found",
    ///         500: "Internal server error"
    ///     ]
    ///
    ///     let httpResponseCodes = [200, 403, 301]
    ///     for code in httpResponseCodes {
    ///         let message = responseMessages[code, default: "Unknown response"]
    ///         print("Response \(code): \(message)")
    ///     }
    ///     // Prints "Response 200: OK"
    ///     // Prints "Response 403: Access Forbidden"
    ///     // Prints "Response 301: Unknown response"
    ///
    /// When an hash table's `Value` type has value semantics, you can use this
    /// subscript to perform in-place operations on values in the hash table.
    /// The following example uses this subscript while counting the occurrences
    /// of each letter in a string:
    ///
    ///     let message = "Hello, Elle!"
    ///     var letterCounts: SeparateChainingHashTable<Character, Int> = [:]
    ///     for letter in message {
    ///         letterCounts[letter, default: 0] += 1
    ///     }
    ///     // letterCounts == ["H": 1, "e": 2, "l": 4, "o": 1, ...]
    ///
    /// When `letterCounts[letter, defaultValue: 0] += 1` is executed with a
    /// value of `letter` that isn't already a key in `letterCounts`, the
    /// specified default value (`0`) is returned from the subscript,
    /// incremented, and then added to the hash table under that key.
    ///
    /// - Note: Do not use this subscript to modify hash table values if the
    ///   dictionary's `Value` type is a class. In that case, the default value
    ///   and key are not written back to the hash table after an operation.
    ///
    /// - Parameters:
    ///   - key: The key to look up in the hash table.
    ///   - defaultValue:   The default value to use if `key` doesn't exist
    ///                     in the hash table.
    /// - Returns:  The value associated with `key` in the hash table;
    ///             otherwise, `defaultValue`.
    public subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
        get {
            buffer?.getValue(forKey: key) ?? defaultValue()
        }
        
        _modify {
            var other = Self()
            (self, other) = (other, self)
            defer {
                (self, other) = (other, self)
            }
            other.makeUnique()
            let bag: HashTableBuffer<Key, Value>.Bag
            if let b = other.buffer!.getBag(forKey: key) {
                bag = b
            } else {
                if other.buffer!.tableIsTooTight {
                    let newCapacity = Swift.max((other.count + 1) * 3 / 2, other.capacity * 2)
                    other.buffer!.resizeTo(newCapacity: newCapacity)
                    other.changeIndexID()
                }
                bag = other.buffer!.setNewElementWith(key: key, value: defaultValue())
            }
            yield &bag.value
        }
    }
    
}
