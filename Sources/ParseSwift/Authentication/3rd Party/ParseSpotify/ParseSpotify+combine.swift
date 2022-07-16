//
//  ParseSpotify+combine.swift
//  ParseSwift
//
//  Created by Ulaş Sancak on 06/20/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

public extension ParseSpotify {
    // MARK: Combine
    /**
     Login a `ParseUser` *asynchronously* using Spotify authentication. Publishes when complete.
     - parameter id: The **Spotify profile id** from **Spotify**.
     - parameter accessToken: Required **access_token** from **Spotify**.
     - parameter expiresIn: Optional **expires_in** in seconds from **Spotify**.
     - parameter refreshToken: Optional **refresh_token** from **Spotify**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func loginPublisher(id: String,
                        accessToken: String,
                        expiresIn: Int? = nil,
                        refreshToken: String? = nil,
                        options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.login(id: id,
                       accessToken: accessToken,
                       expiresIn: expiresIn,
                       refreshToken: refreshToken,
                       options: options,
                       completion: promise)
        }
    }

    /**
     Login a `ParseUser` *asynchronously* using Spotify authentication. Publishes when complete.
     - parameter authData: Dictionary containing key/values.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func loginPublisher(authData: [String: String],
                        options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.login(authData: authData,
                       options: options,
                       completion: promise)
        }
    }
}

public extension ParseSpotify {
    /**
     Link the *current* `ParseUser` *asynchronously* using Spotify authentication.
     Publishes when complete.
     - parameter id: The **Spotify profile id** from **Spotify**.
     - parameter accessToken: Required **access_token** from **Spotify**.
     - parameter expiresIn: Optional **expires_in** in seconds from **Spotify**.
     - parameter refreshToken: Optional **refresh_token** from **Spotify**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func linkPublisher(id: String,
                       accessToken: String,
                       expiresIn: Int? = nil,
                       refreshToken: String? = nil,
                       options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.link(id: id,
                      accessToken: accessToken,
                      expiresIn: expiresIn,
                      refreshToken: refreshToken,
                      options: options,
                      completion: promise)
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using Spotify authentication.
     Publishes when complete.
     - parameter authData: Dictionary containing key/values.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func linkPublisher(authData: [String: String],
                       options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.link(authData: authData,
                      options: options,
                      completion: promise)
        }
    }
}

#endif
