//
//  ParseURLSessionDelegate.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/4/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

class ParseURLSessionDelegate: NSObject, URLSessionDelegate, URLSessionDataDelegate, URLSessionDownloadDelegate
{
    var callbackQueue: DispatchQueue
    var authentication: ((URLAuthenticationChallenge,
                          (URLSession.AuthChallengeDisposition,
                           URLCredential?) -> Void) -> Void)?
    var downloadDelegates = [URLSessionDownloadTask: ((URLSessionDownloadTask, Int64, Int64, Int64) -> Void)]()
    var uploadDelegates = [URLSessionTask: ((URLSessionTask, Int64, Int64, Int64) -> Void)]()
    var streamDelegates = [URLSessionTask: InputStream]()
    var taskCallbackQueues = [URLSessionTask: DispatchQueue]()

    init (callbackQueue: DispatchQueue,
          authentication: ((URLAuthenticationChallenge,
                            (URLSession.AuthChallengeDisposition,
                             URLCredential?) -> Void) -> Void)?) {
        self.callbackQueue = callbackQueue
        self.authentication = authentication
        super.init()
    }

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition,
                                                  URLCredential?) -> Void) {
        if let authentication = authentication {
            callbackQueue.async {
                authentication(challenge, completionHandler)
            }
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didSendBodyData bytesSent: Int64,
                    totalBytesSent: Int64,
                    totalBytesExpectedToSend: Int64) {
        if let callBack = uploadDelegates[task],
           let queue = taskCallbackQueues[task] {

            queue.async {
                callBack(task, bytesSent, totalBytesSent, totalBytesExpectedToSend)

                if totalBytesSent == totalBytesExpectedToSend {
                    self.uploadDelegates.removeValue(forKey: task)
                }
            }
        }
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {

        if let callBack = downloadDelegates[downloadTask],
           let queue = taskCallbackQueues[downloadTask] {
            queue.async {
                callBack(downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
                if totalBytesWritten == totalBytesExpectedToWrite {
                    self.downloadDelegates.removeValue(forKey: downloadTask)
                }
            }
        }
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        downloadDelegates.removeValue(forKey: downloadTask)
        taskCallbackQueues.removeValue(forKey: downloadTask)
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        if let stream = streamDelegates[task] {
            completionHandler(stream)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        uploadDelegates.removeValue(forKey: task)
        streamDelegates.removeValue(forKey: task)
        taskCallbackQueues.removeValue(forKey: task)
    }
}
