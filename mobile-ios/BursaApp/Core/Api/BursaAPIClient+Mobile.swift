import Foundation

extension BursaAPIClient {
    // MARK: - Places & menu

    func places(
        category: String? = nil,
        sub: String? = nil,
        spec: String? = nil,
        q: String? = nil,
        limit: Int = 24,
        offset: Int = 0
    ) async throws -> [PlaceItem] {
        var components = URLComponents(url: AppConfig.apiBase.appendingPathComponent("places"), resolvingAgainstBaseURL: false)!
        var items: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
        ]
        if let category, !category.isEmpty { items.append(URLQueryItem(name: "category", value: category)) }
        if let sub, !sub.isEmpty { items.append(URLQueryItem(name: "sub", value: sub)) }
        if let spec, !spec.isEmpty { items.append(URLQueryItem(name: "spec", value: spec)) }
        if let q, !q.isEmpty { items.append(URLQueryItem(name: "q", value: q)) }
        components.queryItems = items
        let json = try await getJSON(url: components.url!)
        return PlaceItem.list(from: json)
    }

    func placeDetail(slug: String) async throws -> [String: Any] {
        let s = slug.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { throw APIError(message: "Geçersiz slug", statusCode: 400) }
        let url = AppConfig.apiBase.appendingPathComponent("places/\(s)")
        let json = try await getJSON(url: url)
        guard let place = json["place"] as? [String: Any] else {
            throw APIError(message: "Mekan bulunamadı", statusCode: 404)
        }
        return place
    }

    func nearby(lat: Double, lng: Double, radius: Int = 1200) async throws -> [PlaceItem] {
        var components = URLComponents(url: AppConfig.apiBase.appendingPathComponent("discover/nearby"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lng", value: String(lng)),
            URLQueryItem(name: "r", value: String(radius)),
        ]
        let json = try await getJSON(url: components.url!)
        return PlaceItem.list(from: json)
    }

    func mobileMenu() async throws -> [MenuGroup] {
        let url = AppConfig.apiBase.appendingPathComponent("mobile/menu")
        let json = try await getJSON(url: url)
        return MenuGroup.decodeList(from: json)
    }

    func weeklyLeaders() async throws -> [LeaderRow] {
        let url = AppConfig.apiBase.appendingPathComponent("leaders/weekly")
        let json = try await getJSON(url: url)
        return (json["leaders"] as? [[String: Any]] ?? []).compactMap(LeaderRow.decode(from:))
    }

    func weekend() async throws -> [String: Any] {
        let url = AppConfig.apiBase.appendingPathComponent("discover/weekend")
        return try await getJSON(url: url)
    }

    // MARK: - Mobile modules

    func mobileGET(_ path: String, query: [String: String] = [:]) async throws -> [String: Any] {
        var components = URLComponents(url: AppConfig.apiBase.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        return try await getJSON(url: components.url!)
    }

    func visitPlaces(page: Int = 1, q: String = "", ilce: String = "", sort: String = "featured") async throws -> [String: Any] {
        var query: [String: String] = ["page": String(page)]
        if !q.isEmpty { query["q"] = q }
        if !ilce.isEmpty { query["ilce"] = ilce }
        if !sort.isEmpty { query["sort"] = sort }
        return try await mobileGET("mobile/visit", query: query)
    }

    func mobilePlaces(_ endpoint: MobileEndpoint, query: [String: String] = [:]) async throws -> [String: Any] {
        try await mobileGET("mobile/\(endpoint.rawValue)", query: query)
    }

    func nobetciEczaneler(ilce: String? = nil) async throws -> [String: Any] {
        var q: [String: String] = [:]
        if let ilce, !ilce.isEmpty { q["ilce"] = ilce }
        return try await mobileGET("mobile/nobetci-eczaneler", query: q)
    }

    func bursaNews(page: Int = 1) async throws -> [String: Any] {
        try await mobileGET("mobile/news", query: ["page": String(page), "limit": "24"])
    }

    func bursasporFeed() async throws -> [String: Any] {
        try await mobileGET("mobile/bursaspor")
    }

    func teleferikInfo() async throws -> [String: Any] {
        try await mobileGET("mobile/teleferik")
    }

    func utilitiesInfo() async throws -> [String: Any] {
        try await mobileGET("mobile/utilities")
    }
}
