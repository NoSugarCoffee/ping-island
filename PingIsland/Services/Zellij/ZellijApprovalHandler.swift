//
//  ZellijApprovalHandler.swift
//  PingIsland
//
//  Sends free-text follow-up messages into a zellij pane. Approve/deny for
//  blocking-hook clients (Claude Code and compatible) does not need this --
//  see HookSocketServer.respondToPermissionBySession, which answers over
//  the hook socket directly and works regardless of terminal/multiplexer.
//  This mirrors ToolApprovalHandler's keystroke-injection path only for the
//  capability that genuinely has no socket-based equivalent: typing an
//  arbitrary follow-up prompt into the running CLI.
//

import Foundation
import os.log

actor ZellijApprovalHandler {
    static let shared = ZellijApprovalHandler()

    nonisolated static let logger = Logger(subsystem: "com.wudanwu.pingisland", category: "ZellijApproval")

    private init() {}

    /// Send a message to a zellij target
    func sendMessage(_ message: String, to target: ZellijTarget) async -> Bool {
        await sendKeys(to: target, keys: message, pressEnter: true)
    }

    // MARK: - Private Methods

    private func sendKeys(to target: ZellijTarget, keys: String, pressEnter: Bool) async -> Bool {
        guard let zellijPath = await ZellijPathFinder.shared.getZellijPath() else {
            return false
        }

        let sessionArgs = ["--session", target.session]
        let writeArgs = sessionArgs + ["action", "write-chars", "-p", target.paneId, keys]

        do {
            Self.logger.debug("Sending text to \(target.targetString, privacy: .public)")
            _ = try await ProcessExecutor.shared.run(zellijPath, arguments: writeArgs)

            if pressEnter {
                Self.logger.debug("Sending Enter key")
                let enterArgs = sessionArgs + ["action", "send-keys", "-p", target.paneId, "Enter"]
                _ = try await ProcessExecutor.shared.run(zellijPath, arguments: enterArgs)
            }
            return true
        } catch {
            Self.logger.error("Error: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}
