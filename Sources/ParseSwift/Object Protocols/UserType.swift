import Foundation

internal struct CurrentUserInfo {
    static var currentUser: Any?
    static var currentSessionToken: String?
}

public protocol UserType: ObjectType {
    var username: String? { get set }
    var email: String? { get set }
    var password: String? { get set }
}

public extension UserType {
    var sessionToken: String? {
        if let currentUser = CurrentUserInfo.currentUser as? Self,
            currentUser.objectId != nil && self.objectId != nil &&
            currentUser.objectId == self.objectId {
            return CurrentUserInfo.currentSessionToken
        }

        return nil
    }

    static var className: String {
        return "_User"
    }
}

public extension UserType {
    static var current: Self? {
        return CurrentUserInfo.currentUser as? Self
    }
}

extension UserType {
    static func logIn(username: String, password: String, callback: ((Self?, Error?) -> Void)? = nil) -> Cancellable {
        let params = [
            "username": username,
            "password": password
        ].map {
            URLQueryItem(name: $0, value: $1)
        }

        return API.Endpoint.login.makeRequest(method: .get, params: params, options: []) {(data, error) in
            if let data = data {
                do {
                    let user = try getDecoder().decode(Self.self, from: data)
                    let response = try getDecoder().decode(LoginSignupResponse.self, from: data)
                    CurrentUserInfo.currentUser = user
                    CurrentUserInfo.currentSessionToken = response.sessionToken
                    callback?(user, error)
                } catch {
                    callback?(nil, error)
                }
            } else if let error = error {
                callback?(nil, error)
            } else {
                fatalError()
            }
        }
    }

    static func logOut(callback: (() -> Void)? = nil) -> Cancellable? {
        return API.Endpoint.logout.makeRequest(method: .post, options: []) {(_, _) in
            callback?()
        }
    }

    static func signUp(username: String, password: String, callback: ((Self?, Error?) -> Void)? = nil) -> Cancellable {
        let body = SignupBody(username: username, password: password)

        return API.Endpoint.signup.makeRequest(method: .post, body: body, options: []) {(data, error) in
            if let data = data {
                do {
                    let response = try getDecoder().decode(LoginSignupResponse.self, from: data)

                    var user = try getDecoder().decode(Self.self, from: data)
                    user.username = username
                    user.password = password
                    user.updatedAt = response.updatedAt ?? response.createdAt

                    // Set the current user
                    CurrentUserInfo.currentUser = user
                    CurrentUserInfo.currentSessionToken = response.sessionToken

                    callback?(user, nil)
                } catch {
                    callback?(nil, error)
                }
            } else if let error = error {
                callback?(nil, error)
            } else {
                fatalError()
            }
        }
    }
}

public struct SignupBody: Codable {
    let username: String
    let password: String
}
