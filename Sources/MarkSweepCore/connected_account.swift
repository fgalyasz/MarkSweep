import Foundation

public struct ConnectedAccount: Equatable, Codable {
    public let kind: AccountKind
    public let email: String

    public init(kind: AccountKind, email: String) {
        self.kind = kind
        self.email = email
    }
}
