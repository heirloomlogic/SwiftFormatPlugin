# SwiftFormatPlugin

A lightweight SPM plugin that lints and formats Swift source files using `swift-format` from the Swift 6 toolchain.

Works on **macOS**, **Linux**, and **Windows**.

## Plugins

| Plugin | Type | What it does |
|---|---|---|
| **SwiftFormatBuildToolPlugin** | Build Tool | Runs `swift-format lint` automatically on every build as a pre-build step. |
| **SwiftFormatCommandPlugin** | Command | Runs `swift-format format --in-place` on demand to reformat source files. |

Both plugins work with Swift Package Manager. On macOS, Xcode project integration is also supported.

## Requirements

- **Swift 6.0+** toolchain that includes `swift-format`
- **macOS**: Xcode 16+ (the plugin invokes `swift-format` via `xcrun`)
- **Linux / Windows**: `swift-format` must be on your `$PATH`

## Installation

Add the package to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/HeirloomLogic/SwiftFormatPlugin.git", from: "1.0.0"),
]
```

### Build Tool Plugin (automatic linting)

Apply the plugin to any target you want linted on every build:

```swift
.target(
    name: "MyTarget",
    plugins: [
        .plugin(name: "SwiftFormatBuildToolPlugin", package: "SwiftFormatPlugin"),
    ]
)
```

### Command Plugin (on-demand formatting)

The command plugin registers the SwiftPM built-in `format-source-code` verb. Run it from the command line:

```bash
swift package plugin --allow-writing-to-package-directory format-source-code
```

The plugin runs silently on success — use `git diff` to see what changed.

In Xcode: **right-click your project or package → SwiftFormatCommandPlugin**.

## Configuration

The plugin looks for a `.swift-format` configuration file in your **project root**. If one is found, it will be used for both linting and formatting.

If no `.swift-format` file is present, the plugin falls back to a sensible built-in default configuration that includes, among other things:

- 4-space indentation, 120-character line length
- Ordered imports and trailing commas
- `NeverForceUnwrap`, `NeverUseForceTry`, and `NeverUseImplicitlyUnwrappedOptionals`
- `AllPublicDeclarationsHaveDocumentation`
- `FileScopedDeclarationPrivacy` set to `private`

To customize, define your own `.swift-format` file in the root of your project. You can generate a starter configuration with:

```bash
# macOS
xcrun swift-format dump-configuration > .swift-format

# Linux / Windows
swift-format dump-configuration > .swift-format
```

## How It Works

On **macOS**, the plugins invoke `swift-format` via `/usr/bin/xcrun`, which resolves to the binary in your active Xcode toolchain. On **Linux** and **Windows**, the plugins invoke `swift-format` directly from your `$PATH`. This means:

- **Zero compile-time cost** — no `swift-syntax` dependency tree to build.
- **Always in sync** with your toolchain's Swift version.
- **No binary artifacts** to download or manage.

## License

This project is available under the MIT License. See [LICENSE](LICENSE) for details.
