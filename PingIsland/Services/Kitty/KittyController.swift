//
//  KittyController.swift
//  PingIsland
//
//  Focuses a specific kitty OS window via kitty's remote-control protocol.
//
//  kitty runs a single process for every window it owns, so
//  NSRunningApplication-based activation can only raise "some" kitty
//  window -- not necessarily the one attached to the terminal session the
//  notch is trying to jump to. kitty's remote control lets us target the
//  exact window by the id captured in KITTY_WINDOW_ID at hook time.
//
//  Requires the user's kitty.conf to set:
//    allow_remote_control socket-only
//    listen_on unix:/tmp/kitty-remote-control
//  If remote control isn't enabled, focusWindow simply fails and callers
//  fall back to the existing app-level activation.
//

import Foundation
import os.log

actor KittyController {
    static let shared = KittyController()

    nonisolated static let logger = Logger(subsystem: "com.wudanwu.pingisland", category: "KittyController")

    private init() {}

    /// Raises the kitty OS window with the given KITTY_WINDOW_ID.
    func focusWindow(kittyWindowID: String) async -> Bool {
        guard let kittyPath = await KittyPathFinder.shared.getKittyPath() else {
            return false
        }

        do {
            _ = try await ProcessExecutor.shared.run(kittyPath, arguments: [
                "@", "--to", KittyPathFinder.remoteControlSocket,
                "focus-window", "--match", "id:\(kittyWindowID)"
            ])
            return true
        } catch {
            Self.logger.debug("focusWindow(kittyWindowID:) failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}
