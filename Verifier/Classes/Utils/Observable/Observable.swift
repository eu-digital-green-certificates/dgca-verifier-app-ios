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
