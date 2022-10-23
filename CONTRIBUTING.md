# Contributing to the ParseSwift SDK <!-- omit in toc -->

## Table of Contents <!-- omit in toc -->
- [Contributing](#contributing)
- [Why Contributing?](#why-contributing)
- [Environment Setup](#environment-setup)
  - [Setting up your local machine](#setting-up-your-local-machine)
  - [Swift Playgrounds](#swift-playgrounds)
  - [Please Do's](#please-dos)
- [Pull Request](#pull-request)
- [Evolution](#evolution)
- [Code of Conduct](#code-of-conduct)

We really want the ParseSwift SDK to be yours, to see it grow and thrive in the open source community.

If you are not familiar with Pull Requests and want to know more about them, you can visit the [Creating a pull request](https://help.github.com/articles/creating-a-pull-request/) article. It contains detailed information about the process.

## Contributing

Before you start to code, please open a [new issue](https://github.com/netreconlab/Parse-Swift/issues/new/choose) to describe your idea, or search for and continue the discussion in an [existing issue](https://github.com/netreconlab/Parse-Swift/issues).

> ⚠️ Please do not post a security vulnerability on GitHub. Instead, follow the [Security Policy](https://github.com/netreconlab/parse-server/security/policy).

Please completely fill out any templates to provide essential information about your new feature or the bug you discovered.

Together we will plan out the best conceptual approach for your contribution, so that your and our time is invested in the best possible approach. The discussion often reveals how to leverage existing features of ParseSwift SDK to reach your goal with even less effort and in a more sustainable way.

When you are ready to code, you can find more information about opening a pull request in the [GitHub docs](https://help.github.com/articles/creating-a-pull-request/).

Whether this is your first contribution or you are already an experienced contributor, do not hesitate to ask for help!

## Why Contributing?

Buy cheap, buy twice. What? No, this is not the Economics 101 class, but the same is true for contributing.

There are two ways of writing a feature or fixing a bug. Sometimes the quick solution is to just write a Cloud Code function that does what you want. Contributing by making the change directly in ParseSwift may take a bit longer, but it actually saves you much more time in the long run.

Consider the benefits you get:

- #### 🚀 Higher efficiency
  Your code is examined for efficiency and interoperability with existing features by the community.
- #### 🛡 Stronger security
  Your code is scrutinized for bugs and vulnerabilities and automated checks help to identify security issues that may arise in the future.
- #### 🧬 Continuous improvement
  If your feature is used by others it is likely to be continuously improved and extended by the community.
- #### 💝 Giving back
  You give back to the community that contributed to make the Parse Platform become what it is today and for future developers to come.
- #### 🧑‍🎓 Improving yourself
  You learn to better understand the inner workings of ParseSwift, which will help you to write more efficient and resilient code for your own application.

Most importantly, with every contribution you improve your skills so that future contributions take even less time and you get all the benefits above for free — easy choice, right?

## Environment Setup

### Setting up your local machine

* [Fork](https://github.com/netreconlab/Parse-Swift) this project and clone the fork on to your local machine:

```sh
$ git clone https://github.com/netreconlab/Parse-Swift
$ cd Parse-Swift # go into the clone directory
```

* Please install [SwiftLint](https://github.com/realm/SwiftLint) to ensure that your PR conforms to our coding standards:

```sh
$ brew install swiftlint
```

### Swift Playgrounds

Any feature additions should work with a real Parse Server. You can experiment with features in the ParseSwift SDK by modifying the [ParseSwift Playground files](https://github.com/netreconlab/Parse-Swift/tree/main/ParseSwift.playground/Pages). It is recommended to make sure your ParseSwift workspace in Xcode is set to build for `ParseSwift (macOS)` framework when using Swift Playgrounds. To configure the playgounds, you can do one of the following:

* Use the pre-configured parse-server in [this repo](https://github.com/netreconlab/parse-hipaa/tree/parse-swift) which comes with docker compose files (`docker-compose up` gives you a working server) configured to connect with the ParseSwift Playgrounds. The docker comes with [Parse Dashboard](https://github.com/parse-community/parse-dashboard) and can be used with MongoDB or PostgreSQL.
* Configure the ParseSwift Playgrounds to work with your own Parse Server by editing the configuation in [Common.swift](https://github.com/netreconlab/Parse-Swift/blob/e9ba846c399257100b285d25d2bd055628b13b4b/ParseSwift.playground/Sources/Common.swift#L4-L19).

### Please Do's

* Take testing seriously! Aim to increase the test coverage with every pull request
* Add/modify test files for the code you are working on in [ParseSwiftTests](https://github.com/netreconlab/Parse-Swift/tree/main/Tests/ParseSwiftTests)
* Run the tests for the file you are working on using Xcode
* Run the tests for the whole project to make sure the code passes all tests. This can be done by running the tests in Xcode
* Address all errors and warnings your fixes introduce as the ParseSwift SDK should have zero warnings
* Test your additions in Swift Playgrounds and add to the Playgrounds if applicable
* Please consider if any changes to the [docs](http://docs.parseplatform.org) are needed or add additional sections in the case of an enhancement or feature.

## Pull Request

For release automation, the title of pull requests needs to be written in a defined syntax. We loosely follow the [Conventional Commits](https://www.conventionalcommits.org) specification, which defines this syntax:

```
<type>: <summary>
```

The _type_ is the category of change that is made, possible types are:
- `feat` - add a new feature
- `fix` - fix a bug
- `refactor` - refactor code without impact on features or performance
- `docs` - add or edit code comments, documentation, GitHub pages
- `style` - edit code style
- `build` - retry failing build and anything build process related
- `perf` - performance optimization
- `ci` - continuous integration
- `test` - tests

The _summary_ is a short change description in present tense, not capitalized, without period at the end. This summary will also be used as the changelog entry.
- It must be short and self-explanatory for a reader who does not see the details of the full pull request description
- It must not contain abbreviations, e.g. instead of `LQ` write `LiveQuery`
- It must use the correct product and feature names as referenced in the documentation, e.g. instead of `Cloud Validator` use `Cloud Function validation`
- In case of a breaking change, the summary must not contain duplicate information that is also in the [BREAKING CHANGE](#breaking-change) chapter of the pull request description. It must not contain a note that it is a breaking change, as this will be automatically flagged as such if the pull request description contains the BREAKING CHANGE chapter.

For example:

```
feat: add handle to door for easy opening
```

Currently, we are not making use of the commit _scope_, which would be written as `<type>(<scope>): <summary>`, that attributes a change to a specific part of the product.

## Evolution

The ParseSwift SDK is not a port of the [Parse-SDK-iOS-OSX SDK](https://github.com/parse-community/Parse-SDK-iOS-OSX) and though some of it may feel familiar, it is not backwards compatible and is designed using [protocol oriented programming (POP) and value types](https://www.pluralsight.com/guides/protocol-oriented-programming-in-swift) instead of OOP and reference types. You can learn more about POP by watching [this](https://developer.apple.com/videos/play/wwdc2015/408/) or [that](https://developer.apple.com/videos/play/wwdc2016/419/) videos from previous WWDC's. Please see [this thread](https://github.com/parse-community/Parse-Swift/issues/3) for a detailed discussion about the intended evolution of this SDK.
