//
//  ZellijPathFinder.swift
//  PingIsland
//
//  Finds zellij executable path
//

import Foundation

/// Finds and caches the zellij executable path
actor ZellijPathFinder {
    static let shared = ZellijPathFinder()

    private var cachedPath: String?

    private init() {}

    /// Get the path to zellij executable
    func getZellijPath() -> String? {
        if let cached = cachedPath {
            return cached
        }

        let home = FileManager.default.homeDirectoryForCurrentUser.path

        // Unlike tmux (almost always Homebrew or system-packaged), zellij is
        // commonly installed via cargo or a user package manager (e.g. nix
        // profiles), so more install locations are checked here.
        let possiblePaths = [
            "/opt/homebrew/bin/zellij",       // Apple Silicon Homebrew
            "/usr/local/bin/zellij",          // Intel Homebrew
            "/usr/bin/zellij",                // System
            "/bin/zellij",
            "\(home)/.cargo/bin/zellij",       // cargo install
            "\(home)/.nix-profile/bin/zellij" // nix profile / home-manager
        ]

        for path in possiblePaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                cachedPath = path
                return path
            }
        }

        return nil
    }

    /// Check if zellij is available
    func isZellijAvailable() -> Bool {
        getZellijPath() != nil
    }
}
