import Foundation

/// URL query string building utilities.
public enum URLQueryBuilder: Sendable {
    /// Characters allowed in URL query parameter names and values (RFC 3986 unreserved).
    private static let allowedCharacters: CharacterSet = {
        var cs = CharacterSet.alphanumerics
        cs.insert(charactersIn: "-._~")
        return cs
    }()

    /// Percent-encodes a string for use in URL query parameters.
    public static func percentEncode(_ string: String) -> String {
        string.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? string
    }

    /// Parses a URL query string into key-value pairs.
    public static func parseQuery(_ query: String) -> [String: String] {
        var result: [String: String] = [:]
        let pairs = query.split(separator: "&")
        for pair in pairs {
            let parts = pair.split(separator: "=", maxSplits: 1)
            guard let key = parts.first else { continue }
            let decodedKey = String(key).removingPercentEncoding ?? String(key)
            let value = parts.count > 1 ? String(parts[1]) : ""
            let decodedValue = value.removingPercentEncoding ?? value
            result[decodedKey] = decodedValue
        }
        return result
    }

    /// Builds a URL query string from key-value pairs.
    public static func buildQuery(from parameters: [(String, String)]) -> String {
        parameters
            .map { "\(percentEncode($0.0))=\(percentEncode($0.1))" }
            .joined(separator: "&")
    }
}
