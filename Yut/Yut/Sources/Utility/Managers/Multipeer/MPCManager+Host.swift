import MultipeerConnectivity

extension MPCManager: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Task { @MainActor [weak self] in
            guard let self, self.advertiser === advertiser else {
                invitationHandler(false, nil)
                return
            }
            let accepted = acceptInvitation(from: peerID)
            invitationHandler(accepted, accepted ? session : nil)
        }
    }

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        Task { @MainActor [weak self] in
            guard let self, self.advertiser === advertiser else { return }
            report(error)
        }
    }
}
