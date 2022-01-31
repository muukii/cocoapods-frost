# cocoapods-frost

A plugin for [CocoaPods](https://cocoapods.org/) that creates XCFramework(for internal distribution) for speeding up build time.

## How it works

- Defines pod by `frost_pod` that creates xcframework.
- Builds and creates XCFramework with `-allow-internal-distribution` from build settings CocoaPods generated.
- Generates a `podspec.json` that installs xcframework as `vendored_frameworks`
- `frost_pod` uses that generated podspec as a local pod. which installs xcframework instead of sources.
