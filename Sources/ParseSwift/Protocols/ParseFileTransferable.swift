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
     is complete. This handler is executed on the delegate queue.
     */
    func upload(with request: URLRequest,
                fromFile fileURL: URL,
                completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTask

    /**
     Creates a task that performs an HTTP request for the specified URL request
     object, uploads the provided data, and calls a handler upon completion.
     - parameter request: The Parse URL request object that provides the URL, cache policy,
     request type, and so on.
     - parameter bodyData: The body data for the request.
     - parameter completion: The completion handler to call when the load request
     is complete. This handler is executed on the delegate queue.
     */
    func upload(with request: URLRequest,
                from bodyData: Data?,
                completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTask
}

extension ParseFileTransferable {
    func upload(with request: URLRequest,
                fromFile fileURL: URL,
                completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTask {
        URLSession.parse.uploadTask(with: request, fromFile: fileURL, completionHandler: completion)
    }

    func upload(with request: URLRequest,
                from bodyData: Data?,
                completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTask {
        URLSession.parse.uploadTask(with: request, from: bodyData, completionHandler: completion)
    }
}
