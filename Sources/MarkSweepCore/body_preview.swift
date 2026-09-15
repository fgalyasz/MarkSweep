import Foundation

public func stripScriptAndStyle(_ html: String) -> String {
    let script = try! NSRegularExpression(
        pattern: "<(script|style)[^>]*>[\\s\\S]*?</(script|style)>",
        options: [.caseInsensitive]
    )
    let range = NSRange(html.startIndex..., in: html)
    return script.stringByReplacingMatches(in: html, range: range, withTemplate: "")
}

public func stripTags(_ html: String) -> String {
    let tags = try! NSRegularExpression(pattern: "<[^>]+>", options: [])
    let cleaned = stripScriptAndStyle(html)
    let range = NSRange(cleaned.startIndex..., in: cleaned)
    return tags.stringByReplacingMatches(in: cleaned, range: range, withTemplate: " ")
}

public func decodeHTMLEntities(_ text: String) -> String {
    text.replacingOccurrences(of: "&nbsp;", with: " ")
        .replacingOccurrences(of: "&amp;", with: "&")
        .replacingOccurrences(of: "&lt;", with: "<")
        .replacingOccurrences(of: "&gt;", with: ">")
        .replacingOccurrences(of: "&quot;", with: "\"")
}

public func collapseWhitespace(_ text: String) -> String {
    let parts = text.split { $0.isWhitespace || $0.isNewline }
    return parts.joined(separator: " ")
}

public func truncate(_ text: String, maxLength: Int) -> String {
    if text.count <= maxLength { return text }
    return String(text.prefix(maxLength))
}

public func previewText(from raw: String, maxLength: Int = 800) -> String {
    let stripped = decodeHTMLEntities(stripTags(raw))
    return truncate(collapseWhitespace(stripped), maxLength: maxLength)
}

public func previewForMessage(_ features: MessageFeatures) -> String {
    if let body = features.bodyText, body.isEmpty == false {
        return previewText(from: body)
    }
    return previewText(from: features.snippet)
}
