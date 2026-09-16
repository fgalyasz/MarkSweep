import Foundation

public enum MarkSweepError: Error, Equatable {
    case notConnected
    case httpStatus(Int, String)
    case decode
    case oauthDenied
    case oauthStateMismatch
    case missingClientID
    case tokenMissing
    case listenFailed
    case tokenSaveFailed
}
