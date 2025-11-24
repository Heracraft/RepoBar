import Foundation

/// Simple in-memory ETag cache keyed by URL string.
actor ETagCache {
    private var store: [String: (etag: String, data: Data)] = [:]
    private var rateLimitedUntil: Date?

    func cached(for url: URL) -> (etag: String, data: Data)? {
        self.store[url.absoluteString]
    }

    func save(url: URL, etag: String?, data: Data) {
        guard let etag else { return }
        self.store[url.absoluteString] = (etag, data)
    }

    func setRateLimitReset(date: Date) {
        self.rateLimitedUntil = date
    }

    func rateLimitUntil() -> Date? {
        self.rateLimitedUntil
    }

    func isRateLimited(now: Date = Date()) -> Bool {
        if let until = rateLimitedUntil, until > now { return true }
        return false
    }
}
