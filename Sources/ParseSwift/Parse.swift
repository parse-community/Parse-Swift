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

// swiftlint:disable:next inclusive_language
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
    _ = URLSession.parse //Initialize Parse URLSession now
    DispatchQueue.main.async {
        _ = BaseParseInstallation()
    }
}

// swiftlint:disable:next inclusive_language
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
               primitiveObjectStore: primitiveObjectStore,
               authentication: authentication)
}
