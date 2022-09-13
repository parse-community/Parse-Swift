//
//  ParseFileAdaptable.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/12/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/**
 A protocol for overriding the default transfer behavior for `ParseFile`'s.
 Allows for direct uploads to other file storage providers.
 */
public protocol ParseFileTransferable: AnyObject {
    /**
     Creates a task that performs an HTTP request for uploading the specified file,
     then calls a handler upon completion.
     - parameter request: The Parse URL request object that provides the URL, cache policy,
     request type, and so on.
     - parameter fileURL: The URL of the file to upload.
     - parameter completion: The completion handler to call when the load request
     is complete. Should be in the form `(Data?, URLResponse?, URLRequest?, Error?)`.
    `Data` and `URLResponse` should be created using `makeSuccessfulUploadResponse()`.
    `URLRequest` is the request used to upload the file if available. `Error` is any error that occured
     that prevented the file upload.
     */
    func upload(with request: URLRequest,
                fromFile fileURL: URL,
                completion: @escaping (Data?, URLResponse?, URLRequest?, Error?) -> Void) throws -> URLSessionUploadTask

    /**
     Creates a task that performs an HTTP request for the specified URL request
     object, uploads the provided data, and calls a handler upon completion.
     - parameter request: The Parse URL request object that provides the URL, cache policy,
     request type, and so on.
     - parameter bodyData: The body data for the request.
     - parameter completion: The completion handler to call when the load request
     is complete. Should be in the form `(Data?, URLResponse?, URLRequest?, Error?)`.
    `Data` and `URLResponse` should be created using `makeSuccessfulUploadResponse()`.
    `URLRequest` is the request used to upload the file if available. `Error` is any error that occured
     that prevented the file upload.
     */
    func upload(with request: URLRequest,
                from bodyData: Data?,
                completion: @escaping (Data?, URLResponse?, URLRequest?, Error?) -> Void) throws -> URLSessionUploadTask

    /**
     Compose a valid file upload response with a name and url.
     
     Use this method after uploading a file to any file storage to
     respond to the Swift SDK upload request.
     - parameter name: The name of the file.
     - parameter url: The url of the file that was stored.
     - returns: A tuple of `(Data, HTTPURLResponse?)` where `Data` is the
     JSON encoded file upload response and `HTTPURLResponse` is the metadata
     associated with the response to the load request.
     */
    func makeSuccessfulUploadResponse(_ name: String, url: URL) throws -> (Data, HTTPURLResponse?)

    /**
     Compose a dummy upload task.
     
     Use this method if you do not need the Parse Swift SDK to start
     your upload task for you.
     - returns: A dummy upload task that starts an upload of zero bytes
     to localhost.
     - throws: An error of type `ParseError`.
     */
    func makeDummyUploadTask() throws -> URLSessionUploadTask
}

// MARK: Default Implementation - Internal
extension ParseFileTransferable {
    func upload(with request: URLRequest,
                fromFile fileURL: URL,
                // swiftlint:disable:next line_length
                completion: @escaping (Data?, URLResponse?, URLRequest?, Error?) -> Void) throws -> URLSessionUploadTask {
        URLSession.parse.uploadTask(with: request, fromFile: fileURL) { (data, response, error) in
            completion(data, response, request, error)
        }
    }

    func upload(with request: URLRequest,
                from bodyData: Data?,
                // swiftlint:disable:next line_length
                completion: @escaping (Data?, URLResponse?, URLRequest?, Error?) -> Void) throws -> URLSessionUploadTask {
        URLSession.parse.uploadTask(with: request, from: bodyData) { (data, response, error) in
            completion(data, response, request, error)
        }
    }
}

// MARK: Default Implementation - Public
public extension ParseFileTransferable {
    func makeSuccessfulUploadResponse(_ name: String, url: URL) throws -> (Data, HTTPURLResponse?) {
        let responseData = FileUploadResponse(name: name, url: url)
        let response = HTTPURLResponse(url: url,
                                       statusCode: 200,
                                       httpVersion: nil,
                                       headerFields: nil)
        let encodedResponseData = try ParseCoding.jsonEncoder().encode(responseData)
        return (encodedResponseData, response)
    }

    func makeDummyUploadTask() throws -> URLSessionUploadTask {
        guard let url = URL(string: "http://localhost") else {
            throw ParseError(code: .unknownError, message: "Could not create URL")
        }
        return URLSession.shared.uploadTask(with: .init(url: url), from: Data())
    }
}
