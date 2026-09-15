import Foundation

public protocol Sleeper {
    func sleep(seconds: Double) async
}

public struct ImmediateSleeper: Sleeper {
    public init() {}

    public func sleep(seconds: Double) async {}
}

public struct TaskSleeper: Sleeper {
    public init() {}

    public func sleep(seconds: Double) async {
        let ns = UInt64(max(0, seconds) * 1_000_000_000)
        try? await Task.sleep(nanoseconds: ns)
    }
}

public final class RecordingSleeper: Sleeper {
    public private(set) var sleeps: [Double] = []

    public init() {}

    public func sleep(seconds: Double) async {
        sleeps.append(seconds)
    }
}

public let gmailScanPauseSeconds = 0.15

public func quotaRetryDelays() -> [Double] {
    [1, 2, 4]
}

public func isQuotaDetail(_ detail: String) -> Bool {
    let lower = detail.lowercased()
    return lower.contains("quota") || lower.contains("rate limit")
}

public func isQuotaError(_ error: Error) -> Bool {
    guard let sweep = error as? MarkSweepError else { return false }
    guard case let .httpStatus(status, detail) = sweep else { return false }
    return quotaStatus(status) && isQuotaDetail(detail)
}

public func nextQuotaDelay(_ delays: inout [Double], error: Error) -> Double? {
    if isQuotaError(error) == false { return nil }
    if delays.isEmpty { return nil }
    return delays.removeFirst()
}

public func performWithQuotaRetry<T>(
    sleeper: Sleeper,
    work: () async throws -> T
) async throws -> T {
    var delays = quotaRetryDelays()
    while true {
        do { return try await work() } catch {
            guard let wait = nextQuotaDelay(&delays, error: error) else { throw error }
            await sleeper.sleep(seconds: wait)
        }
    }
}
