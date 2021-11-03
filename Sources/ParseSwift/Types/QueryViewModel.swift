//
//  QueryViewModel.swift
//  ParseSwift
//
//  Created by Corey Baker on 7/3/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if canImport(SwiftUI)
import Foundation

/**
 A default implementation of the `QueryObservable` protocol. Suitable for `ObjectObserved`
 and can be used as a SwiftUI view model. Also can be used as a Combine publisher. See Apple's
 [documentation](https://developer.apple.com/documentation/combine/observableobject)
 for more details.
 */
open class QueryViewModel<T: ParseObject>: QueryObservable {

    public var query: Query<T>
    public typealias Object = T

    /// Updates and notifies when the new results have been retrieved.
    open var results = [Object]() {
        willSet {
            count = newValue.count
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }

    /// Updates and notifies when the count of the results have been retrieved.
    open var count = 0 {
        willSet {
            error = nil
            if newValue != results.count {
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            }
        }
    }

    /// Updates and notifies when there is an error retrieving the results.
    open var error: ParseError? {
        willSet {
            if newValue != nil {
                results.removeAll()
                count = results.count
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            }
        }
    }

    required public init(query: Query<T>) {
        self.query = query
    }

    open func find(options: API.Options = []) {
        query.find(options: options) { result in
            switch result {
            case .success(let results):
                self.results = results
            case .failure(let error):
                self.error = error
            }
        }
    }

    open func findAll(batchLimit: Int? = nil,
                      options: API.Options = []) {

        query.findAll(batchLimit: batchLimit,
                      options: options) { result in
            switch result {
            case .success(let results):
                self.results = results
            case .failure(let error):
                self.error = error
            }
        }
    }

    open func first(options: API.Options = []) {
        query.first(options: options) { result in
            switch result {
            case .success(let result):
                self.results = [result]
            case .failure(let error):
                self.error = error
            }
        }
    }

    open func count(options: API.Options = []) {
        query.count(options: options) { result in
            switch result {
            case .success(let count):
                self.count = count
            case .failure(let error):
                self.error = error
            }
        }
    }

    open func aggregate(_ pipeline: [[String: Encodable]],
                        options: API.Options = []) {
        query.aggregate(pipeline, options: options) { result in
            switch result {
            case .success(let results):
                self.results = results
            case .failure(let error):
                self.error = error
            }
        }
    }
}

// MARK: QueryViewModel
public extension Query {

    /**
     Creates a view model for this query. Suitable for `ObjectObserved`
     as the view model can be used as a SwiftUI publisher. Meaning it can serve
     indepedently as a ViewModel in MVVM.
     */
    var viewModel: QueryViewModel<ResultType> {
        QueryViewModel(query: self)
    }

    /**
     Creates a view model for this query. Suitable for `ObjectObserved`
     as the view model can be used as a SwiftUI publisher. Meaning it can serve
     indepedently as a ViewModel in MVVM.
     - parameter query: Any query.
     - returns: The view model for this query.
     */
    static func viewModel(_ query: Self) -> QueryViewModel<ResultType> {
        QueryViewModel(query: query)
    }
}
#endif
