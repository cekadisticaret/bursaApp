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
            SimpleInfoView(title: "Rota planlayıcı", message: "Harita sekmesinden yakındaki mekanlara rota çizebilirsin.")
        case "/arkadas-ara":
            ActivityBuddyView()
        case "/liderler":
            LeadersView()
        case "/eglence":
            CategoryPlacesView(title: "Eğlence", category: "fun")
        default:
            if let cat = link.category, !cat.isEmpty {
                CategoryPlacesView(title: link.label, category: cat)
            } else {
                SimpleInfoView(title: link.label, message: "Bu bölüm yakında.")
            }
        }
    }
}

struct SimpleInfoView: View {
    let title: String
    let message: String

    var body: some View {
        AppPage(title: title) {
            Text(message)
                .foregroundStyle(AppColors.muted)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
