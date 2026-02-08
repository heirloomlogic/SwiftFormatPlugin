import Foundation
import PackagePlugin

@main
struct SwiftFormatBuildToolPlugin: BuildToolPlugin {
    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) throws -> [Command] {
        guard let sourceModule = target as? SourceModuleTarget else {
            return []
        }

        let sourceFiles = sourceModule.sourceFiles(withSuffix: ".swift")
        guard !sourceFiles.isEmpty else {
            return []
        }

        let configPath = try resolveConfiguration(
            projectRoot: context.package.directoryURL,
            pluginWorkDirectory: context.pluginWorkDirectoryURL
        )

        var arguments: [String] = [
            "swift-format", "lint",
            "--configuration", configPath,
        ]
        for file in sourceFiles {
            arguments.append(file.url.path)
        }

        return [
            .prebuildCommand(
                displayName: "swift-format lint (\(target.name))",
                executable: swiftFormatExecutable(),
                arguments: arguments,
                outputFilesDirectory: context.pluginWorkDirectoryURL
            )
        ]
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
