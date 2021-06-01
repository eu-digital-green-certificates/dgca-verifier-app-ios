/*
 *  license-start
 *  
 *  Copyright (C) 2021 Ministero della Salute and all other contributors
 *  
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  
 *      http://www.apache.org/licenses/LICENSE-2.0
 *  
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
*/

//
//  Cache.swift
//
//  Copyright © 2019. All rights reserved.
//

import Foundation

/// General purpose cache implementation with optimizations such as automatic memory management, etc.
open class Cache<Key: AnyObject, Value> {
    /// Cache object with weak key reference used for automatic memory management.
    private struct Object<Key: AnyObject, Value> {
        /// Gets or sets the cache object key.
        public weak var key: Key!
        
        /// Gets or sets the cache object value.
        public var value: Value
    }
    
    /// Gets or sets the collection of cached objects.
    private var objects: [Object<Key, Value>] = []
    
    /// Gets a list with all the cached objects.
    open var values: [Value] {
        return objects.map({ return $0.value })
    }
    
    /// Gets the number of cached objects.
    open var count: Int {
        return objects.count
    }
    
    // MARK: - Init(s)
    
    /// Creates a cache object.
    public init() {
        
    }
    
    // MARK: -
    
    /// Gets or sets a cached object based on a key.
    ///
    /// - Parameter key: The key used to identify a cached object.
    open subscript(key: Key) -> Value? {
        get {
            compact()
            
            return objects.filter({ return $0.key === key }).first?.value
        }
        
        set {
            compact()
            
            if let index = objects.firstIndex(where: { return $0.key === key }) {
                if let value = newValue {
                    objects[index].value = value
                } else {
                    objects.remove(at: index)
                }
            } else if let value = newValue {
                objects.append(Object<Key, Value>(key: key, value: value))
            }
        }
    }
    
    /// Compacts the cache by removing objects whose keys have been released.
    open func compact() {
        objects = objects.filter({ return $0.key != nil })
    }
}
