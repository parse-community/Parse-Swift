import Foundation

/**
 Objects that conform to the `ParseUser` protocol have a local representation of a user persisted to the Parse Data.
 This protocol inherits from the `ParseObject` protocol, and retains the same functionality of a `ParseObject`,
 but also extends it with various user specific methods, like authentication, signing up, and validation uniqueness.
*/
public protocol ParseUser: ParseObject {
    /**
    The username for the `ParseUser`.
    */
    var username: String? { get set }

    /**
    The email for the `ParseUser`.
    */
    var email: String? { get set }

    /**
     The password for the `ParseUser`.

     This will not be filled in from the server with the password.
     It is only meant to be set.
    */
    var password: String? { get set }
}

// MARK: Default Implementations
public extension ParseUser {
    static var className: String {
        return "_User"
    }
}

// MARK: CurrentUserContainer
struct CurrentUserContainer<T: ParseUser>: Codable {
    var currentUser: T?
    var sessionToken: String?
}

// MARK: Current User Support
extension ParseUser {
    static var currentUserContainer: CurrentUserContainer<Self>? {
        get {
            guard let currentUserInMemory: CurrentUserContainer<Self>
                = try? ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentUser) else {
                return try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser)
            }
            return currentUserInMemory
        }
        set { try? ParseStorage.shared.set(newValue, for: ParseStorage.Keys.currentUser) }
    }

    internal static func saveCurrentContainerToKeychain() {
        //Only save the BaseParseUser to keep Keychain footprint finite
        guard let currentUserInMemory: CurrentUserContainer<BaseParseUser>
            = try? ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentUser) else {
            return
        }
        try? KeychainStore.shared.set(currentUserInMemory, for: ParseStorage.Keys.currentUser)
    }

    internal static func deleteCurrentContainerFromKeychain() {
        try? ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentUser)
        try? KeychainStore.shared.delete(valueFor: ParseStorage.Keys.currentUser)
    }

    /**
     Gets the currently logged in user from the Keychain and returns an instance of it.

     - returns: Returns a `ParseUser` that is the currently logged in user. If there is none, returns `nil`.
     - warning: Only use `current` objects on the main thread as as modifications to `current` have to be unique.
    */
    public static var current: Self? {
        get { Self.currentUserContainer?.currentUser }
        set { Self.currentUserContainer?.currentUser = newValue }
    }

    /**
     The session token for the `ParseUser`.

     This is set by the server upon successful authentication.
    */
    public var sessionToken: String? {
        Self.currentUserContainer?.sessionToken
    }
}

// MARK: Logging In
extension ParseUser {

    /**
     Makes a *synchronous* request to login a user with specified credentials.

     Returns an instance of the successfully logged in `ParseUser`.
     This also caches the user locally so that calls to `+current` will use the latest logged in user.

     - parameter username: The username of the user.
     - parameter password: The password of the user.
     - parameter error: The error object to set on error.

     - throws: An error of type `ParseUser`.
     - returns: An instance of the logged in `ParseUser`.
     If login failed due to either an incorrect password or incorrect username, it throws a `ParseError`.
    */
    public static func login(username: String,
                             password: String) throws -> Self {
        return try loginCommand(username: username, password: password).execute(options: [])
    }

    /**
     Makes an *asynchronous* request to log in a user with specified credentials.
     Returns an instance of the successfully logged in `ParseUser`.

     This also caches the user locally so that calls to `+current` will use the latest logged in user.
     - parameter username: The username of the user.
     - parameter password: The password of the user.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    public static func login(
        username: String,
        password: String,
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        return loginCommand(username: username, password: password)
            .executeAsync(options: [], callbackQueue: callbackQueue, completion: completion)
    }

    private static func loginCommand(username: String,
                                     password: String) -> API.Command<NoBody, Self> {
        let params = [
            "username": username,
            "password": password
        ]

        return API.Command<NoBody, Self>(method: .GET,
                                         path: .login,
                                         params: params) { (data) -> Self in
            let response = try ParseCoding.jsonDecoder().decode(LoginSignupResponse.self, from: data)
            var user = try ParseCoding.jsonDecoder().decode(Self.self, from: data)
            user.username = username
            user.password = password

            Self.currentUserContainer = .init(
                currentUser: user,
                sessionToken: response.sessionToken
            )
            Self.saveCurrentContainerToKeychain()
            return user
        }
    }
}

// MARK: Logging Out
extension ParseUser {

    /**
    Logs out the currently logged in user in Keychain *synchronously*.
    */
    public static func logout() throws {
        _ = try logoutCommand().execute(options: [])
    }

    /**
     Logs out the currently logged in user *asynchronously*.

     This will also remove the session from the Keychain, log out of linked services
     and all future calls to `current` will return `nil`. This is preferable to using `logout`,
     unless your code is already running from a background thread.

     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: A block that will be called when logging out, completes or fails.
    */
    public static func logout(callbackQueue: DispatchQueue = .main,
                              completion: @escaping (Result<Bool, ParseError>) -> Void) {
        logoutCommand().executeAsync(options: [], callbackQueue: callbackQueue) { result in
            completion(result.map { true })
        }
    }

    private static func logoutCommand() -> API.Command<NoBody, Void> {
       return API.Command(method: .POST, path: .logout) { (_) -> Void in
            deleteCurrentContainerFromKeychain()
            currentUserContainer = nil
       }
    }
}

// MARK: Signing Up
extension ParseUser {
    /**
     Signs up the user *synchronously*.

     This will also enforce that the username isn't already taken.

     - warning: Make sure that password and username are set before calling this method.

     - returns: Returns whether the sign up was successful.
    */
    public static func signup(username: String,
                              password: String) throws -> Self {
        return try signupCommand(username: username, password: password).execute(options: [])
    }

    /**
     Signs up the user *synchronously*.

     This will also enforce that the username isn't already taken.

     - warning: Make sure that password and username are set before calling this method.

     - returns: Returns whether the sign up was successful.
    */
    public func signup() throws -> Self {
        return try signupCommand().execute(options: [])
    }

    /**
     Signs up the user *asynchronously*.

     This will also enforce that the username isn't already taken.

     - warning: Make sure that password and username are set before calling this method.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    public func signup(callbackQueue: DispatchQueue = .main,
                       completion: @escaping (Result<Self, ParseError>) -> Void) {
        return signupCommand().executeAsync(options: [], callbackQueue: callbackQueue, completion: completion)
    }

    /**
     Signs up the user *asynchronously*.

     This will also enforce that the username isn't already taken.

     - warning: Make sure that password and username are set before calling this method.

     - parameter username: The username of the user.
     - parameter password: The password of the user.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    public static func signup(
        username: String,
        password: String,
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        return signupCommand(username: username, password: password)
            .executeAsync(options: [], callbackQueue: callbackQueue, completion: completion)
    }

    private static func signupCommand(username: String,
                                      password: String) -> API.Command<SignupBody, Self> {

        let body = SignupBody(username: username, password: password)
        return API.Command(method: .POST, path: .signup, body: body) { (data) -> Self in

            let response = try ParseCoding.jsonDecoder().decode(LoginSignupResponse.self, from: data)
            var user = try ParseCoding.jsonDecoder().decode(Self.self, from: data)
            user.username = username
            user.password = password

            Self.currentUserContainer = .init(
                currentUser: user,
                sessionToken: response.sessionToken
            )
            Self.saveCurrentContainerToKeychain()
            return user
        }
    }

    private func signupCommand() -> API.Command<Self, Self> {
        return API.Command(method: .POST, path: .signup, body: self) { (data) -> Self in

            let response = try ParseCoding.jsonDecoder().decode(LoginSignupResponse.self, from: data)
            var user = try ParseCoding.jsonDecoder().decode(Self.self, from: data)
            user.username = self.username
            user.password = self.password

            Self.currentUserContainer = .init(
                currentUser: user,
                sessionToken: response.sessionToken
            )
            Self.saveCurrentContainerToKeychain()
            return user
        }
    }
}

// MARK: SignupBody
private struct SignupBody: Codable {
    let username: String
    let password: String
}

// MARK: Fetchable
extension ParseUser {
    internal static func updateKeychainIfNeeded(_ results: [Self], deleting: Bool = false) throws {
        guard let currentUser = BaseParseUser.current else {
            return
        }

        var foundCurrentUserObjects = results.filter { $0.hasSameObjectId(as: currentUser) }
        foundCurrentUserObjects = try foundCurrentUserObjects.sorted(by: {
            if $0.updatedAt == nil || $1.updatedAt == nil {
                throw ParseError(code: .unknownError,
                                 message: "Objects from the server should always have an 'updatedAt'")
            }
            return $0.updatedAt!.compare($1.updatedAt!) == .orderedDescending
        })
        if let foundCurrentUser = foundCurrentUserObjects.first {
            if !deleting {
                Self.current = foundCurrentUser
                Self.saveCurrentContainerToKeychain()
            } else {
                Self.deleteCurrentContainerFromKeychain()
            }
        }
    }

    /**
     Fetches the `ParseObject` *synchronously* with the current data from the server and sets an error if one occurs.

     - parameter options: A set of options used to save objects. Defaults to an empty set.
     - throws: An Error of `ParseError` type.
    */
    public func fetch(options: API.Options = []) throws -> Self {
        let result: Self = try fetchCommand().execute(options: options)
        try? Self.updateKeychainIfNeeded([result])
        return result
    }

    /**
     Fetches the `ParseObject` *asynchronously* and executes the given callback block.

     - parameter options: A set of options used to save objects. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    public func fetch(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
         do {
            try fetchCommand().executeAsync(options: options, callbackQueue: callbackQueue) { result in
                if case .success(let foundResult) = result {
                    try? Self.updateKeychainIfNeeded([foundResult])
                }
                completion(result)
            }
         } catch let error as ParseError {
             completion(.failure(error))
         } catch {
             completion(.failure(ParseError(code: .unknownError, message: error.localizedDescription)))
         }
    }
}

// MARK: Saveable
extension ParseUser {

    /**
     Saves the `ParseObject` *synchronously* and throws an error if there's an issue.

     - parameter options: A set of options used to save objects. Defaults to an empty set.
     - throws: A Error of type `ParseError`.

     - returns: Returns saved `ParseObject`.
    */
    public func save(options: API.Options = []) throws -> Self {
        var childObjects: [NSDictionary: PointerType]?
        var error: ParseError?
        let group = DispatchGroup()
        group.enter()
        self.ensureDeepSave(options: options) { result in
            switch result {

            case .success(let savedChildObjects):
                childObjects = savedChildObjects
                group.leave()
            case .failure(let parseError):
                error = parseError
            }
        }
        group.wait()

        if let error = error {
            throw error
        }

        let result: Self = try saveCommand().execute(options: options, childObjects: childObjects)
        try? Self.updateKeychainIfNeeded([result])
        return result
    }

    /**
     Saves the `ParseObject` *asynchronously* and executes the given callback block.

     - parameter options: A set of options used to save objects. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    public func save(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        self.ensureDeepSave(options: options) { result in
            switch result {

            case .success(let savedChildObjects):
                self.saveCommand().executeAsync(options: options, callbackQueue: callbackQueue,
                                           childObjects: savedChildObjects) { result in
                    if case .success(let foundResults) = result {
                        try? Self.updateKeychainIfNeeded([foundResults])
                    }
                    completion(result)
                }
            case .failure(let parseError):
                completion(.failure(parseError))
            }
        }
    }
}

// MARK: Deletable
extension ParseUser {
    /**
     Deletes the `ParseObject` *synchronously* with the current data from the server and sets an error if one occurs.

     - parameter options: A set of options used to save objects. Defaults to an empty set.
     - throws: An Error of `ParseError` type.
    */
    public func delete(options: API.Options = []) throws {
        _ = try deleteCommand().execute(options: options)
        try? Self.updateKeychainIfNeeded([self], deleting: true)
    }

    /**
     Deletes the `ParseObject` *asynchronously* and executes the given callback block.

     - parameter options: A set of options used to save objects. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    public func delete(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (ParseError?) -> Void
    ) {
         do {
            try deleteCommand().executeAsync(options: options, callbackQueue: callbackQueue) { result in
                switch result {

                case .success:
                    try? Self.updateKeychainIfNeeded([self], deleting: true)
                    completion(nil)
                case .failure(let error):
                    completion(error)
                }
            }
         } catch let error as ParseError {
             completion(error)
         } catch {
             completion(ParseError(code: .unknownError, message: error.localizedDescription))
         }
    }
}

// MARK: Batch Support
public extension Sequence where Element: ParseUser {

    /**
     Saves a collection of objects *synchronously* all at once and throws an error if necessary.

     - parameter options: A set of options used to save objects. Defaults to an empty set.

     - returns: Returns a Result enum with the object if a save was successful or a `ParseError` if it failed.
     - throws: `ParseError`
    */
    func saveAll(options: API.Options = []) throws -> [(Result<Self.Element, ParseError>)] {
        let commands = map { $0.saveCommand() }
        let returnResults = try API.Command<Self.Element, Self.Element>
            .batch(commands: commands)
            .execute(options: options)
        try? Self.Element.updateKeychainIfNeeded(compactMap {$0})
        return returnResults
    }

    /**
     Saves a collection of objects all at once *asynchronously* and executes the completion block when done.

     - parameter options: A set of options used to save objects. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
    */
    func saveAll(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
    ) {
        let commands = map { $0.saveCommand() }
        API.Command<Self.Element, Self.Element>
                .batch(commands: commands)
            .executeAsync(options: options, callbackQueue: callbackQueue) { results in
                switch results {

                case .success(let saved):
                    try? Self.Element.updateKeychainIfNeeded(compactMap {$0})
                    completion(.success(saved))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }

    /**
     Fetches a collection of objects *synchronously* all at once and throws an error if necessary.

     - parameter options: A set of options used to fetch objects. Defaults to an empty set.

     - returns: Returns a Result enum with the object if a fetch was successful or a `ParseError` if it failed.
     - throws: `ParseError`
     - warning: The order in which objects are returned are not guarenteed. You shouldn't expect results in
     any particular order.
    */
    func fetchAll(options: API.Options = []) throws -> [(Result<Self.Element, ParseError>)] {

        if (allSatisfy { $0.className == Self.Element.className}) {
            let uniqueObjectIds = Set(compactMap { $0.objectId })
            let query = Self.Element.query(containedIn(key: "objectId", array: [uniqueObjectIds]))
            let fetchedObjects = try query.find(options: options)
            var fetchedObjectsToReturn = [(Result<Self.Element, ParseError>)]()

            uniqueObjectIds.forEach {
                let uniqueObjectId = $0
                if let fetchedObject = fetchedObjects.first(where: {$0.objectId == uniqueObjectId}) {
                    fetchedObjectsToReturn.append(.success(fetchedObject))
                } else {
                    fetchedObjectsToReturn.append(.failure(ParseError(code: .objectNotFound,
                                                                      // swiftlint:disable:next line_length
                                                                      message: "objectId \"\(uniqueObjectId)\" was not found in className \"\(Self.Element.className)\"")))
                }
            }
            try? Self.Element.updateKeychainIfNeeded(fetchedObjects)
            return fetchedObjectsToReturn
        } else {
            throw ParseError(code: .unknownError, message: "all items to fetch must be of the same class")
        }
    }

    /**
     Fetches a collection of objects all at once *asynchronously* and executes the completion block when done.

     - parameter options: A set of options used to fetch objects. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
     - warning: The order in which objects are returned are not guarenteed. You shouldn't expect results in
     any particular order.
    */
    func fetchAll(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
    ) {
        if (allSatisfy { $0.className == Self.Element.className}) {
            let uniqueObjectIds = Set(compactMap { $0.objectId })
            let query = Self.Element.query(containedIn(key: "objectId", array: [uniqueObjectIds]))
            query.find(options: options, callbackQueue: callbackQueue) { result in
                switch result {

                case .success(let fetchedObjects):
                    var fetchedObjectsToReturn = [(Result<Self.Element, ParseError>)]()

                    uniqueObjectIds.forEach {
                        let uniqueObjectId = $0
                        if let fetchedObject = fetchedObjects.first(where: {$0.objectId == uniqueObjectId}) {
                            fetchedObjectsToReturn.append(.success(fetchedObject))
                        } else {
                            fetchedObjectsToReturn.append(.failure(ParseError(code: .objectNotFound,
                                                                              // swiftlint:disable:next line_length
                                                                              message: "objectId \"\(uniqueObjectId)\" was not found in className \"\(Self.Element.className)\"")))
                        }
                    }
                    try? Self.Element.updateKeychainIfNeeded(fetchedObjects)
                    completion(.success(fetchedObjectsToReturn))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            completion(.failure(ParseError(code: .unknownError,
                                           message: "all items to fetch must be of the same class")))
        }
    }

    /**
     Deletes a collection of objects *synchronously* all at once and throws an error if necessary.

     - parameter options: A set of options used to delete objects. Defaults to an empty set.

     - returns: Returns a Result enum with `true` if the delete successful or a `ParseError` if it failed.
        1. A `ParseError.Code.aggregateError`. This object's "errors" property is an
        array of other Parse.Error objects. Each error object in this array
        has an "object" property that references the object that could not be
        deleted (for instance, because that object could not be found).
        2. A non-aggregate Parse.Error. This indicates a serious error that
        caused the delete operation to be aborted partway through (for
        instance, a connection failure in the middle of the delete).
     - throws: `ParseError`
    */
    func deleteAll(options: API.Options = []) throws -> [(Result<Bool, ParseError>)] {
        let commands = try map { try $0.deleteCommand() }
        let returnResults = try API.Command<Self.Element, Self.Element>
            .batch(commands: commands)
            .execute(options: options)

        try? Self.Element.updateKeychainIfNeeded(compactMap {$0})
        return returnResults
    }

    /**
     Deletes a collection of objects all at once *asynchronously* and executes the completion block when done.

     - parameter options: A set of options used to delete objects. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Bool, ParseError>)], ParseError>)`.
     Each element in the array is a Result enum with `true` if the delete successful or a `ParseError` if it failed.
     1. A `ParseError.Code.aggregateError`. This object's "errors" property is an
     array of other Parse.Error objects. Each error object in this array
     has an "object" property that references the object that could not be
     deleted (for instance, because that object could not be found).
     2. A non-aggregate Parse.Error. This indicates a serious error that
     caused the delete operation to be aborted partway through (for
     instance, a connection failure in the middle of the delete).
    */
    func deleteAll(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Bool, ParseError>)], ParseError>) -> Void
    ) {
        do {
            let commands = try map({ try $0.deleteCommand() })
            API.Command<Self.Element, Self.Element>
                    .batch(commands: commands)
                .executeAsync(options: options, callbackQueue: callbackQueue) { results in
                    switch results {

                    case .success(let deleted):
                        try? Self.Element.updateKeychainIfNeeded(compactMap {$0})
                        completion(.success(deleted))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
        } catch {
            guard let parseError = error as? ParseError else {
                completion(.failure(ParseError(code: .unknownError, message: error.localizedDescription)))
                return
            }
            completion(.failure(parseError))
        }
    }
} // swiftlint:disable:this file_length
