PLATFORM_IOS = iOS Simulator,name=iPhone 11 Pro Max
PLATFORM_MACOS = macOS
PLATFORM_TVOS = tvOS Simulator,name=Apple TV 4K (at 1080p)
PLATFORM_WATCHOS = watchOS Simulator,name=Apple Watch Series 4 - 44mm

default: test

test:
	set -o pipefail && env NSUnbufferedIO=YES xcodebuild test \
		-scheme ParseSwift\ \(iOS\) \
		-destination platform="$(PLATFORM_IOS)"
                | xcpretty
        xcodebuild test \
		-scheme ParseSwift\ \(macOS\) \
		-destination platform="$(PLATFORM_MACOS)"
                | xcpretty
	xcodebuild test \
		-scheme ParseSwift\ \(tvOS\) \
		-destination platform="$(PLATFORM_TVOS)"
                | xcpretty
	set -o pipefail && env NSUnbufferedIO=YES xcodebuild \
		-scheme ParseSwift\ \(watchOS\) \
		-destination platform="$(PLATFORM_WATCHOS)" \
                | xcpretty

format:
	swift format --in-place --recursive \
		./Package.swift ./Sources ./Tests

.PHONY: format test-all test-swift test-workspace
