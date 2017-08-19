import Foundation

internal var _applicationId: String!
internal var _masterKey: String?
internal var _clientKey: String?
internal var _serverURL: URL!
internal var _mountPath: String!

public func initialize(applicationId: String, clientKey: String? = nil, masterKey: String? = nil, serverURL: URL) {
    _applicationId = applicationId
    _clientKey = clientKey
    _masterKey = masterKey
    _serverURL = serverURL
    _mountPath = "/" + serverURL.pathComponents.filter { $0 != "/" }.joined(separator: "/")
}

extension String {

    /// Percent escapes values to be added to a URL query as specified in RFC 3986
    ///
    /// This percent-escapes all characters besides the alphanumeric character set and "-", ".", "_", and "~".
    ///
    /// http://www.ietf.org/rfc/rfc3986.txt
    ///
    /// :returns: Returns percent-escaped string.

    func addingPercentEncodingForURLQueryValue() -> String? {
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")

        return self.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
    }

}

/// Build string representation of HTTP parameter dictionary of keys and objects
///
/// This percent escapes in compliance with RFC 3986
///
/// http://www.ietf.org/rfc/rfc3986.txt
///
/// :returns: String representation in the form of key1=value1&key2=value2 where the keys and values are percent escaped
func stringFromHttpParameters<T>(_ params: [String: T]) -> String where T: Encodable {
    return params.flatMap { (key, value) -> String? in
        let percentEscapedKey = key.addingPercentEncodingForURLQueryValue()!
        if let percentEscapedValue = try? getEncoder().encode(value) {
            return "\(percentEscapedKey)=\(percentEscapedValue)"
        }
        return nil
    }.joined(separator: "&")
}
//}

