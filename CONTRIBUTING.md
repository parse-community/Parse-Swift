# Contributing to the ParseSwift SDK <!-- omit in toc -->

## Table of Contents <!-- omit in toc -->
- [Contributing](#contributing)
- [Environment Setup](#environment-setup)
  - [Setting up your local machine](#setting-up-your-local-machine)
  - [Swift Playgrounds](#swift-playgrounds)
  - [Please Do's](#please-dos)
- [Evolution](#evolution)
- [Code of Conduct](#code-of-conduct)

We really want the ParseSwift SDK to be yours, to see it grow and thrive in the open source community.

## Contributing

For shared Parse Platform contribution rules, pull request title syntax, review expectations, and release guidance, see the [Parse Server contribution guide](https://github.com/parse-community/parse-server/blob/alpha/CONTRIBUTING.md). This file keeps only ParseSwift-specific setup and testing notes.

Before you start to code, please open a [new issue](https://github.com/parse-community/Parse-Swift/issues/new/choose) to describe your idea, or search for and continue the discussion in an [existing issue](https://github.com/parse-community/Parse-Swift/issues).

> Please do not post a security vulnerability on GitHub or in the Parse Community Forum. Instead, follow the [Parse Community Security Policy](https://github.com/parse-community/parse-server/security/policy).

Please completely fill out any templates to provide essential information about your new feature or the bug you discovered.

When you are ready to code, use the pull request process and title format described in the shared contribution guide. If you are not familiar with pull requests, the GitHub docs explain [how to create a pull request](https://help.github.com/articles/creating-a-pull-request/).

## Environment Setup

### Setting up your local machine

* [Fork](https://github.com/parse-community/Parse-Swift) this project and clone the fork on to your local machine:

```sh
$ git clone https://github.com/parse-community/Parse-Swift
$ cd Parse-Swift # go into the clone directory
```

* Please install [SwiftLint](https://github.com/realm/SwiftLint) to ensure that your PR conforms to our coding standards:

```sh
$ brew install swiftlint
```

### Swift Playgrounds

Any feature additions should work with a real Parse Server. You can experiment with features in the ParseSwift SDK by modifying the [ParseSwift Playground files](https://github.com/parse-community/Parse-Swift/tree/main/ParseSwift.playground/Pages). It is recommended to make sure your ParseSwift workspace in Xcode is set to build for `ParseSwift (macOS)` framework when using Swift Playgrounds. To configure the playgounds, you can do one of the following:

* Use the pre-configured parse-server in [this repo](https://github.com/netreconlab/parse-hipaa/tree/parse-swift) which comes with docker compose files (`docker-compose up` gives you a working server) configured to connect with the ParseSwift Playgrounds. The docker comes with [Parse Dashboard](https://github.com/parse-community/parse-dashboard) and can be used with MongoDB or PostgreSQL.
* Configure the ParseSwift Playgrounds to work with your own Parse Server by editing the configuation in [Common.swift](https://github.com/parse-community/Parse-Swift/blob/e9ba846c399257100b285d25d2bd055628b13b4b/ParseSwift.playground/Sources/Common.swift#L4-L19).

### Please Do's

* Take testing seriously! Aim to increase the test coverage with every pull request.
* Add or modify test files for the code you are working on in [ParseSwiftTests](https://github.com/parse-community/Parse-Swift/tree/main/Tests/ParseSwiftTests).
* Run the tests for the file you are working on using Xcode.
* Run the tests for the whole project to make sure the code passes all tests. This can be done by running the tests in Xcode.
* Address all errors and warnings your fixes introduce as the ParseSwift SDK should have zero warnings.
* Test your additions in Swift Playgrounds and add to the Playgrounds if applicable.
* Please consider if any changes to the [docs](http://docs.parseplatform.org) are needed or add additional sections in the case of an enhancement or feature.

## Evolution

The ParseSwift SDK is not a port of the [Parse-SDK-iOS-OSX SDK](https://github.com/parse-community/Parse-SDK-iOS-OSX) and though some of it may feel familiar, it is not backwards compatible and is designed using [protocol oriented programming (POP) and value types](https://www.pluralsight.com/guides/protocol-oriented-programming-in-swift) instead of OOP and reference types. You can learn more about POP by watching [this](https://developer.apple.com/videos/play/wwdc2015/408/) or [that](https://developer.apple.com/videos/play/wwdc2016/419/) videos from previous WWDC's. Please see [this thread](https://github.com/parse-community/Parse-Swift/issues/3) for a detailed discussion about the intended evolution of this SDK.

## Code of Conduct

This project adheres to the [Contributor Covenant Code of Conduct](https://github.com/parse-community/.github/blob/main/CODE_OF_CONDUCT.md). By participating, you are expected to honor this code.
