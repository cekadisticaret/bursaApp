import Foundation

struct PlaceItem: Identifiable, Sendable, Hashable {
    var id: String { slug.isEmpty ? title : slug }
    let title: String
    let slug: String
    let category: String
    let ilce: String
    let blurb: String
    let imgUrl: String
    let lat: Double?
    let lng: Double?
    let subcategory: String
    let whenLabel: String
    let venueName: String
    let categoryLabel: String
    let path: String

    var detailSlug: String {
        let s = slug.trimmingCharacters(in: .whitespacesAndNewlines)
        if !s.isEmpty { return s }
        return Self.slugFromPath(path)
    }

    static func slugFromPath(_ path: String) -> String {
        let p = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !p.isEmpty else { return "" }
        let segment = p.split(separator: "/").last.map(String.init) ?? ""
        if segment.hasPrefix("bursa-") { return String(segment.dropFirst(6)) }
        return segment
    }

    static func decode(from json: [String: Any]) -> PlaceItem? {
        let path = json["path"] as? String ?? ""
        let slugRaw = (json["slug"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let slug = slugRaw.isEmpty ? slugFromPath(path) : slugRaw
        guard !slug.isEmpty || !(json["title"] as? String ?? "").isEmpty else { return nil }
        return PlaceItem(
            title: json["title"] as? String ?? "",
            slug: slug,
            category: json["category"] as? String ?? "",
            ilce: json["ilce"] as? String ?? "",
            blurb: json["blurb"] as? String ?? "",
            imgUrl: json["img_url"] as? String ?? "",
            lat: JSONValue.double(json["lat"]),
            lng: JSONValue.double(json["lng"]),
            subcategory: json["subcategory"] as? String ?? json["subcategory_label"] as? String ?? "",
            whenLabel: json["when"] as? String ?? json["when_long"] as? String ?? "",
            venueName: json["venue_name"] as? String ?? "",
            categoryLabel: json["category_label"] as? String ?? "",
            path: path
        )
    }

    static func list(from json: [String: Any], key: String = "places") -> [PlaceItem] {
        (json[key] as? [[String: Any]] ?? []).compactMap(decode(from:))
    }
}

struct MenuLink: Identifiable, Sendable, Hashable {
    var id: String { path + label }
    let label: String
    let path: String
    let category: String?

    static func decode(from json: [String: Any]) -> MenuLink {
        MenuLink(
            label: json["label"] as? String ?? "",
            path: json["path"] as? String ?? "",
            category: json["category"] as? String
        )
    }
}

struct MenuGroup: Identifiable, Sendable {
    var id: String { title }
    let title: String
    let icon: String
    let items: [MenuLink]

    static func decodeList(from json: [String: Any]) -> [MenuGroup] {
        (json["groups"] as? [[String: Any]] ?? []).compactMap { row in
            guard let title = row["title"] as? String else { return nil }
            let items = (row["items"] as? [[String: Any]] ?? []).map(MenuLink.decode(from:))
            return MenuGroup(title: title, icon: row["icon"] as? String ?? "", items: items)
        }
    }
}

struct LeaderRow: Identifiable, Sendable {
    var id: String { "\(rank)-\(name)" }
    let rank: Int
    let name: String
    let points: Int
    let avatarUrl: String

    static func decode(from json: [String: Any]) -> LeaderRow? {
        guard let name = json["name"] as? String else { return nil }
        return LeaderRow(
            rank: JSONValue.int(json["rank"]),
            name: name,
            points: JSONValue.int(json["points"]),
            avatarUrl: json["avatar_url"] as? String ?? ""
        )
    }
}

enum JSONValue {
    static func int(_ value: Any?) -> Int {
        if let v = value as? Int { return v }
        if let v = value as? NSNumber { return v.intValue }
        if let s = value as? String, let v = Int(s) { return v }
        return 0
    }

    static func double(_ value: Any?) -> Double? {
        if let v = value as? Double { return v }
        if let v = value as? NSNumber { return v.doubleValue }
        if let s = value as? String { return Double(s) }
        return nil
    }
}

enum MobileEndpoint: String, Sendable {
    case vets, dentists, doctors, hospitals, hotels
}
