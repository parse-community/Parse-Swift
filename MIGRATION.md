# Migration from Parse ObjC SDK <!-- omit in toc -->

This document describes how to migrate from the [Parse ObjC SDK](https://github.com/parse-community/Parse-SDK-iOS-OSX) to the Parse Swift SDK.

ℹ️ *This document is a work-in-progress. If you find information missing, please submit a pull request to help us updating this document for the benefit of others.*

- [Status of the SDKs](#status-of-the-sdks)
- [Migration Instructions](#migration-instructions)
- [Behavioral Differences](#behavioral-differences)
- [Known Issues](#known-issues)
- [Feature Comparison](#feature-comparison)

# Status of the SDKs

The Parse ObjC SDK will be phased out in the future in favor of the more modern Parse Swift SDK. While both SDKs overlap in the ecosystems they serve, they are built conceptually different, which can make migration more challenging. Your milage may vary depending on your use case, we therefore encourage you to migrate as soon as possible.

# Migration Instructions

1. x
2. x
3. x

# Behavioral Differences

- x
- x
- x

# Known Issues

The issues below are important to consider before migrating.

- ⚠️ Partially updating an object sends the full object to the server; this can have a significant impact on data transfer costs depending on your use case and architecture. All other Parse SDKs including the Parse ObjC SDK only send the changed properties to the server. For details see [GitHub issue #242](https://github.com/parse-community/Parse-Swift/issues/242).

# Feature Comparison

This table only lists features that are known to be available in the Parse ObjC SDK but still missing in the Swift SDK. *This table is a work-in-progress.*

| Feature | Parse ObjC SDK | Parse Swift SDK |
|---------|----------------|-----------------|
| -       | -              | -               |
