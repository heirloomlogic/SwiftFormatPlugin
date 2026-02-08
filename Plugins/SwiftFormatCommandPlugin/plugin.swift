import Foundation
import PackagePlugin

@main
struct SwiftFormatCommandPlugin: CommandPlugin {
    func performCommand(
        context: PluginContext,
        arguments: [String]
    ) throws {
        let configPath = try resolveConfiguration(
            projectRoot: context.package.directoryURL,
            pluginWorkDirectory: context.pluginWorkDirectoryURL
        )

        for target in context.package.targets {
            guard let sourceModule = target as? SourceModuleTarget else {
                Diagnostics.remark(
                    "Skipping target \"\(target.name)\" because it is not a source module."
                )
                continue
            }

            let sourceFiles = sourceModule.sourceFiles(withSuffix: ".swift")
            guard !sourceFiles.isEmpty else {
                Diagnostics.remark(
                    "Skipping target \"\(target.name)\" because it has no Swift source files."
                )
                continue
            }

            try format(sourceFiles: sourceFiles, targetName: target.name, configPath: configPath)
        }
    }

    func format(sourceFiles: FileList, targetName: String, configPath: String) throws {
        var arguments: [String] = [
            "swift-format", "format",
            "--in-place",
            "--parallel",
            "--configuration", configPath,
        ]

        let swiftFiles = sourceFiles.filter {
            $0.type == .source && $0.url.pathExtension == "swift"
        }
        arguments += swiftFiles.map { $0.url.path(percentEncoded: false) }

        let process = Process()
        process.executableURL = swiftFormatExecutable()
        process.arguments = arguments

        try process.run()
        process.waitUntilExit()

        guard process.terminationReason == .exit, process.terminationStatus == EXIT_SUCCESS else {
            Diagnostics.error(
                "swift-format format failed for target \"\(targetName)\" "
                    + "(status \(process.terminationStatus))."
            )
            return
        }

        Diagnostics.remark("Formatted Swift source files in target \"\(targetName)\".")
    }

    /// Returns the executable URL used to invoke `swift-format`.
    /// On macOS this is `xcrun` (resolves from the active Xcode toolchain).
    /// On Linux / Windows the binary is expected on `$PATH`.
    private func swiftFormatExecutable() -> URL {
        #if os(macOS)
            URL(fileURLWithPath: "/usr/bin/xcrun")
        #else
            URL(fileURLWithPath: "/usr/bin/env")
        #endif
    }

    // MARK: - Configuration Resolution

    /// Looks for `.swift-format` in the downstream project root.
    /// Falls back to an embedded default written to the plugin work directory.
    func resolveConfiguration(
        projectRoot: URL,
        pluginWorkDirectory: URL
    ) throws -> String {
        let projectConfig = projectRoot.appendingPathComponent(".swift-format")
        if FileManager.default.fileExists(atPath: projectConfig.path) {
            Diagnostics.remark(
                "Using project configuration at \(projectConfig.path)."
            )
            return projectConfig.path
        }

        let fallbackURL = pluginWorkDirectory.appendingPathComponent("swift-format-fallback.json")
        try fallbackConfigJSON.write(to: fallbackURL, atomically: true, encoding: .utf8)
        Diagnostics.remark(
            "No .swift-format found in project root; using bundled fallback configuration."
        )
        return fallbackURL.path
    }
}

// MARK: - Embedded Fallback Configuration

/// The default `.swift-format` configuration shipped with this plugin.
/// Downstream projects can override this by placing their own `.swift-format`
/// in the project root.
private let fallbackConfigJSON = """
    {
      "fileScopedDeclarationPrivacy": {
        "accessLevel": "private"
      },
      "indentConditionalCompilationBlocks": true,
      "indentSwitchCaseLabels": false,
      "indentation": {
        "spaces": 4
      },
      "lineBreakAroundMultilineExpressionChainComponents": false,
      "lineBreakBeforeControlFlowKeywords": false,
      "lineBreakBeforeEachArgument": true,
      "lineBreakBeforeEachGenericRequirement": false,
      "lineBreakBetweenDeclarationAttributes": false,
      "lineLength": 120,
      "maximumBlankLines": 1,
      "multiElementCollectionTrailingCommas": true,
      "noAssignmentInExpressions": {
        "allowedFunctions": [
          "XCTAssertNoThrow"
        ]
      },
      "prioritizeKeepingFunctionOutputTogether": true,
      "reflowMultilineStringLiterals": "never",
      "respectsExistingLineBreaks": true,
      "rules": {
        "AllPublicDeclarationsHaveDocumentation": true,
        "AlwaysUseLiteralForEmptyCollectionInit": false,
        "AlwaysUseLowerCamelCase": true,
        "AmbiguousTrailingClosureOverload": true,
        "AvoidRetroactiveConformances": true,
        "BeginDocumentationCommentWithOneLineSummary": false,
        "DoNotUseSemicolons": true,
        "DontRepeatTypeInStaticProperties": true,
        "FileScopedDeclarationPrivacy": true,
        "FullyIndirectEnum": true,
        "GroupNumericLiterals": true,
        "IdentifiersMustBeASCII": true,
        "NeverForceUnwrap": true,
        "NeverUseForceTry": true,
        "NeverUseImplicitlyUnwrappedOptionals": true,
        "NoAccessLevelOnExtensionDeclaration": true,
        "NoAssignmentInExpressions": true,
        "NoBlockComments": true,
        "NoCasesWithOnlyFallthrough": true,
        "NoEmptyLinesOpeningClosingBraces": true,
        "NoEmptyTrailingClosureParentheses": true,
        "NoLabelsInCasePatterns": true,
        "NoLeadingUnderscores": true,
        "NoParensAroundConditions": true,
        "NoPlaygroundLiterals": true,
        "NoVoidReturnOnFunctionSignature": true,
        "OmitExplicitReturns": true,
        "OneCasePerLine": true,
        "OneVariableDeclarationPerLine": true,
        "OnlyOneTrailingClosureArgument": true,
        "OrderedImports": true,
        "ReplaceForEachWithForLoop": true,
        "ReturnVoidInsteadOfEmptyTuple": true,
        "TypeNamesShouldBeCapitalized": true,
        "UseEarlyExits": false,
        "UseExplicitNilCheckInConditions": true,
        "UseLetInEveryBoundCaseVariable": true,
        "UseShorthandTypeNames": true,
        "UseSingleLinePropertyGetter": true,
        "UseSynthesizedInitializer": true,
        "UseTripleSlashForDocumentationComments": true,
        "UseWhereClausesInForLoops": true,
        "ValidateDocumentationComments": false
      },
      "spacesAroundRangeFormationOperators": false,
      "spacesBeforeEndOfLineComments": 2,
      "tabWidth": 4,
      "version": 1
    }
    """
