import CryptoKit
import Foundation

public struct PKCEChallenge: Equatable {
    public let verifier: String
    public let challenge: String
    public let state: String

    public init(verifier: String, challenge: String, state: String) {
        self.verifier = verifier
        self.challenge = challenge
        self.state = state
    }
}

public func base64URLEncode(_ data: Data) -> String {
    data.base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
}

public func randomURLSafeString(byteCount: Int) -> String {
    var bytes = [UInt8](repeating: 0, count: byteCount)
    _ = SecRandomCopyBytes(kSecRandomDefault, byteCount, &bytes)
    return base64URLEncode(Data(bytes))
}

public func pkceChallengeS256(verifier: String) -> String {
    let digest = SHA256.hash(data: Data(verifier.utf8))
    return base64URLEncode(Data(digest))
}

public func makePKCEChallenge() -> PKCEChallenge {
    let verifier = randomURLSafeString(byteCount: 32)
    let state = randomURLSafeString(byteCount: 16)
    return PKCEChallenge(verifier: verifier, challenge: pkceChallengeS256(verifier: verifier), state: state)
}
