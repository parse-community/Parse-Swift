import Foundation

private var currentUser: Any?

private func setCurrentUser<T>(user: T) where T: ParseUserType {
    currentUser = user
}

protocol ParseUserType: ParseObjectType {

}

extension ParseUserType {
    static var current: Self? {
        return currentUser as? Self
    }

    static func login(email: String, password: String) -> RESTCommand<NoBody, Self> {
        return RESTCommand(method: .POST, path: "/users/login", mapper: { (data) -> Self in
            let r = try JSONDecoder().decode(Self.self, from: data)
            setCurrentUser(user: r)
            return r
        })
    }
}

