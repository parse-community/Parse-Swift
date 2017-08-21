//: [Previous](@previous)

import PlaygroundSupport
import Foundation
import ParseSwift
PlaygroundPage.current.needsIndefiniteExecution = true

//: start parse-server with
//: npm start -- --appId applicationId --clientKey clientKey --masterKey masterKey --mountPath /1

func shell(_ args: String, prelaunch: ((Process) -> Void)? = nil) -> Int32 {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = ["bash", "-c", args]
    prelaunch?(task)
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}

func killOldParse() {
    shell("ps aux | grep parse-server | awk '{print $2}' | xargs kill -9")
}

func startMongodb() {
    shell("mongodb-runner --start")
}

func printCWD() {
    guard let jsonPath = Bundle.main.url(forResource: "package", withExtension: "json") else { return }
    print(jsonPath)
    let resources = jsonPath.deletingPathExtension().deletingLastPathComponent()
    print(resources.absoluteString)
    let process = Process()
    process.launchPath = "/Users/florent/.nvm/versions/node/v7.4.0/bin/npm"
    // process.currentDirectoryPath = resources.absoluteString
    process.environment = [
        "PATH": "/Users/florent/.nvm/versions/node/v7.4.0/bin",
        "VERBOSE": "1"
    ]
    process.arguments = ["install", "parse-server", "mongodb-runner"]
    process.launch()
    process.waitUntilExit()
    // print(Bundle.main.path(forResource: "package", ofType: "json"))
    print(FileManager.default.currentDirectoryPath)
    shell("echo $PWD")
}

public func startParse(applicationId: String,
                       clientKey: String? = nil,
                       masterKey: String,
                       mountPath: String) {
//    killOldParse()
//    startMongodb()
//    shell(args: "which node")
//    let arguments =  ["--appId", applicationId, "--masterKey", masterKey, "--mountPath", mountPath]
//    let process = Process()
//    process.environment = [
//        "PATH": "/Users/florent/.nvm/versions/node/v7.4.0/bin",
//        "VERBOSE": "1"
//    ]
//    process.launchPath = "/Users/florent/src/Parse/parse-server/bin/parse-server"
//    process.arguments = arguments
//    process.terminationHandler = { process in
//        print("Terminated...")
//    }
//    process.launch()
//    print("Parse-server Started!", process.processIdentifier)
}

initializeParse()

struct GameScore: ParseSwift.ObjectType {
    //: Those are required for Object
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ACL?

    //: Your own properties
    var score: Int

    //: a custom initializer
    init(score: Int) {
        self.score = score
    }
}

var score = GameScore(score: 10)

guard let score = try? score.sync.save() else { fatalError() }
assert(score.objectId != nil)
assert(score.createdAt != nil)
assert(score.updatedAt != nil)
assert(score.score == 10)

// Need to make it a var as Value Types
var changedScore = score
changedScore.score = 200
guard let savedScore = try? changedScore.sync.save() else { fatalError() }
assert(score.score == 10)
assert(score.objectId == changedScore.objectId)

// TODO: Add support for sync saveAll
// let score2 = GameScore(score: 3)
//GameScore.saveAll(score, score2) { (result) in
//    guard case .success(let results) = result else {
//        assert(false)
//        return
//    }
//    results.forEach { (result) in
//        let (_, error) = result
//        assert(error == nil, "error should be nil")
//    }
//}
//
//// Also works as extension of sequence
//[score, score2].saveAll { (result) in
//    guard case .success(let results) = result else {
//        assert(false)
//        return
//    }
//    results.forEach { (result) in
//        let (_, error) = result
//        assert(error == nil, "error should be nil")
//    }
//
//}
//
//print("Done!")
PlaygroundPage.current.finishExecution()
//: [Next](@next)
