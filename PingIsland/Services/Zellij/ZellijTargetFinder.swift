//
//  ZellijTargetFinder.swift
//  PingIsland
//
//  Finds zellij targets for Claude processes
//
//  Unlike tmux, zellij's `list-panes` output carries no pane PID, so
//  PID-based matching is done indirectly: resolve the caller's PID to its
//  working directory (the same lsof-based helper tmux's fallback path
//  already uses) and match that against each pane's `pane_cwd`. Zellij also
//  has no `-a`/"all sessions" flag on `list-panes` -- each session must be
//  queried individually via `zellij --session <name> action list-panes`.
//

import Foundation

private struct ZellijPane: Decodable {
    let id: Int
    let isPlugin: Bool
    let isFocused: Bool
    let exited: Bool
    let paneCommand: String?
    let paneCwd: String?

    enum CodingKeys: String, CodingKey {
        case id
        case isPlugin = "is_plugin"
        case isFocused = "is_focused"
        case exited
        case paneCommand = "pane_command"
        case paneCwd = "pane_cwd"
    }
}

/// Finds zellij session/pane targets for Claude processes
actor ZellijTargetFinder {
    static let shared = ZellijTargetFinder()

    private init() {}

    /// Find the zellij target for a given Claude PID by resolving the
    /// process's working directory and matching it against pane_cwd.
    func findTarget(forClaudePid claudePid: Int) async -> ZellijTarget? {
        guard let workingDir = ProcessTreeBuilder.shared.getWorkingDirectory(forPid: claudePid) else {
            return nil
        }

        return await findTarget(forWorkingDirectory: workingDir, preferringCommand: "claude")
    }

    /// Find the zellij target for a given working directory
    func findTarget(forWorkingDirectory workingDir: String) async -> ZellijTarget? {
        await findTarget(forWorkingDirectory: workingDir, preferringCommand: nil)
    }

    /// Check if a session's zellij pane is currently the focused pane
    func isSessionPaneActive(claudePid: Int) async -> Bool {
        guard let target = await findTarget(forClaudePid: claudePid) else {
            return false
        }

        guard let panes = await listPanes(session: target.session) else {
            return false
        }

        guard let paneId = Int(target.paneId) else { return false }
        return panes.contains { $0.id == paneId && !$0.isPlugin && $0.isFocused }
    }

    // MARK: - Private Methods

    private func findTarget(forWorkingDirectory workingDir: String, preferringCommand: String?) async -> ZellijTarget? {
        guard let zellijPath = await ZellijPathFinder.shared.getZellijPath() else {
            return nil
        }

        guard let sessionNames = await listSessions(zellijPath: zellijPath), !sessionNames.isEmpty else {
            return nil
        }

        var fallback: ZellijTarget?

        for session in sessionNames {
            guard let panes = await listPanes(zellijPath: zellijPath, session: session) else { continue }

            for pane in panes where !pane.isPlugin && !pane.exited {
                guard pane.paneCwd == workingDir else { continue }

                let target = ZellijTarget(session: session, paneId: String(pane.id))

                if let preferringCommand,
                   pane.paneCommand?.lowercased().contains(preferringCommand) == true {
                    return target
                }

                if fallback == nil {
                    fallback = target
                }
            }
        }

        return fallback
    }

    private func listSessions(zellijPath: String) async -> [String]? {
        do {
            let output = try await ProcessExecutor.shared.run(zellijPath, arguments: ["list-sessions", "-n", "-s"])
            let names = output.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            return names
        } catch {
            return nil
        }
    }

    private func listPanes(session: String) async -> [ZellijPane]? {
        guard let zellijPath = await ZellijPathFinder.shared.getZellijPath() else { return nil }
        return await listPanes(zellijPath: zellijPath, session: session)
    }

    private func listPanes(zellijPath: String, session: String) async -> [ZellijPane]? {
        do {
            let output = try await ProcessExecutor.shared.run(zellijPath, arguments: [
                "--session", session, "action", "list-panes", "--json"
            ])
            guard let data = output.data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode([ZellijPane].self, from: data)
        } catch {
            return nil
        }
    }
}
