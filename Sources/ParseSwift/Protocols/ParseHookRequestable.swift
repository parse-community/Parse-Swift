//
//  ParseHookRequestable.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/14/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

public protocol ParseHookRequestable: Codable, Equatable {
    associatedtype UserType: ParseCloudUser
    var masterKey: Bool { get }
    var user: UserType? { get set }
    var installationId: String? { get }
    var ipAddress: String { get }
    var headers: [String: String] { get }
}

extension ParseHookRequestable {
    /**
     Produce the set options that should be used for subsequent `ParseHook` requests.
     - returns: The set of options produced by the current request.
     */
    public func options() -> API.Options {
        var options = API.Options()
        if masterKey {
            options.insert(.useMasterKey)
        } else if let sessionToken = user?.sessionToken {
            options.insert(.sessionToken(sessionToken))
            if let installationId = installationId {
                options.insert(.installationId(installationId))
            }
        }
        return options
    }

    public func hydrateUser(completion: @escaping (Result<Self, ParseError>) -> Void) {
        guard let user = user else {
            let error = ParseError(code: .unknownError,
                                   message: "Resquest does not contain a user.")
            completion(.failure(error))
            return
        }
        let request = self
        user.fetch(options: options()) { result in
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
