import Foundation

public enum MarkSweepError: Error, Equatable {
    case notConnected
    case httpStatus(Int)
    case decode
    case oauthDenied
    case oauthStateMismatch
    case missingClientID
    case tokenMissing
    case listenFailed
}
