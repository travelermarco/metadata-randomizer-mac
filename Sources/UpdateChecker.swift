import Foundation

struct UpdateInfo: Sendable {
    let version: String
    let releaseURL: URL
}

enum UpdateChecker {

    private static let apiURL = URL(string:
        "https://api.github.com/repos/travelermarco/metadata-randomizer-mac/releases/latest")!
    private static let fallbackURL = URL(string:
        "https://github.com/travelermarco/metadata-randomizer-mac/releases/latest")!

    static func check(current: String) async -> UpdateInfo? {
        var request = URLRequest(url: apiURL, timeoutInterval: 8)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            // 404 means no releases yet — that's fine
            if let http = response as? HTTPURLResponse, http.statusCode == 404 { return nil }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tag = json["tag_name"] as? String
            else { return nil }

            let remote = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
            guard isNewer(remote: remote, than: current) else { return nil }

            let url = (json["html_url"] as? String).flatMap(URL.init) ?? fallbackURL
            return UpdateInfo(version: remote, releaseURL: url)
        } catch {
            return nil   // offline or timeout — silent fail
        }
    }

    private static func isNewer(remote: String, than current: String) -> Bool {
        let r = remote.split(separator: ".").compactMap { Int($0) }
        let c = current.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(r.count, c.count) {
            let rv = i < r.count ? r[i] : 0
            let cv = i < c.count ? c[i] : 0
            if rv > cv { return true }
            if rv < cv { return false }
        }
        return false
    }
}
