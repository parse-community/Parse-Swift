//
//  ParseAuthenticationRegistry.swift
//  ParseSwift
//
//  Created by Cory Imdieke on 3/29/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

public protocol ParseAuthenticationDelegate {
	/**
	 Called when restoring third party authentication credentials that have been serialized,
	 such as session keys, user id, etc.
	 - This method will be executed on a background thread.
	 - parameter authData: The auth data for the provider. This value may be `nil` when unlinking an account.
	 - returns `true` - if the `authData` was succesfully synchronized,
	 or `false` if user should not longer be associated because of bad `authData`.
	 */
	func restoreAuthentication(withAuthData authData: [String: String]) -> Bool
}

/**
 This is a system that maintains a list of auth providers available to the SDK.
 The primary reason is so we can notify these providers when we're going to restore an
 auth session that originated from that provider. This gives the provider a chance to
 re-instate any data necessary for use in the app.
 */
public struct ParseAuthenticationRegistry {
	private static var authRegistry: [String: ParseAuthenticationDelegate] = [:]
	private static var restoredAuthResults: [String: Bool] = [:]

	/**
	Registers an authentication delegate for a specific auth type. Optional, only necessary if your custom authentication
	provider needs to respond to the authentication delegate methods and restore state during user restoration.
	*/
	public static func registerAuthenticationDelegate(_ delegate: ParseAuthenticationDelegate, forAuthType type: String) {
		// TODO: We have a check to make sure each type is only registered once, but do we actually care? Should we just let this succeed?
		assert(authRegistry[type] == nil, "Tried to register an auth delegate to a type name that already exists")

		authRegistry[type] = delegate
	}

	internal static func restoreAuthentication(forType type: String, authData: [String: String]?) -> Bool {
		guard let authData = authData else {
			return true
		}

		if let previousResponse = restoredAuthResults[type] {
			// Already restored, return same result as last time
			return previousResponse
		} else if let delegate = authRegistry[type] {
			let result = delegate.restoreAuthentication(withAuthData: authData)
			restoredAuthResults[type] = result
			return result
		} else {
			return true
		}
	}
}
