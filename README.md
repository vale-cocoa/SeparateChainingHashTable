# SeparateChainingHashTable

A collection whose elements are key-value pairs, stored via a separate chaining hash table.

`SeparateChainingHashTable` shares the same functionalities of Swift `Dictionary`, except for invalidating its `Indicies` every time a call to a mutating method was done —no matter if a mutation has really took effect or not.
