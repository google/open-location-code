# Swift Implementations of Open Location Code

## Curbmap

Curbmap has a Swift 4.x and 3.x implementation located [here](https://github.com/curbmap/OpenLocationCode-swift).

Properties:
* Can be built as a Framework for iOS.
* Available via [CocoaPods](https://cocoapods.org/pods/OpenLocationCode) (`pod OpenLocationCode`).
* Includes Objective-C Bridging Interface.
* Does not implement the complete [Open Location Code API](../API.txt) (`recoverNearest` API method is not implemented).
* Not validated using the OLC [test data](../test_data).

## Open Location Code Project

The [Open Location Code for Swift and Objective-C](https://github.com/google/open-location-code-swift) library provides a Swift 5.x, 4.x, and 3.x implementation.

Properties:
* Can be built as a Framework for iOS, macOS, tvOS and watchOS.
* Available via [CocoaPods](https://cocoapods.org/pods/OpenLocationCodeFramework) (`pod OpenLocationCodeFramework`).
* Supports [Carthage](https://github.com/Carthage/Carthage).
* Includes Objective-C Bridging Interface.
* Can be built as a Swift module (with no dependency on the Foundation framework) supporting Swift on Linux and macOS.
* Available via the [Swift Package Manager](https://swift.org/package-manager/).
* Implements the complete [Open Location Code API](../API.txt).
* Validated using the OLC [test data](../test_data).
