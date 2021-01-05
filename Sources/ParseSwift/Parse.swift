import Foundation

internal struct ParseConfiguration {
    static var applicationId: String!
    static var masterKey: String? // swiftlint:disable:this inclusive_language
    static var clientKey: String?
    static var serverURL: URL!
    static var liveQuerysServerURL: URL?
    static var mountPath: String!
    static var sessionDelegate: ParseURLSessionDelegate!
    static var isTestingSDK = false //Enable this only for certain tests like ParseFile
}

/**
 `ParseSwift` contains static functions that handle global configuration for the Parse framework.
 - parameter applicationId: The application id of your Parse application.
 - parameter clientKey: The client key of your Parse application.
 - parameter masterKey: The master key of your Parse application.
 - parameter serverURL: The server URL to connect to Parse Server.
 - parameter liveQueryServerURL: The server URL to connect to Parse Server.
 - parameter primitiveObjectStore: A key/value store that conforms to the `PrimitiveObjectStore`
 protocol. Defaults to `nil` in which one will be created an memory, but never persisted.
 - parameter authentication: A callback block that will be used to receive/accept/decline network challenges.
 Defaults to `nil` in which the SDK will use the default OS authentication methods for challenges.
 It should have the following argument signature: `(challenge: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition,
 URLCredential?) -> Void) -> Void`.
 See Apple's [documentation](https://developer.apple.com/documentation/foundation/urlsessiontaskdelegate/1411595-urlsession) for more for details.
 */
public func initialize(
    applicationId: String,
    clientKey: String? = nil,
    masterKey: String? = nil,
    serverURL: URL,
    liveQueryServerURL: URL? = nil,
    primitiveObjectStore: PrimitiveObjectStore? = nil,
    authentication: ((URLAuthenticationChallenge,
                      (URLSession.AuthChallengeDisposition,
                       URLCredential?) -> Void) -> Void)? = nil
) {
    ParseConfiguration.applicationId = applicationId
    ParseConfiguration.clientKey = clientKey
    ParseConfiguration.masterKey = masterKey
    ParseConfiguration.serverURL = serverURL
    ParseConfiguration.liveQuerysServerURL = liveQueryServerURL
    ParseConfiguration.mountPath = "/" + serverURL.pathComponents
                                            .filter { $0 != "/" }
                                            .joined(separator: "/")
    ParseStorage.shared.use(primitiveObjectStore ?? CodableInMemoryPrimitiveObjectStore())
    ParseConfiguration.sessionDelegate = ParseURLSessionDelegate(callbackQueue: .main, authentication: authentication)
    //Prepare installation
    DispatchQueue.main.async {
        _ = BaseParseInstallation()
    }
}

internal func initialize(applicationId: String,
                         clientKey: String? = nil,
                         masterKey: String? = nil,
                         serverURL: URL,
                         liveQueryServerURL: URL? = nil,
                         primitiveObjectStore: PrimitiveObjectStore? = nil,
                         testing: Bool = false,
                         authentication: ((URLAuthenticationChallenge,
                                           (URLSession.AuthChallengeDisposition,
                                            URLCredential?) -> Void) -> Void)? = nil) {
    ParseConfiguration.isTestingSDK = testing

    initialize(applicationId: applicationId,
               clientKey: clientKey,
               masterKey: masterKey,
               serverURL: serverURL,
               liveQueryServerURL: liveQueryServerURL,
               authentication: authentication)
}
