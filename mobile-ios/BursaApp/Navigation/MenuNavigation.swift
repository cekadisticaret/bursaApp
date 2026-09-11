import SwiftUI

enum AppMenuPath {
    static func open(_ item: MenuLink, tabSelection: Binding<ShellTab>?, navigationPath: Binding<NavigationPath>?) {
        let path = item.path
        switch path {
        case "/feed":
            tabSelection?.wrappedValue = .feed
        case "/yeme-icme":
            tabSelection?.wrappedValue = .food
        case "/etrafimda", "/harita":
            tabSelection?.wrappedValue = .explore
        default:
            if let navigationPath {
                navigationPath.wrappedValue.append(MenuDestination(link: item))
            }
        }
    }
}

struct MenuDestination: Hashable {
    let link: MenuLink
}

struct MenuDestinationView: View {
    let link: MenuLink

    var body: some View {
        destination
            .navigationDestination(for: String.self) { slug in
                if slug.hasPrefix("news:") {
                    NewsDetailView(slug: String(slug.dropFirst(5)))
                } else if slug.hasPrefix("pharmacy:") {
                    PharmacyDetailView(slug: String(slug.dropFirst(9)))
                } else {
                    PlaceDetailView(slug: slug)
                }
            }
    }

    @ViewBuilder
    private var destination: some View {
        switch link.path {
        case "/gezilecek":
            VisitView()
        case "/nobetci-eczaneler":
            PharmacyView()
        case "/haberler":
            NewsView()
        case "/bursaspor":
            BursasporView()
        case "/uludag-teleferik":
            TeleferikView()
        case "/faturalar":
            UtilitiesView()
        case "/hafta-sonu":
            WeekendView()
        case "/oteller":
            MobilePlacesView(endpoint: .hotels, title: "Oteller")
        case "/veterinerler":
            MobilePlacesView(endpoint: .vets, title: "Veterinerler")
        case "/dis-hekimleri":
            MobilePlacesView(endpoint: .dentists, title: "Diş hekimleri")
        case "/doktorlar":
            MobilePlacesView(endpoint: .doctors, title: "Doktorlar")
        case "/hastaneler":
            MobilePlacesView(endpoint: .hospitals, title: "Hastaneler")
        case "/rota":
            RoutePlannerView()
        case "/arkadas-ara":
            ActivityBuddyView()
        case "/okey", "/okey-ara":
            OkeyView()
        case "/liderler":
            LeadersView()
        case "/eglence":
            CategoryPlacesView(title: "Eğlence", category: "fun")
        case "/etkinlikler":
            CategoryPlacesView(title: "Etkinlikler", category: "event")
        case "/yeme-icme-list":
            CategoryPlacesView(title: "Yeme-içme", category: "food")
        default:
            if let cat = link.category, !cat.isEmpty {
                CategoryPlacesView(title: link.label, category: cat)
            } else if !link.path.isEmpty, link.path != "/" {
                CategoryPlacesView(title: link.label, category: pathToCategory(link.path))
            } else {
                RoutePlannerView()
            }
        }
    }

    private func pathToCategory(_ path: String) -> String {
        switch path {
        case "/konaklama": return "hotel"
        case "/spor": return "sport"
        case "/dugun": return "wedding"
        case "/gece-hayati": return "nightlife"
        default: return "visit"
        }
    }
}
