// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SwiftFormatPlugin",
    products: [
        .plugin(
            name: "SwiftFormatBuildToolPlugin",
            targets: ["SwiftFormatBuildToolPlugin"]
        ),
        .plugin(
            name: "SwiftFormatCommandPlugin",
            targets: ["SwiftFormatCommandPlugin"]
        ),
    ],
    targets: [
        .plugin(
            name: "SwiftFormatBuildToolPlugin",
            capability: .buildTool()
        ),
        .plugin(
            name: "SwiftFormatCommandPlugin",
            capability: .command(
                intent: .sourceCodeFormatting(),
                permissions: [
                    .writeToPackageDirectory(reason: "Format Swift source files in-place.")
                ]
            )
        ),
    ]
)
