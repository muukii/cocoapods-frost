# cocoapods-frost

A plugin for [CocoaPods](https://cocoapods.org/) that creates XCFramework(for internal distribution) for speeding up build time.

## How it works

- Defines pod by `frost_pod` that creates XCFramework.
- Builds and creates XCFramework with `-allow-internal-distribution` from build settings CocoaPods generated.
- Generates a `podspec.json` that installs XCFramework as `vendored_frameworks`
- `frost_pod` uses that generated podspec as a local pod. which installs XCFramework instead of sources.

## Usage

Specifies pods with `pod_frost` that needs to create XCFramework.  
Still, using `pod` can be left to build from source code.

```ruby
frost_pod "Moya"
frost_pod "MondrianLayout"

pod "JAYSON"
```

## Subspecs

CocoaPods integrates multiple subspecs into one module.  
Generated XCFramework contains all of subspecs specified in Podfile.

For instance,

https://github.com/Moya/Moya/blob/master/Moya.podspec

```ruby
frost_pod "Moya/Core"
frost_pod "Moya/Combine"
```
that creates `Moya.xcframework` includes core implementation and combine supports.

So `frost_pod` specifies as whole pod with dropping subspec specifiers.

## Development

It supports debugging in VSCode.

## License

MIT

## Author

- [Hiroshi Kimura (Muukii)](https://github.com/muukii)
