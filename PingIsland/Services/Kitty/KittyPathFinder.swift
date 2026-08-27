//
//  KittyPathFinder.swift
//  PingIsland
//
//  Finds the kitty executable and its remote-control socket
//

import Foundation

/// Finds and caches the kitty executable path
actor KittyPathFinder {
    static let shared = KittyPathFinder()

    /// Must match the `listen_on` value configured in the user's kitty.conf.
    /// kitty runs one process for every window it owns, so a single global
    /// socket is enough to reach all of them.
    static let remoteControlSocket = "unix:/tmp/kitty-remote-control"

    private var cachedPath: String?

    private init() {}

    func getKittyPath() -> String? {
        if let cached = cachedPath {
            return cached
        }

        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let possiblePaths = [
            "/opt/homebrew/bin/kitty",
            "/usr/local/bin/kitty",
            "/Applications/kitty.app/Contents/MacOS/kitty",
            "\(home)/.nix-profile/bin/kitty"
        ]

        for path in possiblePaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                cachedPath = path
                return path
            }
        }

        return nil
    }

    func isKittyAvailable() -> Bool {
        getKittyPath() != nil
    }
}
