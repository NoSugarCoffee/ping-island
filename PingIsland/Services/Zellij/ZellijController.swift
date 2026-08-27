//
//  ZellijController.swift
//  PingIsland
//
//  High-level zellij operations controller
//

import Foundation

/// Controller for zellij operations
actor ZellijController {
    static let shared = ZellijController()

    private init() {}

    func findZellijTarget(forClaudePid pid: Int) async -> ZellijTarget? {
        await ZellijTargetFinder.shared.findTarget(forClaudePid: pid)
    }

    func findZellijTarget(forWorkingDirectory dir: String) async -> ZellijTarget? {
        await ZellijTargetFinder.shared.findTarget(forWorkingDirectory: dir)
    }

    func sendMessage(_ message: String, to target: ZellijTarget) async -> Bool {
        await ZellijApprovalHandler.shared.sendMessage(message, to: target)
    }

    /// Focus the tab and pane for the given target. Zellij pane IDs are
    /// unique per-session (unlike tmux, where panes are scoped per-window),
    /// so a single focus-pane-id call is expected to switch tabs as needed.
    func switchToPane(target: ZellijTarget) async -> Bool {
        guard let zellijPath = await ZellijPathFinder.shared.getZellijPath() else {
            return false
        }

        do {
            _ = try await ProcessExecutor.shared.run(zellijPath, arguments: [
                "--session", target.session, "action", "focus-pane-id", target.paneId
            ])
            return true
        } catch {
            return false
        }
    }
}
