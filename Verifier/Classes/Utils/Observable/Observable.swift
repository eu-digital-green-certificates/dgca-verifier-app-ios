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
//  Observable.swift
//
//  Copyright © 2019. All rights reserved.
//

import Foundation

/// Provides the means of tracking value changes by keeping a list of observers that are notified each time the value changes.
open class Observable<T> {
    /// Observable callback.
    public typealias Callback = (T?)->Void
    
    /// The cache of observer objects.
    private var observers: Cache<AnyObject, Callback> = Cache<AnyObject, Callback>()
    
    /// Gets or sets the value that is being monitored.
    open var value: T? {
        didSet {
            observers.values.forEach {
                $0(value)
            }
        }
    }
    
    // MARK: - Init(s)
    
    /// Creates an observable object.
    ///
    /// - Parameter value: The initil observable value.
    public init(_ value: T? = nil) {
        self.value = value
    }
    
    // MARK: - Observers
    
    /// Adds an observer to the list.
    ///
    /// - Parameters:
    ///   - observer: The observer to add.
    ///   - callback: The observer callback.
    open func add(observer: AnyObject, _ callback: @escaping Callback) {
        observers[observer] = callback
    }
    
    /// Removes an observer from the list.
    ///
    /// - Parameter observer: The observer to remove.
    open func remove(observer: AnyObject) {
        observers[observer] = nil
    }
}
