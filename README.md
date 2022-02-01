# cocoapods-frost

A plugin for [CocoaPods](https://cocoapods.org/) that creates XCFramework(for internal distribution) for speeding up build time.

> 🚜 Still working on development, but partially works

**Alternatives**
- [coocapods-binary](https://github.com/leavez/cocoapods-binary)
- [PodBuilder](https://github.com/Subito-it/PodBuilder)
- [Rugby](https://github.com/swiftyfinch/Rugby)

## Support this project

If you are interested in this project or you need
- Hit the ⭐️ button to make this project popular.
- Becoming sponsorship in subscription or one-time.

<a href="https://www.buymeacoffee.com/muukii">
<img width="230" alt="yellow-button" src="https://user-images.githubusercontent.com/1888355/146226808-eb2e9ee0-c6bd-44a2-a330-3bbc8a6244cf.png">
</a>

## Features

- Supports static or dynamic by `use_frameworks! :linkage => :static`
- Supports coexisting in source code and frameworks

## known Issues

Managed in [issues](https://github.com/muukii/cocoapods-frost/issues)

- some pods fails build
  - especially, already provided as framework

## How it works

- Defines pod by `frost_pod` that creates XCFramework.
- Builds and creates XCFramework with `-allow-internal-distribution` from build settings CocoaPods generated.
- Generates a `podspec.json` that installs XCFramework as `vendored_frameworks`
- `frost_pod` uses that generated podspec as a local pod. which installs XCFramework instead of sources.

## Usage

Make bundler installs `cocoapods-frost`

`Gemfile`
```
gem 'cocoapods-frost', git: "https://github.com/muukii/cocoapods-frost.git", branch: "main"
```

Annotate Podfile that uses `cocoapods-frost` as plugin

`Podfile`
```ruby
plugin "cocoapods-frost"
```

Specifies pods with `pod_frost` that needs to create XCFramework.  
Still, using `pod` can be left to build from source code.

`Podfile`
```ruby
frost_pod "Moya"
frost_pod "MondrianLayout"

pod "JAYSON"
```

Build XCFrameworks

```sh
$ bundle exec pod frost
```

Then

```sh
$ bundle exec pod install
```

## Directory structure

- Repository
  - Podfile
  - Podfile.lock
  - FrostPodfile.lock `cocoapods-frost` creates, should be managed in git
  - Pods
  - FrostPods <- `cocoapods-frost` creates
    - GeneratedPods (should be managed in git, git-lfs, something else)

## About subspecs

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
