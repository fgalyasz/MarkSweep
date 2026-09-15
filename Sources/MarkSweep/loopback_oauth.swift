import Foundation
import Network
import MarkSweepCore

final class LoopbackOAuthCatcher {
    private var listener: NWListener?
    private var continuation: CheckedContinuation<URL, Error>?

    func collectRedirect(port: UInt16, onReady: @escaping () -> Void) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            self.beginListen(port: port, onReady: onReady)
        }
    }

    func cancel() {
        listener?.cancel()
        listener = nil
        finishWait(result: .failure(MarkSweepError.oauthDenied))
    }

    func beginListen(port: UInt16, onReady: @escaping () -> Void) {
        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            finishWait(result: .failure(MarkSweepError.listenFailed))
            return
        }
        startListener(port: nwPort, onReady: onReady)
    }

    func startListener(port: NWEndpoint.Port, onReady: @escaping () -> Void) {
        do {
            let listener = try NWListener(using: .tcp, on: port)
            listener.newConnectionHandler = { [weak self] connection in
                self?.accept(connection)
            }
            let queue = DispatchQueue(label: "marksweep.oauth.loopback")
            listener.start(queue: queue)
            self.listener = listener
            onReady()
        } catch {
            finishWait(result: .failure(MarkSweepError.listenFailed))
        }
    }

    func accept(_ connection: NWConnection) {
        connection.start(queue: DispatchQueue(label: "marksweep.oauth.connection"))
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, error in
            self?.handleReceive(connection: connection, data: data, error: error)
        }
    }

    func handleReceive(connection: NWConnection, data: Data?, error: Error?) {
        if let error {
            connection.cancel()
            finishWait(result: .failure(error))
            return
        }
        guard let data, let url = parseHTTPRequestURL(data) else {
            connection.cancel()
            finishWait(result: .failure(MarkSweepError.oauthDenied))
            return
        }
        connection.send(content: httpSuccessPage(), completion: .contentProcessed { _ in
            connection.cancel()
        })
        finishWait(result: .success(url))
    }

    func finishWait(result: Result<URL, Error>) {
        listener?.cancel()
        listener = nil
        continuation?.resume(with: result)
        continuation = nil
    }
}

func parseHTTPRequestURL(_ data: Data) -> URL? {
    guard let text = String(data: data, encoding: .utf8) else { return nil }
    let line = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? ""
    let parts = line.split(separator: " ")
    guard parts.count >= 2 else { return nil }
    return URL(string: "http://127.0.0.1\(parts[1])")
}

func httpSuccessPage() -> Data {
    let html = "<html><body>You can return to MarkSweep.</body></html>"
    let header = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: \(html.utf8.count)\r\nConnection: close\r\n\r\n"
    return Data((header + html).utf8)
}

func firstFreeLoopbackPort(from start: UInt16 = 8765, count: UInt16 = 20) throws -> UInt16 {
    for offset in 0..<count {
        let port = start + offset
        if loopbackPortIsFree(port) { return port }
    }
    throw MarkSweepError.listenFailed
}

func loopbackPortIsFree(_ port: UInt16) -> Bool {
    let sock = socket(AF_INET, SOCK_STREAM, 0)
    if sock < 0 { return false }
    var addr = sockaddr_in()
    addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
    addr.sin_family = sa_family_t(AF_INET)
    addr.sin_port = port.bigEndian
    addr.sin_addr = in_addr(s_addr: inet_addr("127.0.0.1"))
    let result = withUnsafePointer(to: &addr) { pointer in
        pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size)) }
    }
    close(sock)
    return result == 0
}
