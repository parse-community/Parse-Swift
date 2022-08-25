//
//  ParseHookRequestable.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/14/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/**
 Conforming to `ParseHookRequestable` allows you to create types that
 can decode requests when `ParseHookFunctionable` functions are called.
 - requires: `.useMasterKey` has to be available. It is recommended to only
 use the master key in server-side applications where the key is kept secure and not
 exposed to the public.
 */
public protocol ParseHookRequestable: ParseTypeable {
    associatedtype UserType: ParseCloudUser
    /**
     Specifies if the **masterKey** was used in the
     Parse hook call.
     */
    var masterKey: Bool? { get }
    /**
     A `ParseUser` that contains additional attributes
     needed for Parse hook calls. If **nil** a user with
     a valid session did not make the call.
     */
    var user: UserType? { get set }
    /**
     If set, the installationId triggering the request.
     */
    var installationId: String? { get }
    /**
     The IP address of the client making the request.
     */
    var ipAddress: String? { get }
    /**
     The original HTTP headers for the request.
     */
    var headers: [String: String]? { get }
}

extension ParseHookRequestable {
    /**
     Produce the set of options that should be used for subsequent `ParseHook` requests.
     - returns: The set of options produced by the current request.
     */
    public func options() -> API.Options {
        var options = API.Options()
        if let masterKey = masterKey,
            masterKey {
            options.insert(.useMasterKey)
        } else if let sessionToken = user?.sessionToken {
            options.insert(.sessionToken(sessionToken))
            if let installationId = installationId {
                options.insert(.installationId(installationId))
            }
        } else if let installationId = installationId {
            options.insert(.installationId(installationId))
        }
        return options
    }

    /**
     Fetches the complete `ParseUser`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: A block that will be called when the Cloud Code completes or fails.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     */
    public func hydrateUser(options: API.Options = [],
                            callbackQueue: DispatchQueue = .main,
                            completion: @escaping (Result<Self, ParseError>) -> Void) {
        guard let user = user else {
            let error = ParseError(code: .unknownError,
                                   message: "Resquest does not contain a user.")
            completion(.failure(error))
            return
        }
        let request = self
        var updatedOptions = self.options()
        updatedOptions.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        options.forEach { updatedOptions.insert($0) }
        user.fetch(options: updatedOptions,
                   callbackQueue: callbackQueue) { result in
            switch result {
            case .success(let fetchedUser):
                let updatedRequest = request.applyUser(fetchedUser)
                completion(.success(updatedRequest))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func applyUser(_ updatedUser: UserType) -> Self {
        var mutableRequest = self
        mutableRequest.user = updatedUser
        mutableRequest.user?.sessionToken = self.user?.sessionToken
        return mutableRequest
    }
}
