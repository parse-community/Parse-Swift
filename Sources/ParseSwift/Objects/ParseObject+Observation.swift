    //
    //  ParseObjectObservable.swift
    //  ParseSwift
    //
    //  Created by Craig Spell on 2/10/26.
    //

import SwiftUI

    /// A lightweight, observable wrapper around a ParseObject that integrates with SwiftUI’s Observation framework.
    ///
    /// ParseObjectObservable enables two key capabilities when working with types conforming to `ParseObject`:
    /// - Observation: It uses the `@Observable` macro (iOS 17, macOS 14 and later) so SwiftUI views can automatically
    ///   update when properties on the underlying object change.
    /// - Dynamic member lookup: It forwards property access to the wrapped `ParseObject` using `@dynamicMemberLookup`,
    ///   allowing you to read and write properties directly as if they were defined on this wrapper.
    ///
    /// Usage:
    /// - Wrap any `ParseObject` instance using the `asObservable` convenience property:
    ///   - Example: `@State private var todo = Todo().asObservable`
    /// - Access and mutate properties as usual:
    ///   - Example: `todo.title = "New Title"`
    /// - Call async persistence methods (`fetch`, `save`, `create`, `replace`, `update`, `delete`) on the wrapper to
    ///   keep the observable state in sync with the server. Successful mutating operations automatically replace the
    ///   internal value and trigger view updates.
    ///
    /// Notes:
    /// - Availability: iOS 17.0+ and macOS 14.0+.
    /// - Threading: Designed to be used from the main actor in UI code; ensure you call async methods appropriately
    ///   within Swift concurrency contexts.
    /// - Identity: This wrapper holds and replaces the underlying value on successful network operations. If your UI
    ///   depends on object identity (e.g., `id`, `objectId`, `hashValue`), be mindful that the wrapped instance may be
    ///   replaced after calls like `save()` or `fetch()`.
    ///
    /// - Generic Parameter:
    ///   - T: A type conforming to `ParseObject` that represents the underlying Parse model.
@available(macOS 14.0, iOS 17.0, *)
@Observable @dynamicMemberLookup
public class ParseObjectObservable<T: ParseObject> {
    private var value: T
    
    init(_ value: T) {
        self.value = value
    }
    
        /// Provides dynamic member lookup into the wrapped ParseObject.
        ///
        /// This subscript enables forwarding property access from the observable wrapper
        /// directly to the underlying `ParseObject` using key path-based dynamic member
        /// lookup. It allows reading and writing properties as if they were defined on
        /// `ParseObjectObservable` itself.
        ///
        /// - Parameter keyPath: A writable key path referencing a property on the
        ///   underlying `ParseObject` type `T`.
        /// - Returns: The value of the property referenced by `keyPath`.
        ///
        /// Usage:
        /// - Read a property: `let title = todo.title`
        /// - Write a property: `todo.title = "New Title"`
        ///
        /// Notes:
        /// - Because the key path is writable, setting a value mutates the wrapped
        ///   `ParseObject`. This mutation participates in SwiftUI’s Observation system
        ///   via the `@Observable` macro on this wrapper, causing dependent views to
        ///   update.
        /// - The generic `V` is the property type referenced by the provided key path.
        /// - This is intended for use with properties defined on `T` that are exposed
        ///   via `WritableKeyPath`.
    subscript<V>(dynamicMember keyPath: WritableKeyPath<T, V>) -> V {
        get { value[keyPath: keyPath] }
        set { value[keyPath: keyPath] = newValue }
    }
}


@available(macOS 14.0, iOS 17.0, *)
public extension ParseObject {
        /// A lightweight convenience property that wraps a `ParseObject` in an observable
        /// wrapper compatible with SwiftUI’s Observation framework.
        ///
        /// This property returns a `ParseObjectObservable<Self>` which:
        /// - Enables SwiftUI views to automatically update when properties on the object change,
        ///   leveraging the `@Observable` macro (iOS 17, macOS 14 and later).
        /// - Supports dynamic member lookup so you can access and mutate properties directly
        ///   on the wrapper as if they were defined on the original `ParseObject`.
        ///
        /// Usage:
        /// - Create an observable instance for use in SwiftUI state:
        ///   - `@State private var todo = Todo().asObservable`
        /// - Read and write properties as usual:
        ///   - `todo.title = "New Title"`
        /// - Call async persistence methods on the wrapper to keep state in sync with the server:
        ///   - `try await todo.save()`
        ///
        /// Notes:
        /// - Availability: iOS 17.0+ and macOS 14.0+.
        /// - Identity: Successful network operations like `save()` or `fetch()` may replace the
        ///   underlying value inside the wrapper. If your UI depends on identity (e.g., `objectId`),
        ///   account for this behavior.
        /// - Threading: Designed for use from the main actor in UI contexts; call async methods
        ///   within appropriate Swift concurrency contexts.
        ///
        /// - Returns: An observable wrapper around the receiver that integrates with SwiftUI Observation.
    var asObservable: ParseObjectObservable<Self> {
        ParseObjectObservable(self)
    }
}


@available(macOS 14.0, iOS 17.0, *)
public extension ParseObjectObservable {
    
        /// Fetches the latest state of the underlying Parse object from the server and updates this observable wrapper.
        ///
        /// This method issues a network request to retrieve the most current representation of the wrapped object (`T`)
        /// from your Parse backend. On success, the internal `value` is replaced with the fetched instance, which
        /// automatically notifies SwiftUI’s Observation system (via `@Observable`) so any dependent views are refreshed.
        ///
        /// - Parameters:
        ///   - includeKeys: An optional array of key names to include in the fetch. Use this to eagerly load related objects
        ///                  or specific fields that are not returned by default. Pass `nil` to use the server’s defaults.
        ///   - options: Additional request options to control networking behavior, caching, and other Parse client features.
        ///              Defaults to an empty set.
        /// - Returns: The freshly fetched object of type `T`.
        /// - Throws: An error if the network request fails, the object cannot be found, or if the response cannot be decoded.
        /// - Important: This method replaces the wrapped object on success. If your UI or logic depends on identity
        ///              (e.g., `objectId` or hashing), be aware the instance may change after the call completes.
        /// - Availability: iOS 17.0+, macOS 14.0+.
        /// - Concurrency: Intended for use on the main actor in UI contexts; call from an async context.
    @discardableResult func fetch(includeKeys: [String]? = nil,
                                  options: API.Options = []) async throws -> T {
        let newValue = try await value.fetch(includeKeys: includeKeys, options: options)
        self.value = newValue
        return newValue
    }
    
        /// Persists the current state of the wrapped Parse object to the server and updates this observable wrapper on success.
        ///
        /// This method forwards to `T.save(ignoringCustomObjectIdConfig:options:)` on the underlying `ParseObject`,
        /// replacing the internal value with the server-returned instance when the save completes successfully.
        /// Because `ParseObjectObservable` is annotated with `@Observable`, replacing the value automatically
        /// notifies SwiftUI’s Observation system, causing dependent views to refresh.
        ///
        /// - Parameters:
        ///   - ignoringCustomObjectIdConfig: When `true`, bypasses any client-side configuration that enforces custom
        ///     objectId behavior and allows the server to determine or accept the provided `objectId`. Leave as `false`
        ///     to respect the SDK’s configured custom objectId rules. Defaults to `false`.
        ///   - options: Additional request options that control networking behavior, caching, and other Parse client
        ///     features. Defaults to an empty set.
        /// - Returns: The saved object of type `T` as returned by the server. This is also assigned to the wrapper’s
        ///   internal value, which triggers observation updates.
        /// - Throws: An error if the save operation fails due to networking issues, validation errors, or decoding problems.
        /// - Important: Successful saves replace the wrapped instance. If your UI or logic depends on identity (e.g.,
        ///   `objectId`, equality, or hashing), be aware the instance may change after this call completes.
        /// - Availability: iOS 17.0+ and macOS 14.0+.
        /// - Concurrency: Intended for use in async contexts on the main actor in UI code.
    @discardableResult func save(ignoringCustomObjectIdConfig: Bool = false,
                                 options: API.Options = []) async throws -> T {
        let newValue = try await value.save(ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig, options: options)
        self.value = newValue
        return newValue
    }
    
        //TODO: - Add Documentation
    @discardableResult func create(options: API.Options = []) async throws -> T {
        let newValue = try await value.create(options: options)
        self.value = newValue
        return newValue
    }
    
        //TODO: - Add Documentation
    @discardableResult func replace(options: API.Options = []) async throws -> T {
        let newValue = try await value.replace(options: options)
        self.value = newValue
        return newValue
    }
    
        //TODO: - Add Documentation
    @discardableResult internal func update(options: API.Options = []) async throws -> T {
        let newValue = try await value.update(options: options)
        self.value = newValue
        return newValue
    }
    
        //TODO: - Add Documentation
    func delete(options: API.Options = []) async throws {
        try await value.delete(options: options)
    }
}


public extension Binding {
        //    #warning("This probably shouldn't be in a public extension.")
        //    static func ??<V>(lhs: Binding<V?>, rhs: V) -> Binding<V> where Value == V? {
        //        .init(lhs, replacingNilWith: rhs)
        //    }
    
        //TODO: - Add Documentation
    func `default`<V>(to defaultValue: V) -> Binding<V> where Value == V? {
        .init(get: { self.wrappedValue ?? defaultValue },
              set: { self.wrappedValue = $0 })
    }
}


