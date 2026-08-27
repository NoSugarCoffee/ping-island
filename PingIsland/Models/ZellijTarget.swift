//
//  ZellijTarget.swift
//  PingIsland
//
//  Data model for zellij session/pane targeting
//

import Foundation

/// Represents a zellij target (session name + pane id, e.g. "my-session:3")
struct ZellijTarget: Sendable {
    let session: String
    let paneId: String

    nonisolated var targetString: String {
        "\(session):\(paneId)"
    }

    nonisolated init(session: String, paneId: String) {
        self.session = session
        self.paneId = paneId
    }

    /// Parse from the internal target string format "session:paneId"
    nonisolated init?(from targetString: String) {
        let parts = targetString.split(separator: ":", maxSplits: 1)
        guard parts.count == 2 else { return nil }

        self.session = String(parts[0])
        self.paneId = String(parts[1])
    }
}
