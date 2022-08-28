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

class ParseURLSessionDelegate: NSObject
{
    var callbackQueue: DispatchQueue
    var authentication: ((URLAuthenticationChallenge,
                          (URLSession.AuthChallengeDisposition,
                           URLCredential?) -> Void) -> Void)?

    #if compiler(>=5.5.2) && canImport(_Concurrency)
    actor SessionDelegate {
        var downloadDelegates = [URLSessionDownloadTask: ((URLSessionDownloadTask, Int64, Int64, Int64) -> Void)]()
        var uploadDelegates = [URLSessionTask: ((URLSessionTask, Int64, Int64, Int64) -> Void)]()
        var streamDelegates = [URLSessionTask: InputStream]()
        var taskCallbackQueues = [URLSessionTask: DispatchQueue]()

        func updateDownload(_ task: URLSessionDownloadTask,
                            callback: ((URLSessionDownloadTask, Int64, Int64, Int64) -> Void)?) {
            downloadDelegates[task] = callback
        }

        func removeDownload(_ task: URLSessionDownloadTask) {
            downloadDelegates.removeValue(forKey: task)
            taskCallbackQueues.removeValue(forKey: task)
        }

        func updateUpload(_ task: URLSessionTask,
                          callback: ((URLSessionTask, Int64, Int64, Int64) -> Void)?) {
            uploadDelegates[task] = callback
        }

        func removeUpload(_ task: URLSessionTask) {
            uploadDelegates.removeValue(forKey: task)
            taskCallbackQueues.removeValue(forKey: task)
        }

        func updateStream(_ task: URLSessionTask,
                          stream: InputStream) {
            streamDelegates[task] = stream
        }

        func removeStream(_ task: URLSessionTask) {
            streamDelegates.removeValue(forKey: task)
            taskCallbackQueues.removeValue(forKey: task)
        }

        func updateTask(_ task: URLSessionTask,
                        queue: DispatchQueue) {
            taskCallbackQueues[task] = queue
        }

        func removeTask(_ task: URLSessionTask) {
            taskCallbackQueues.removeValue(forKey: task)
        }
    }

    var delegates = SessionDelegate()

    #else
    var downloadDelegates = [URLSessionDownloadTask: ((URLSessionDownloadTask, Int64, Int64, Int64) -> Void)]()
    var uploadDelegates = [URLSessionTask: ((URLSessionTask, Int64, Int64, Int64) -> Void)]()
    var streamDelegates = [URLSessionTask: InputStream]()
    var taskCallbackQueues = [URLSessionTask: DispatchQueue]()
    #endif

    init (callbackQueue: DispatchQueue,
          authentication: ((URLAuthenticationChallenge,
                            (URLSession.AuthChallengeDisposition,
                             URLCredential?) -> Void) -> Void)?) {
        self.callbackQueue = callbackQueue
        self.authentication = authentication
        super.init()
    }
}

extension ParseURLSessionDelegate: URLSessionDelegate {
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
}

extension ParseURLSessionDelegate: URLSessionDataDelegate {
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didSendBodyData bytesSent: Int64,
                    totalBytesSent: Int64,
                    totalBytesExpectedToSend: Int64) {
        #if compiler(>=5.5.2) && canImport(_Concurrency)
        Task {
            if let callback = await delegates.uploadDelegates[task],
               let queue = await delegates.taskCallbackQueues[task] {
                queue.async {
                    callback(task, bytesSent, totalBytesSent, totalBytesExpectedToSend)
                }
            }
        }
        #else
        if let callback = uploadDelegates[task],
           let queue = taskCallbackQueues[task] {
            queue.async {
                callback(task, bytesSent, totalBytesSent, totalBytesExpectedToSend)
            }
        }
        #endif
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        #if compiler(>=5.5.2) && canImport(_Concurrency)
        Task {
            if let stream = await delegates.streamDelegates[task] {
                completionHandler(stream)
            }
        }
        #else
        if let stream = streamDelegates[task] {
            completionHandler(stream)
        }
        #endif
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        #if compiler(>=5.5.2) && canImport(_Concurrency)
        Task {
            await delegates.removeUpload(task)
            await delegates.removeStream(task)
            if let downloadTask = task as? URLSessionDownloadTask {
                await delegates.removeDownload(downloadTask)
            }
        }
        #else
        uploadDelegates.removeValue(forKey: task)
        streamDelegates.removeValue(forKey: task)
        taskCallbackQueues.removeValue(forKey: task)
        if let downloadTask = task as? URLSessionDownloadTask {
            downloadDelegates.removeValue(forKey: downloadTask)
        }
        #endif
    }
}

extension ParseURLSessionDelegate: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        #if compiler(>=5.5.2) && canImport(_Concurrency)
        Task {
            if let callback = await delegates.downloadDelegates[downloadTask],
               let queue = await delegates.taskCallbackQueues[downloadTask] {
                queue.async {
                    callback(downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
                }
            }
        }
        #else
        if let callback = downloadDelegates[downloadTask],
           let queue = taskCallbackQueues[downloadTask] {
            queue.async {
                callback(downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
            }
        }
        #endif
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        #if compiler(>=5.5.2) && canImport(_Concurrency)
        Task {
            await delegates.removeDownload(downloadTask)
        }
        #else
        downloadDelegates.removeValue(forKey: downloadTask)
        taskCallbackQueues.removeValue(forKey: downloadTask)
        #endif
    }
}
